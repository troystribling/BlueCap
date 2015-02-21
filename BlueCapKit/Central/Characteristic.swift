//
//  Characteristic.swift
//  BlueCap
//
//  Created by Troy Stribling on 6/8/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation
import CoreBluetooth

public protocol CharacteristicWrapper {

    var uuid                    : CBUUID                {get}
    var name                    : String                {get}
    var connectorator           : Connectorator?        {get}
    var isNotifying             : Bool                  {get}
    var stringValues            : [String]              {get}
    var afterDiscoveredPromise  : StreamPromise<Self>?  {get}
    
    
    func stringValue(data:NSData?) -> [String:String]?
    func dataFromStringValue(stringValue:[String:String]) -> NSData?
    
    func setNotifyValue(state:Bool)
    func propertyEnabled(property:CBCharacteristicProperties) -> Bool
    func readValueForCharacteristic()
    func writeValue(value:NSData)
    
}

///////////////////////////////////////////
// IMPL
public struct CharacteristicImpl<Wrapper:CharacteristicWrapper> {
    
    private var notificationUpdatePromise          : StreamPromise<Wrapper>?
    private var notificationStateChangedPromise    = Promise<Wrapper>()
    private var readPromise                        = Promise<Wrapper>()
    private var writePromise                       = Promise<Wrapper>()
    
    private var reading = false
    private var writing = false
    
    private var readSequence    = 0
    private var writeSequence   = 0
    private let defaultTimeout  = 10.0
    
    public init() {
    }
    
    public func stringValue(characteristic:Wrapper, data:NSData?) -> [String:String]? {
        return characteristic.stringValue(data).map{$0}
    }
    
    public func stringValues(characteristic:Wrapper) -> [String] {
        return characteristic.stringValues
    }
    
    public func value<T:Deserializable>(data:NSData?) -> T? {
        if let data = data {
            return T.deserialize(data)
        } else {
            return nil
        }
    }
    
    public func value<T:RawDeserializable where T.RawType:Deserializable>(data:NSData?) -> T? {
        if let data = data {
            return Serde.deserialize(data)
        } else {
            return nil
        }
    }
    
    public func value<T:RawArrayDeserializable where T.RawType:Deserializable>(data:NSData?) -> T? {
        if let data = data {
            return Serde.deserialize(data)
        } else {
            return nil
        }
    }
    
    public func value<T:RawPairDeserializable where T.RawType1:Deserializable, T.RawType2:Deserializable>(data:NSData?) -> T? {
        if let data = data {
            return Serde.deserialize(data)
        } else {
            return nil
        }
    }
    
    public func value<T:RawArrayPairDeserializable where T.RawType1:Deserializable, T.RawType2:Deserializable>(data:NSData?) -> T? {
        if let data = data {
            return Serde.deserialize(data)
        } else {
            return nil
        }
    }
    
    public mutating func startNotifying(characteristic:Wrapper) -> Future<Wrapper> {
        self.notificationStateChangedPromise = Promise<Wrapper>()
        if characteristic.propertyEnabled(.Notify) {
            characteristic.setNotifyValue(true)
        }
        return self.notificationStateChangedPromise.future
    }
    
    public mutating func stopNotifying(characteristic:Wrapper) -> Future<Wrapper> {
        self.notificationStateChangedPromise = Promise<Wrapper>()
        if characteristic.propertyEnabled(.Notify) {
            characteristic.setNotifyValue(false)
        }
        return self.notificationStateChangedPromise.future
    }
    
    public mutating func recieveNotificationUpdates(capacity:Int? = nil) -> FutureStream<Wrapper> {
        if let capacity = capacity {
            self.notificationUpdatePromise = StreamPromise<Wrapper>(capacity:capacity)
        } else {
            self.notificationUpdatePromise = StreamPromise<Wrapper>()
        }
        return self.notificationUpdatePromise!.future
    }
    
    public mutating func stopNotificationUpdates() {
        self.notificationUpdatePromise = nil
    }
    
