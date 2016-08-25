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
    static let ioQueue = Queue("us.gnos.blueCap.mutable-characteristic.io")

    fileprivate let profile: CharacteristicProfile

    fileprivate var centrals = SerialIODictionary<Foundation.UUID, CBCentralInjectable>(MutableCharacteristic.ioQueue)

    fileprivate var _queuedUpdates = [Data]()
    fileprivate var _isUpdating = false

    internal var _processWriteRequestPromise: StreamPromise<(request: CBATTRequestInjectable, central: CBCentralInjectable)>?
    internal weak var _service: MutableService?
    
    internal let cbMutableChracteristic: CBMutableCharacteristicInjectable
    public var value: Data?

    fileprivate var queuedUpdates: [Data] {
        get {
            return MutableCharacteristic.ioQueue.sync { return self._queuedUpdates }
        }
        set {
            MutableCharacteristic.ioQueue.sync { self._queuedUpdates = newValue }
        }
    }

    fileprivate var processWriteRequestPromise: StreamPromise<(request: CBATTRequestInjectable, central: CBCentralInjectable)>? {
        get {
            return MutableCharacteristic.ioQueue.sync { return self._processWriteRequestPromise }
        }
        set {
            MutableCharacteristic.ioQueue.sync { self._processWriteRequestPromise = newValue }
        }
    }

    public fileprivate(set) var isUpdating: Bool {
        get {
            return MutableCharacteristic.ioQueue.sync { return self._isUpdating }
        }
        set {
            MutableCharacteristic.ioQueue.sync { self._isUpdating = newValue }
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

    public var pendingUpdates : [Data] {
        return Array(self.queuedUpdates)
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

    open var canNotify : Bool {
        return self.propertyEnabled(.notify)                    ||
               self.propertyEnabled(.indicate)                  ||
               self.propertyEnabled(.notifyEncryptionRequired)  ||
               self.propertyEnabled(.indicateEncryptionRequired)
    }

    // MARK: Initializers
    public convenience init(profile: CharacteristicProfile) {
        let cbMutableChracteristic = CBMutableCharacteristic(type: profile.UUID, properties: profile.properties, value: nil, permissions: profile.permissions)
        self.init(cbMutableCharacteristic: cbMutableChracteristic, profile: profile)
    }

    internal init(cbMutableCharacteristic: CBMutableCharacteristicInjectable, profile: CharacteristicProfile) {
        self.profile = profile
        self.value = profile.initialValue
        self.cbMutableChracteristic = cbMutableCharacteristic
    }

    internal init(cbMutableCharacteristic: CBMutableCharacteristicInjectable) {
        self.profile = CharacteristicProfile(UUID: cbMutableCharacteristic.UUID.uuidString)
        self.value = profile.initialValue
        self.cbMutableChracteristic = cbMutableCharacteristic
    }

    public init(UUID: String, properties: CBCharacteristicProperties, permissions: CBAttributePermissions, value: Data?) {
        self.profile = CharacteristicProfile(UUID: UUID)
        self.value = value
        self.cbMutableChracteristic = CBMutableCharacteristic(type:self.profile.UUID, properties:properties, value:nil, permissions:permissions)
    }

    public convenience init(UUID: String) {
        self.init(profile: CharacteristicProfile(UUID: UUID))
    }

    open class func withProfiles(_ profiles: [CharacteristicProfile]) -> [MutableCharacteristic] {
        return profiles.map{ MutableCharacteristic(profile: $0) }
    }

    open class func withProfiles(_ profiles: [CharacteristicProfile], cbCharacteristics: [CBMutableCharacteristic]) -> [MutableCharacteristic] {
        return profiles.map{ MutableCharacteristic(profile: $0) }
    }

    // MARK: Properties & Permissions
    open func propertyEnabled(_ property:CBCharacteristicProperties) -> Bool {
        return (self.properties.rawValue & property.rawValue) > 0
    }
    
    open func permissionEnabled(_ permission:CBAttributePermissions) -> Bool {
        return (self.permissions.rawValue & permission.rawValue) > 0
    }

    // MARK: Data
    open func data(fromString data: [String:String]) -> Data? {
        return self.profile.data(fromString: data)
    }

    // MARK: Manage Writes
    open func startRespondingToWriteRequests(capacity: Int = Int.max) -> FutureStream<(request: CBATTRequestInjectable, central: CBCentralInjectable)> {
        self.processWriteRequestPromise = StreamPromise<(request: CBATTRequestInjectable, central: CBCentralInjectable)>(capacity: capacity)
        return self.processWriteRequestPromise!.stream
    }
    
    open func stopRespondingToWriteRequests() {
        self.processWriteRequestPromise = nil
    }
    
    open func respondToRequest(_ request: CBATTRequestInjectable, withResult result: CBATTError.Code) {
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
    open func updateValue(withString value: [String:String]) -> Bool {
        guard let data = self.profile.data(fromString: value) else {
            return false
        }
        return self.update(withData: data)
    }

    open func update(withData value: Data) -> Bool  {
        return self.updateValues([value])
    }

    open func update<T: Deserializable>(_ value: T) -> Bool {
        return self.update(withData: SerDe.serialize(value))
    }

    open func update<T: RawDeserializable>(_ value: T) -> Bool  {
        return self.update(withData: SerDe.serialize(value))
    }

    open func update<T: RawArrayDeserializable>(_ value: T) -> Bool  {
        return self.update(withData: SerDe.serialize(value))
    }

    open func update<T: RawPairDeserializable>(_ value: T) -> Bool  {
        return self.update(withData: SerDe.serialize(value))
    }

    open func update<T: RawArrayPairDeserializable>(_ value: T) -> Bool  {
        return self.update(withData: SerDe.serialize(value))
    }

    // MARK: CBPeripheralManagerDelegate Shims
    internal func peripheralManagerIsReadyToUpdateSubscribers() {
        self.isUpdating = true
        let _ = self.updateValues(self.queuedUpdates)
        self.queuedUpdates.removeAll()
    }

    internal func didSubscribeToCharacteristic(_ central: CBCentralInjectable) {
        self.isUpdating = true
        self.centrals[central.identifier] = central
        let _ = self.updateValues(self.queuedUpdates)
        self.queuedUpdates.removeAll()
    }

    internal func didUnsubscribeFromCharacteristic(_ central: CBCentralInjectable) {
        self.centrals.removeValueForKey(central.identifier)
        if self.centrals.keys.count == 0 {
            self.isUpdating = false
        }
    }

    // MARK: Utils
    fileprivate func updateValues(_ values: [Data]) -> Bool  {
        guard let value = values.last else {
            return self.isUpdating
        }
        self.value = value
        if let peripheralManager = self.service?.peripheralManager , self.isUpdating && self.canNotify {
            for value in values {
                self.isUpdating = peripheralManager.updateValue(value, forCharacteristic:self)
                if !self.isUpdating {
                    self.queuedUpdates.append(value)
                }
            }
        } else {
            self.isUpdating = false
            self.queuedUpdates.append(value)
        }
        return self.isUpdating
    }

}
