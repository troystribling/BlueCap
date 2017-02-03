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
public class MutableCharacteristic : NSObject {

    // MARK: Properties
    let profile: CharacteristicProfile

    fileprivate var centrals = [UUID : CBCentralInjectable]()

    fileprivate var queuedUpdates = [Data]()
    internal fileprivate(set) var _isUpdating = false
    fileprivate var processWriteRequestPromise: StreamPromise<(request: CBATTRequestInjectable, central: CBCentralInjectable)>?

    internal var _value: Data?

    let cbMutableChracteristic: CBMutableCharacteristicInjectable

    public internal(set) weak var service: MutableService?

    fileprivate var peripheralQueue: Queue? {
        return service?.peripheralManager?.peripheralQueue
    }

    public let uuid: CBUUID

    public var value: Data? {
        get {
            return peripheralQueue?.sync { return self._value }
        }
        set {
            peripheralQueue?.sync { self._value = newValue }
        }
    }

    public var isUpdating: Bool {
        get {
            return peripheralQueue?.sync { return self._isUpdating } ?? false
        }
    }

    public var name: String {
        return profile.name
    }
    
    public var stringValues: [String] {
        return profile.stringValues
    }
    
    public var permissions: CBAttributePermissions {
        return cbMutableChracteristic.permissions
    }
    
    public var properties: CBCharacteristicProperties {
        return cbMutableChracteristic.properties
    }

    public var subscribers: [CBCentralInjectable] {
        return peripheralQueue?.sync {
            return Array(self.centrals.values)
        } ?? [CBCentralInjectable]()
    }

    public var pendingUpdates : [Data] {
        return peripheralQueue?.sync {
            return Array(self.queuedUpdates)
        } ?? [Data]()
    }

    public var stringValue: [String:String]? {
        if let value = self.value {
            return self.profile.stringValue(value)
        } else {
            return nil
        }
    }

    public var canNotify : Bool {
        return self.propertyEnabled(.notify)                    ||
               self.propertyEnabled(.indicate)                  ||
               self.propertyEnabled(.notifyEncryptionRequired)  ||
               self.propertyEnabled(.indicateEncryptionRequired)
    }

    // MARK: Initializers

    public convenience init(profile: CharacteristicProfile) {
        self.init(cbMutableCharacteristic: CBMutableCharacteristic(type: profile.uuid, properties: profile.properties, value: nil, permissions: profile.permissions), profile: profile)
    }

    internal init(cbMutableCharacteristic: CBMutableCharacteristicInjectable, profile: CharacteristicProfile) {
        self.profile = profile
        self._value = profile.initialValue
        self.cbMutableChracteristic = cbMutableCharacteristic
        uuid = CBUUID(data: cbMutableCharacteristic.uuid.data)
    }

    internal init(cbMutableCharacteristic: CBMutableCharacteristicInjectable) {
        self.profile = CharacteristicProfile(uuid: cbMutableCharacteristic.uuid.uuidString)
        self._value = profile.initialValue
        self.cbMutableChracteristic = cbMutableCharacteristic
        uuid = CBUUID(data: cbMutableCharacteristic.uuid.data)
    }

    public init(UUID: String, properties: CBCharacteristicProperties, permissions: CBAttributePermissions, value: Data?) {
        self.profile = CharacteristicProfile(uuid: UUID)
        self._value = value
        self.cbMutableChracteristic = CBMutableCharacteristic(type: self.profile.uuid, properties: properties, value: nil, permissions: permissions)
        uuid = CBUUID(data: self.profile.uuid.data)
    }

    public convenience init(UUID: String) {
        self.init(profile: CharacteristicProfile(uuid: UUID))
    }

    public class func withProfiles(_ profiles: [CharacteristicProfile]) -> [MutableCharacteristic] {
        return profiles.map{ MutableCharacteristic(profile: $0) }
    }

    public class func withProfiles(_ profiles: [CharacteristicProfile], cbCharacteristics: [CBMutableCharacteristic]) -> [MutableCharacteristic] {
        return profiles.map{ MutableCharacteristic(profile: $0) }
    }

    // MARK: Properties & Permissions