    public mutating func read(characteristic:Wrapper) -> Future<Wrapper> {
        self.readPromise = Promise<Wrapper>()
        if characteristic.propertyEnabled(.Read) {
            Logger.debug("CharacteristicImpl#read: \(characteristic.uuid.UUIDString)")
            characteristic.readValueForCharacteristic()
            self.reading = true
            ++self.readSequence
            self.timeoutRead(characteristic, sequence:self.readSequence)
        } else {
            self.readPromise.failure(BCError.characteristicReadNotSupported)
        }
        return self.readPromise.future
    }
    
    public mutating func writeData(characteristic:Wrapper, value:NSData) -> Future<Wrapper> {
        self.writePromise = Promise<Wrapper>()
        if characteristic.propertyEnabled(.Write) {
            Logger.debug("CharacteristicImpl#write: value=\(value.hexStringValue()), uuid=\(characteristic.uuid.UUIDString)")
            characteristic.writeValue(value)
            self.writing = true
            ++self.writeSequence
            self.timeoutWrite(characteristic, sequence:self.writeSequence)
        } else {
            self.writePromise.failure(BCError.characteristicWriteNotSupported)
        }
        return self.writePromise.future
    }
    
    public mutating func writeString(characteristic:Wrapper, stringValue:[String:String]) -> Future<Wrapper> {
        if let value = characteristic.dataFromStringValue(stringValue) {
            return self.writeData(characteristic, value:value)
        } else {
            self.writePromise = Promise<Wrapper>()
            self.writePromise.failure(BCError.characteristicNotSerilaizable)
            return self.writePromise.future
        }
    }
    
    public mutating func write<T:Deserializable>(characteristic:Wrapper, value:T) -> Future<Wrapper> {
        return self.writeData(characteristic, value:Serde.serialize(value))
    }
    
    public mutating func write<T:RawDeserializable>(characteristic:Wrapper, value:T) -> Future<Wrapper> {
        return self.writeData(characteristic, value:Serde.serialize(value))
    }
    
    public mutating func write<T:RawArrayDeserializable>(characteristic:Wrapper, value:T) -> Future<Wrapper> {
        return self.writeData(characteristic, value:Serde.serialize(value))
    }
    
    public mutating func write<T:RawPairDeserializable>(characteristic:Wrapper, value:T) -> Future<Wrapper> {
        return self.writeData(characteristic, value:Serde.serialize(value))
    }
    
    public mutating func write<T:RawArrayPairDeserializable>(characteristic:Wrapper, value:T) -> Future<Wrapper> {
        return self.writeData(characteristic, value:Serde.serialize(value))
    }
    
    private mutating func timeoutRead(characteristic:Wrapper, sequence:Int) {
        Logger.debug("CharacteristicImpl#timeoutRead: sequence \(sequence), timeout:\(self.readWriteTimeout(characteristic))")
        CentralManager.delay(self.readWriteTimeout(characteristic)) {
            if sequence == self.readSequence && self.reading {
                self.reading = false
                Logger.debug("CharacteristicImpl#timeoutRead: timing out sequence=\(sequence), current readSequence=\(self.readSequence)")
                self.readPromise.failure(BCError.characteristicReadTimeout)
            } else {
                Logger.debug("CharacteristicImpl#timeoutRead: expired")
            }
        }
    }
    
    private mutating func timeoutWrite(characteristic:Wrapper, sequence:Int) {
        Logger.debug("CharacteristicImpl#timeoutWrite: sequence \(sequence), timeout:\(self.readWriteTimeout(characteristic))")
        CentralManager.delay(self.readWriteTimeout(characteristic)) {
            if sequence == self.writeSequence && self.writing {
                self.writing = false
                Logger.debug("CharacteristicImpl#timeoutWrite: timing out sequence=\(sequence), current writeSequence=\(self.writeSequence)")
                self.writePromise.failure(BCError.characteristicWriteTimeout)
            } else {
                Logger.debug("CharacteristicImpl#timeoutWrite: expired")
            }
        }
    }
    
    private func readWriteTimeout(characteristic:Wrapper) -> Double {
        if let connectorator = characteristic.connectorator {
            return connectorator.characteristicTimeout
        } else {
            return self.defaultTimeout
        }
    }
    
    internal func didDiscover(characteristic:Wrapper) {
        Logger.debug("CharacteristicImpl#didDiscover:  uuid=\(characteristic.uuid.UUIDString), name=\(characteristic.name)")
        if let afterDiscoveredPromise = characteristic.afterDiscoveredPromise {
            afterDiscoveredPromise.success(characteristic)
        }
    }
    
