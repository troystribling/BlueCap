//
//  MutableCharacteristic.swift
//  BlueCap
//
//  Created by Troy Stribling on 8/9/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import Foundation
import CoreBluetooth

// MARK: - MutableCharacteristic -
public class MutableCharacteristic {

    // MARK: Properties
    static let ioQueue = Queue("us.gnos.blueCap.mutable-characteristic.io")

    private let profile: CharacteristicProfile

    private var centrals            = BCSerialIODictionary<NSUUID, CBCentralInjectable>(MutableCharacteristic.ioQueue)

    private var _updating           = false
    private var _queuedUpdates      = [NSData]()

    internal var _processWriteRequestPromise: StreamPromise<(CBATTRequestInjectable, CBCentralInjectable)>?

    internal weak var _service: MutableService?
    
    public let cbMutableChracteristic: CBMutableCharacteristic
    public var value: NSData?

    private var queuedUpdates: [NSData] {
        get {
            return MutableCharacteristic.ioQueue.sync { return self._queuedUpdates }
        }
        set {
            MutableCharacteristic.ioQueue.sync { self._queuedUpdates = newValue }
        }
    }

    private var updating: Bool {
        get {
            return MutableCharacteristic.ioQueue.sync { return self._updating }
        }
        set {
            MutableCharacteristic.ioQueue.sync { self._updating = newValue }
        }
    }

    private var processWriteRequestPromise: StreamPromise<(CBATTRequestInjectable, CBCentralInjectable)>? {
        get {
            return MutableCharacteristic.ioQueue.sync { return self._processWriteRequestPromise }
        }
        set {
            MutableCharacteristic.ioQueue.sync { self._processWriteRequestPromise = newValue }
        }
    }

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
        return Array(self.centrals.values)
    }

    public var hasSubscriber: Bool {
        return self.subscribers.count > 0
    }

    public var pendingUpdates : [NSData] {
        return Array(self.queuedUpdates)
    }

    public var isUpdating: Bool {
        return self.updating
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

    // MARK: Initializers
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

    public class func withProfiles(profiles: [CharacteristicProfile], service: MutableService) -> [MutableCharacteristic] {
        return profiles.map{MutableCharacteristic(profile: $0)}
    }

    // MARK: Properties & Permissions
    public func propertyEnabled(property:CBCharacteristicProperties) -> Bool {
        return (self.properties.rawValue & property.rawValue) > 0
    }
    
    public func permissionEnabled(permission:CBAttributePermissions) -> Bool {
        return (self.permissions.rawValue & permission.rawValue) > 0
    }

    // MARK: Data
    public func dataFromStringValue(stringValue: [String:String]) -> NSData? {
        return self.profile.dataFromStringValue(stringValue)
    }

    // MARK: Manage Writes
    public func startRespondingToWriteRequests(capacity: Int? = nil) -> FutureStream<(CBATTRequestInjectable, CBCentralInjectable)> {
        self.processWriteRequestPromise = StreamPromise<(CBATTRequestInjectable, CBCentralInjectable)>(capacity:capacity)
        return self.processWriteRequestPromise!.future
    }
    
    public func stopRespondingToWriteRequests() {
        self.processWriteRequestPromise = nil
    }
    
    public func respondToRequest(request: CBATTRequestInjectable, withResult result: CBATTError) {
        self.service?.peripheralManager?.respondToRequest(request, withResult:result)
    }

    internal func didRespondToWriteRequest(request: CBATTRequestInjectable, central: CBCentralInjectable) -> Bool  {
        if let processWriteRequestPromise = self.processWriteRequestPromise {
            processWriteRequestPromise.success((request, central))
            return true
        } else {
            return false
        }
    }

    // MARK: Manage Notification Updates
    public func updateValueWithString(value: [String:String]) -> Bool {
        if let data = self.profile.dataFromStringValue(value) {
            return self.updateValueWithData(data)
        } else {
            return false
        }
    }

    public func updateValueWithData(value: NSData) -> Bool  {
        return self.updateValuesWithData([value])
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

    internal func peripheralManagerIsReadyToUpdateSubscribers() {
        self.updating = true
        self.updateValuesWithData(self.queuedUpdates)
        self.queuedUpdates.removeAll()
    }

    internal func didSubscribeToCharacteristic(central: CBCentralInjectable) {
            self.centrals[central.identifier] = central
            self.updating = true
            self.updateValuesWithData(self.queuedUpdates)
            self.queuedUpdates.removeAll()
    }

    internal func didUnsubscribeFromCharacteristic(central: CBCentralInjectable) {
        self.centrals.removeValueForKey(central.identifier)
        if !self.hasSubscriber {
            self.updating = false
        }
    }

    private func updateValuesWithData(values: [NSData]) -> Bool  {
        guard let value = values.last else {
            return self.updating
        }
        self.value = value
        if let peripheralManager = self.service?.peripheralManager where self.updating && self.canNotify {
            for value in values {
                self.updating = peripheralManager.updateValue(value, forCharacteristic:self)
                if self.isUpdating == false {
                    self.queuedUpdates.append(value)
                }
            }
        } else {
            self.updating = false
            self.queuedUpdates.append(value)
        }
        return self.updating
    }

}