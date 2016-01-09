//
//  MutableCharacteristic.swift
//  BlueCap
//
//  Created by Troy Stribling on 8/9/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import Foundation
import CoreBluetooth

struct MutableCharacteristicIO {
    static let queue = Queue("us.gnos.mutable-characteristic.io")
}

public class MutableCharacteristic {

    private let profile: CharacteristicProfile
    
    private var _subscribers        = [NSUUID:CBCentralInjectable]()
    private var _isUpdating         = false
    private var _pendingUpdates     = [NSData]()

    internal var processWriteRequestPromise: StreamPromise<(CBATTRequestInjectable, CBCentralInjectable)>?
    internal weak var _service: MutableService?
    
    public let cbMutableChracteristic: CBMutableCharacteristic
    public var value: NSData?

    public var uuid: CBUUID {
        return self.profile.uuid
    }
    
    public var name: String {
        return self.profile.name
    }
    
    public var stringValues: [String] {
        return self.profile.stringValues
    }
    
    public var permissions: CBAttributePermissions {
        return self.cbMutableChracteristic.permissions
    }
    
    public var properties: CBCharacteristicProperties {
        return self.cbMutableChracteristic.properties
    }

    public var subscribers: [CBCentralInjectable] {
        return Array(self._subscribers.values)
    }

    public var hasSubscriber: Bool {
        return self.subscribers.count > 0
    }

    public var pendingUpdates : [NSData] {
        return Array(self._pendingUpdates)
    }

    public var isUpdating: Bool {
        return self._isUpdating
    }
    
    public var service: MutableService? {
        return self._service
    }

    public var stringValue: [String:String]? {
        if let value = self.value {
            return self.profile.stringValue(value)
        } else {
            return nil
        }
    }

    public var canNotify : Bool {
        return self.propertyEnabled(.Notify)                    ||
               self.propertyEnabled(.Indicate)                  ||
               self.propertyEnabled(.NotifyEncryptionRequired)  ||
               self.propertyEnabled(.IndicateEncryptionRequired)
    }

    public init(profile: CharacteristicProfile) {
        self.profile = profile
        self.value = profile.initialValue
        self.cbMutableChracteristic = CBMutableCharacteristic(type: profile.uuid, properties: profile.properties, value: nil, permissions: profile.permissions)
    }

    public init(uuid: String, properties: CBCharacteristicProperties, permissions: CBAttributePermissions, value: NSData?) {
        self.profile = CharacteristicProfile(uuid:uuid)
        self.value = value
        self.cbMutableChracteristic = CBMutableCharacteristic(type:self.profile.uuid, properties:properties, value:nil, permissions:permissions)
    }

    public convenience init(uuid:String, service: MutableService) {
        self.init(profile:CharacteristicProfile(uuid:uuid))
    }

    public func propertyEnabled(property:CBCharacteristicProperties) -> Bool {
        return (self.properties.rawValue & property.rawValue) > 0
    }
    
    public func permissionEnabled(permission:CBAttributePermissions) -> Bool {
        return (self.permissions.rawValue & permission.rawValue) > 0
    }

    public func dataFromStringValue(stringValue: [String:String]) -> NSData? {
        return self.profile.dataFromStringValue(stringValue)
    }
    
    public func updateValueWithData(value: NSData) -> Bool  {
        return MutableCharacteristicIO.queue.sync {
            return self.updateValuesWithData([value])
        }
    }
    
    public class func withProfiles(profiles: [CharacteristicProfile], service: MutableService) -> [MutableCharacteristic] {
        return profiles.map{MutableCharacteristic(profile: $0)}
    }
        
    public func startRespondingToWriteRequests(capacity: Int? = nil) -> FutureStream<(CBATTRequestInjectable, CBCentralInjectable)> {
        return MutableCharacteristicIO.queue.sync {
            self.processWriteRequestPromise = StreamPromise<(CBATTRequestInjectable, CBCentralInjectable)>(capacity:capacity)
            return self.processWriteRequestPromise!.future
        }
    }
    
    public func stopRespondingToWriteRequests() {
        MutableCharacteristicIO.queue.sync {
            self.processWriteRequestPromise = nil
        }
    }
    
    public func peripheralManagerIsReadyToUpdateSubscribers() {
        MutableCharacteristicIO.queue.sync {
            self._isUpdating = true
            self.updateValuesWithData(self._pendingUpdates)
            self._pendingUpdates.removeAll()
        }
    }

    public func updateValueWithString(value: [String:String]) -> Bool {
        if let data = self.profile.dataFromStringValue(value) {
            return self.updateValueWithData(data)
        } else {
            return false
        }
    }
    
    public func respondToRequest(request: CBATTRequestInjectable, withResult result: CBATTError) {
        self.service?.peripheralManager?.respondToRequest(request, withResult:result)
    }
    
    public func updateValue<T:Deserializable>(value: T) -> Bool {
        return self.updateValueWithData(Serde.serialize(value))
    }

    public func updateValue<T:RawDeserializable>(value: T) -> Bool  {
        return self.updateValueWithData(Serde.serialize(value))
    }

    public func updateValue<T:RawArrayDeserializable>(value: T) -> Bool  {
        return self.updateValueWithData(Serde.serialize(value))
    }

    public func updateValue<T:RawPairDeserializable>(value: T) -> Bool  {
        return self.updateValueWithData(Serde.serialize(value))
    }

    public func updateValue<T:RawArrayPairDeserializable>(value: T) -> Bool  {
        return self.updateValueWithData(Serde.serialize(value))
    }

    internal func didRespondToWriteRequest(request: CBATTRequestInjectable, central: CBCentralInjectable) -> Bool  {
        if let processWriteRequestPromise = self.processWriteRequestPromise {
            processWriteRequestPromise.success((request, central))
            return true
        } else {
            return false
        }
    }

    internal func didSubscribeToCharacteristic(central: CBCentralInjectable) {
        MutableCharacteristicIO.queue.sync {
            self._subscribers[central.identifier] = central
            self._isUpdating = true
            self.updateValuesWithData(self._pendingUpdates)
            self._pendingUpdates.removeAll()
        }
    }

    internal func didUnsubscribeFromCharacteristic(central: CBCentralInjectable) {
        MutableCharacteristicIO.queue.sync {
            self._subscribers.removeValueForKey(central.identifier)
            if !self.hasSubscriber {
                self._isUpdating = false
            }
        }
    }

    private func updateValuesWithData(values: [NSData]) -> Bool  {
        guard let value = values.last else {
            return self._isUpdating
        }
        self.value = value
        if let peripheralManager = self.service?.peripheralManager where self._isUpdating && self.canNotify {
            for value in values {
                self._isUpdating = peripheralManager.updateValue(value, forCharacteristic:self)
                if self.isUpdating == false {
                    self._pendingUpdates.append(value)
                }
            }
        } else {
            self._isUpdating = false
            self._pendingUpdates.append(value)
        }
        return self._isUpdating
    }

}