    internal func didUpdateNotificationState(characteristic:Wrapper, error:NSError!) {
        if let error = error {
            Logger.debug("CharacteristicImpl#didUpdateNotificationState Failed:  uuid=\(characteristic.uuid.UUIDString), name=\(characteristic.name)")
            self.notificationStateChangedPromise.failure(error)
        } else {
            Logger.debug("CharacteristicImpl#didUpdateNotificationState Success:  uuid=\(characteristic.uuid.UUIDString), name=\(characteristic.name)")
            self.notificationStateChangedPromise.success(characteristic)
        }
    }
    
    internal mutating func didUpdate(characteristic:Wrapper, error:NSError!) {
        self.reading = false
        if let error = error {
            Logger.debug("CharacteristicImpl#didUpdate Failed:  uuid=\(characteristic.uuid.UUIDString), name=\(characteristic.name)")
            if characteristic.isNotifying {
                if let notificationUpdatePromise = self.notificationUpdatePromise {
                    notificationUpdatePromise.failure(error)
                }
            } else {
                self.readPromise.failure(error)
            }
        } else {
            Logger.debug("CharacteristicImpl#didUpdate Success:  uuid=\(characteristic.uuid.UUIDString), name=\(characteristic.name)")
            if characteristic.isNotifying {
                if let notificationUpdatePromise = self.notificationUpdatePromise {
                    notificationUpdatePromise.success(characteristic)
                }
            } else {
                self.readPromise.success(characteristic)
            }
        }
    }
    
    internal mutating func didWrite(characteristic:Wrapper, error:NSError!) {
        self.writing = false
        if let error = error {
            Logger.debug("CharacteristicImpl#didWrite Failed:  uuid=\(characteristic.uuid.UUIDString), name=\(characteristic.name)")
            self.writePromise.failure(error)
        } else {
            Logger.debug("CharacteristicImpl#didWrite Success:  uuid=\(characteristic.uuid.UUIDString), name=\(characteristic.name)")
            self.writePromise.success(characteristic)
        }
    }

}
// IMPL

///////////////////////////////////////////

public class Characteristic {

    private var notificationUpdatePromise          : StreamPromise<Characteristic>?
    private var notificationStateChangedPromise    = Promise<Characteristic>()
    private var readPromise                        = Promise<Characteristic>()
    private var writePromise                       = Promise<Characteristic>()
    
    private var reading = false
    private var writing = false
    
    private var readSequence    = 0
    private var writeSequence   = 0
    private let defaultTimeout  = 10.0
    
    internal let cbCharacteristic : CBCharacteristic
    internal let _service         : Service
    internal let profile          : CharacteristicProfile
    
    public var service : Service {
        return self._service
    }
    
    public var name : String {
        return self.profile.name
    }
    
    public var uuid : CBUUID! {
        return self.cbCharacteristic.UUID
    }
    
    public var properties : CBCharacteristicProperties {
        return self.cbCharacteristic.properties
    }

    public var isNotifying : Bool {
        return self.cbCharacteristic.isNotifying
    }
    
    public var isBroadcasted : Bool {
        return self.cbCharacteristic.isBroadcasted
    }
    
    public var dataValue : NSData! {
        return self.cbCharacteristic.value
    }

    public var stringValue :[String:String]? {
        if let data = self.dataValue {
            return self.profile.stringValue(data)
        } else {
            return nil
        }
    }
    
    public var stringValues : [String] {
        return self.profile.stringValues
    }
    
    public func value<T:Deserializable>() -> T? {
        if let data = self.dataValue {
            return T.deserialize(data)
        } else {
            return nil
        }
    }

    public func value<T:RawDeserializable where T.RawType:Deserializable>() -> T? {
        if let data = self.dataValue {
            return Serde.deserialize(data)
        } else {
            return nil
        }
    }

    public func value<T:RawArrayDeserializable where T.RawType:Deserializable>() -> T? {
        if let data = self.dataValue {
            return Serde.deserialize(data)
        } else {
            return nil
        }
    }

    public func value<T:RawPairDeserializable where T.RawType1:Deserializable, T.RawType2:Deserializable>() -> T? {
        if let data = self.dataValue {
            return Serde.deserialize(data)
        } else {
            return nil
        }
    }