    public func propertyEnabled(_ property:CBCharacteristicProperties) -> Bool {
        return (self.properties.rawValue & property.rawValue) > 0
    }
    
    public func permissionEnabled(_ permission:CBAttributePermissions) -> Bool {
        return (self.permissions.rawValue & permission.rawValue) > 0
    }

    // MARK: Data

    public func data(fromString data: [String:String]) -> Data? {
        return self.profile.data(fromString: data)
    }

    // MARK: Manage Writes

    public func startRespondingToWriteRequests(capacity: Int = Int.max) -> FutureStream<(request: CBATTRequestInjectable, central: CBCentralInjectable)> {
        return peripheralQueue?.sync {
            if let processWriteRequestPromise = self.processWriteRequestPromise {
                return processWriteRequestPromise.stream
            }
            self.processWriteRequestPromise = StreamPromise<(request: CBATTRequestInjectable, central: CBCentralInjectable)>(capacity: capacity)
            return self.processWriteRequestPromise!.stream
        } ?? FutureStream(error: MutableCharacteristicError.unconfigured)
    }

    public func stopRespondingToWriteRequests() {
        peripheralQueue?.sync {
            self.processWriteRequestPromise = nil
        }
    }
    
    public func respondToRequest(_ request: CBATTRequestInjectable, withResult result: CBATTError.Code) {
        self.service?.peripheralManager?.respondToRequest(request, withResult: result)
    }

    internal func didRespondToWriteRequest(_ request: CBATTRequestInjectable, central: CBCentralInjectable) -> Bool  {
        guard let processWriteRequestPromise = self.processWriteRequestPromise else {
            return false
        }
        processWriteRequestPromise.success((request, central))
        return true
    }

    // MARK: Manage Notification Updates

    public func update(withString value: [String:String]) throws {
        guard let data = self.profile.data(fromString: value) else {
            throw MutableCharacteristicError.notSerializable
        }
        return try update(withData: data)
    }

    public func update(withData value: Data) throws {
        guard let peripheralQueue = peripheralQueue else {
            throw MutableCharacteristicError.unconfigured
        }
        guard canNotify else {
            throw MutableCharacteristicError.notifyNotSupported
        }
        peripheralQueue.sync { self.updateValues([value]) }
    }

    public func update<T: Deserializable>(_ value: T) throws {
        try update(withData: SerDe.serialize(value))
    }

    public func update<T: RawDeserializable>(_ value: T) throws  {
        try update(withData: SerDe.serialize(value))
    }

    public func update<T: RawArrayDeserializable>(_ value: T) throws {
        try update(withData: SerDe.serialize(value))
    }

    public func update<T: RawPairDeserializable>(_ value: T) throws {
        try update(withData: SerDe.serialize(value))
    }

    public func update<T: RawArrayPairDeserializable>(_ value: T) throws {
        try update(withData: SerDe.serialize(value))
    }

    // MARK: CBPeripheralManagerDelegate Shims

    internal func peripheralManagerIsReadyToUpdateSubscribers() {
        self._isUpdating = true
        _ = self.updateValues(self.queuedUpdates)
        self.queuedUpdates.removeAll()
    }

    internal func didSubscribeToCharacteristic(_ central: CBCentralInjectable) {
        self._isUpdating = true
        self.centrals[central.identifier] = central
        _ = self.updateValues(self.queuedUpdates)
        self.queuedUpdates.removeAll()
    }

    internal func didUnsubscribeFromCharacteristic(_ central: CBCentralInjectable) {
        self.centrals.removeValue(forKey: central.identifier)
        if self.centrals.keys.count == 0 {
            self._isUpdating = false
        }
    }

    // MARK: Utils

    fileprivate func updateValues(_ values: [Data])  {
        guard let value = values.last else {
            return
        }
        _value = value
        if let peripheralManager = service?.peripheralManager, _isUpdating {
            for value in values {
                _isUpdating = peripheralManager.updateValue(value, forCharacteristic: self)
                if !_isUpdating { queuedUpdates.append(value) }
            }
        } else {
            _isUpdating = false
            queuedUpdates.append(value)
        }
    }

}
