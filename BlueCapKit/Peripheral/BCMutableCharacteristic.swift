//
//  BCMutableCharacteristic.swift
//  BlueCap
//
//  Created by Troy Stribling on 8/9/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import Foundation
import CoreBluetooth

// MARK: - BCMutableCharacteristic -
public class BCMutableCharacteristic : NSObject {

    // MARK: Properties
    static let ioQueue = Queue("us.gnos.blueCap.mutable-characteristic.io")

    private let profile: BCCharacteristicProfile

    private var centrals = BCSerialIODictionary<NSUUID, CBCentralInjectable>(BCMutableCharacteristic.ioQueue)

    private var _queuedUpdates = [NSData]()
    private var _isUpdating = false

    internal var _processWriteRequestPromise: StreamPromise<(request: CBATTRequestInjectable, central: CBCentralInjectable)>?
    internal weak var _service: BCMutableService?
    
    internal let cbMutableChracteristic: CBMutableCharacteristicInjectable
    public var value: NSData?

    private var queuedUpdates: [NSData] {
        get {
            return BCMutableCharacteristic.ioQueue.sync { return self._queuedUpdates }
        }
        set {
            BCMutableCharacteristic.ioQueue.sync { self._queuedUpdates = newValue }
        }
    }

    private var processWriteRequestPromise: StreamPromise<(request: CBATTRequestInjectable, central: CBCentralInjectable)>? {
        get {
            return BCMutableCharacteristic.ioQueue.sync { return self._processWriteRequestPromise }
        }
        set {
            BCMutableCharacteristic.ioQueue.sync { self._processWriteRequestPromise = newValue }
        }
    }

    public private(set) var isUpdating: Bool {
        get {
            return BCMutableCharacteristic.ioQueue.sync { return self._isUpdating }
        }
        set {
            BCMutableCharacteristic.ioQueue.sync { self._isUpdating = newValue }
        }
    }

    public var UUID: CBUUID {
        return self.profile.UUID
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

    public var pendingUpdates : [NSData] {
        return Array(self.queuedUpdates)
    }

    public var service: BCMutableService? {
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
    public convenience init(profile: BCCharacteristicProfile) {
        let cbMutableChracteristic = CBMutableCharacteristic(type: profile.UUID, properties: profile.properties, value: nil, permissions: profile.permissions)
        self.init(cbMutableCharacteristic: cbMutableChracteristic, profile: profile)
    }

    internal init(cbMutableCharacteristic: CBMutableCharacteristicInjectable, profile: BCCharacteristicProfile) {
        self.profile = profile
        self.value = profile.initialValue
        self.cbMutableChracteristic = cbMutableCharacteristic
    }

    internal init(cbMutableCharacteristic: CBMutableCharacteristicInjectable) {
        self.profile = BCCharacteristicProfile(UUID: cbMutableCharacteristic.UUID.UUIDString)
        self.value = profile.initialValue
        self.cbMutableChracteristic = cbMutableCharacteristic
    }

    public init(UUID: String, properties: CBCharacteristicProperties, permissions: CBAttributePermissions, value: NSData?) {
        self.profile = BCCharacteristicProfile(UUID: UUID)
        self.value = value
        self.cbMutableChracteristic = CBMutableCharacteristic(type:self.profile.UUID, properties:properties, value:nil, permissions:permissions)
    }

    public convenience init(UUID: String) {
        self.init(profile: BCCharacteristicProfile(UUID: UUID))
    }

    public class func withProfiles(profiles: [BCCharacteristicProfile]) -> [BCMutableCharacteristic] {
        return profiles.map{ BCMutableCharacteristic(profile: $0) }
    }

    public class func withProfiles(profiles: [BCCharacteristicProfile], cbCharacteristics: [CBMutableCharacteristic]) -> [BCMutableCharacteristic] {
        return profiles.map{ BCMutableCharacteristic(profile: $0) }
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
    public func startRespondingToWriteRequests(capacity: Int? = nil) -> FutureStream<(request: CBATTRequestInjectable, central: CBCentralInjectable)> {
        self.processWriteRequestPromise = StreamPromise<(request: CBATTRequestInjectable, central: CBCentralInjectable)>(capacity:capacity)
        return self.processWriteRequestPromise!.future
    }
    
    public func stopRespondingToWriteRequests() {
        self.processWriteRequestPromise = nil
    }
    
    public func respondToRequest(request: CBATTRequestInjectable, withResult result: CBATTError) {
        self.service?.peripheralManager?.respondToRequest(request, withResult:result)
    }

    internal func didRespondToWriteRequest(request: CBATTRequestInjectable, central: CBCentralInjectable) -> Bool  {
        guard let processWriteRequestPromise = self.processWriteRequestPromise else {
            return false
        }
        processWriteRequestPromise.success((request, central))
        return true
    }

    // MARK: Manage Notification Updates
    public func updateValueWithString(value: [String:String]) -> Bool {
        guard let data = self.profile.dataFromStringValue(value) else {
            return false
        }
        return self.updateValueWithData(data)
    }

    public func updateValueWithData(value: NSData) -> Bool  {
        return self.updateValuesWithData([value])
    }

    public func updateValue<T: BCDeserializable>(value: T) -> Bool {
        return self.updateValueWithData(BCSerDe.serialize(value))
    }

    public func updateValue<T: BCRawDeserializable>(value: T) -> Bool  {
        return self.updateValueWithData(BCSerDe.serialize(value))
    }

    public func updateValue<T: BCRawArrayDeserializable>(value: T) -> Bool  {
        return self.updateValueWithData(BCSerDe.serialize(value))
    }

    public func updateValue<T: BCRawPairDeserializable>(value: T) -> Bool  {
        return self.updateValueWithData(BCSerDe.serialize(value))
    }

    public func updateValue<T: BCRawArrayPairDeserializable>(value: T) -> Bool  {
        return self.updateValueWithData(BCSerDe.serialize(value))
    }

    // MARK: CBPeripheralManagerDelegate Shims
    internal func peripheralManagerIsReadyToUpdateSubscribers() {
        self.updateIsUpdating(true)
        self.updateValuesWithData(self.queuedUpdates)
        self.queuedUpdates.removeAll()
    }

    internal func didSubscribeToCharacteristic(central: CBCentralInjectable) {
        self.updateIsUpdating(true)
        self.centrals[central.identifier] = central
        self.updateValuesWithData(self.queuedUpdates)
        self.queuedUpdates.removeAll()
    }

    internal func didUnsubscribeFromCharacteristic(central: CBCentralInjectable) {
        self.centrals.removeValueForKey(central.identifier)
        if self.centrals.keys.count == 0 {
            self.updateIsUpdating(false)
        }
    }

    // MARK: Utils
    private func updateValuesWithData(values: [NSData]) -> Bool  {
        guard let value = values.last else {
            return self.isUpdating
        }
        self.value = value
        if let peripheralManager = self.service?.peripheralManager where self.isUpdating && self.canNotify {
            for value in values {
                self.updateIsUpdating(peripheralManager.updateValue(value, forCharacteristic:self))
                if !self.isUpdating {
                    self.queuedUpdates.append(value)
                }
            }
        } else {
            self.updateIsUpdating(false)
            self.queuedUpdates.append(value)
        }
        return self.isUpdating
    }

    func updateIsUpdating(value: Bool) {
        self.willChangeValueForKey("isUpdating")
        self.isUpdating = value
        self.didChangeValueForKey("isUpdating")
    }

}