    public func value<T:RawArrayPairDeserializable where T.RawType1:Deserializable, T.RawType2:Deserializable>() -> T? { 
        if let data = self.dataValue {
            return Serde.deserialize(data)
        } else {
            return nil
        }
    }

    public func startNotifying() -> Future<Characteristic> {
        self.notificationStateChangedPromise = Promise<Characteristic>()
        if self.propertyEnabled(.Notify) {
            self.service.peripheral.cbPeripheral.setNotifyValue(true, forCharacteristic:self.cbCharacteristic)
        }
        return self.notificationStateChangedPromise.future
    }

    public func stopNotifying() -> Future<Characteristic> {
        self.notificationStateChangedPromise = Promise<Characteristic>()
        if self.propertyEnabled(.Notify) {
            self.service.peripheral.cbPeripheral.setNotifyValue(false, forCharacteristic:self.cbCharacteristic)
        }
        return self.notificationStateChangedPromise.future
    }

    public func recieveNotificationUpdates(capacity:Int? = nil) -> FutureStream<Characteristic> {
        if let capacity = capacity {
            self.notificationUpdatePromise = StreamPromise<Characteristic>(capacity:capacity)
        } else {
            self.notificationUpdatePromise = StreamPromise<Characteristic>()
        }
        return self.notificationUpdatePromise!.future
    }
    
    public func stopNotificationUpdates() {
        self.notificationUpdatePromise = nil
    }
    
    public func propertyEnabled(property:CBCharacteristicProperties) -> Bool {
        return (self.properties.rawValue & property.rawValue) > 0
    }
    
    public func read() -> Future<Characteristic> {
        self.readPromise = Promise<Characteristic>()
        if self.propertyEnabled(.Read) {
            Logger.debug("Characteristic#read: \(self.uuid.UUIDString)")
            self.service.peripheral.cbPeripheral.readValueForCharacteristic(self.cbCharacteristic)
            self.reading = true
            ++self.readSequence
            self.timeoutRead(self.readSequence)
        } else {
            self.readPromise.failure(BCError.characteristicReadNotSupported)
        }
        return self.readPromise.future
    }

    public func writeData(value:NSData) -> Future<Characteristic> {
        self.writePromise = Promise<Characteristic>()
        if self.propertyEnabled(.Write) {
            Logger.debug("Characteristic#write: value=\(value.hexStringValue()), uuid=\(self.uuid.UUIDString)")
            self.service.peripheral.cbPeripheral.writeValue(value, forCharacteristic:self.cbCharacteristic, type:.WithResponse)
            self.writing = true
            ++self.writeSequence
            self.timeoutWrite(self.writeSequence)
        } else {
            self.writePromise.failure(BCError.characteristicWriteNotSupported)
        }
        return self.writePromise.future
    }

    public func writeString(stringValue:Dictionary<String, String>) -> Future<Characteristic> {
        if let value = self.profile.dataFromStringValue(stringValue) {
            return self.writeData(value)
        } else {
            self.writePromise = Promise<Characteristic>()
            self.writePromise.failure(BCError.characteristicNotSerilaizable)
            return self.writePromise.future
        }
    }

    public func write<T:Deserializable>(value:T) -> Future<Characteristic> {
        return self.writeData(Serde.serialize(value))
    }
    
    public func write<T:RawDeserializable>(value:T) -> Future<Characteristic> {
        return self.writeData(Serde.serialize(value))
    }

    public func write<T:RawArrayDeserializable>(value:T) -> Future<Characteristic> {
        return self.writeData(Serde.serialize(value))
    }

    public func write<T:RawPairDeserializable>(value:T) -> Future<Characteristic> {
        return self.writeData(Serde.serialize(value))
    }
    
    public func write<T:RawArrayPairDeserializable>(value:T) -> Future<Characteristic> {
        return self.writeData(Serde.serialize(value))
    }

    private func timeoutRead(sequence:Int) {
        Logger.debug("Characteristic#timeoutRead: sequence \(sequence), timeout:\(self.readWriteTimeout())")
        CentralManager.delay(self.readWriteTimeout()) {
            if sequence == self.readSequence && self.reading {
                self.reading = false
                Logger.debug("Characteristic#timeoutRead: timing out sequence=\(sequence), current readSequence=\(self.readSequence)")
                self.readPromise.failure(BCError.characteristicReadTimeout)
            } else {
                Logger.debug("Characteristic#timeoutRead: expired")
            }
        }
    }

    private func timeoutWrite(sequence:Int) {
        Logger.debug("Characteristic#timeoutWrite: sequence \(sequence), timeout:\(self.readWriteTimeout())")
        CentralManager.delay(self.readWriteTimeout()) {
            if sequence == self.writeSequence && self.writing {
                self.writing = false
                Logger.debug("Characteristic#timeoutWrite: timing out sequence=\(sequence), current writeSequence=\(self.writeSequence)")
                self.writePromise.failure(BCError.characteristicWriteTimeout)
            } else {
                Logger.debug("Characteristic#timeoutWrite: expired")
            }
        }
    }
    
    private func readWriteTimeout() -> Double {
        if let connectorator = self.service.peripheral.connectorator {
            return connectorator.characteristicTimeout
        } else {
            return self.defaultTimeout
        }
    }

    internal init(cbCharacteristic:CBCharacteristic, service:Service) {
        self.cbCharacteristic = cbCharacteristic
        self._service = service
        if let serviceProfile = ProfileManager.sharedInstance.serviceProfiles[service.uuid] {
            Logger.debug("Charcteristic#init: Creating characteristic for service profile: \(service.name):\(service.uuid)")
            if let characteristicProfile = serviceProfile.characteristicProfiles[cbCharacteristic.UUID] {
                Logger.debug("Charcteristic#init: Charcteristic profile found creating characteristic: \(characteristicProfile.name):\(characteristicProfile.uuid.UUIDString)")
                self.profile = characteristicProfile
            } else {
                Logger.debug("Charcteristic#init: No characteristic profile found. Creating characteristic with UUID: \(service.uuid.UUIDString)")
                self.profile = CharacteristicProfile(uuid:service.uuid.UUIDString)
            }
        } else {
            Logger.debug("No service profile found. Creating characteristic with UUID: \(service.uuid.UUIDString)")
            self.profile = CharacteristicProfile(uuid:service.uuid.UUIDString)
        }
    }
    
    internal func didDiscover() {
        Logger.debug("Characteristic#didDiscover:  uuid=\(self.uuid.UUIDString), name=\(self.name)")
        if let afterDiscoveredPromise = self.profile.afterDiscoveredPromise {
            afterDiscoveredPromise.success(self)
        }
    }
    
    internal func didUpdateNotificationState(error:NSError!) {
        if let error = error {
            Logger.debug("Characteristic#didUpdateNotificationState Failed:  uuid=\(self.uuid.UUIDString), name=\(self.name)")
            self.notificationStateChangedPromise.failure(error)
        } else {
            Logger.debug("Characteristic#didUpdateNotificationState Success:  uuid=\(self.uuid.UUIDString), name=\(self.name)")
            self.notificationStateChangedPromise.success(self)
        }
    }
    
    internal func didUpdate(error:NSError!) {
        self.reading = false
        if let error = error {
            Logger.debug("Characteristic#didUpdate Failed:  uuid=\(self.uuid.UUIDString), name=\(self.name)")
            if self.isNotifying {
                if let notificationUpdatePromise = self.notificationUpdatePromise {
                    notificationUpdatePromise.failure(error)
                }
            } else {
                self.readPromise.failure(error)
            }
        } else {
            Logger.debug("Characteristic#didUpdate Success:  uuid=\(self.uuid.UUIDString), name=\(self.name)")
            if self.isNotifying {
                if let notificationUpdatePromise = self.notificationUpdatePromise {
                    notificationUpdatePromise.success(self)
                }
            } else {
                self.readPromise.success(self)
            }
        }
    }
    
    internal func didWrite(error:NSError!) {
        self.writing = false
        if let error = error {
            Logger.debug("Characteristic#didWrite Failed:  uuid=\(self.uuid.UUIDString), name=\(self.name)")
            self.writePromise.failure(error)
        } else {
            Logger.debug("Characteristic#didWrite Success:  uuid=\(self.uuid.UUIDString), name=\(self.name)")
            self.writePromise.success(self)
        }
    }
}
