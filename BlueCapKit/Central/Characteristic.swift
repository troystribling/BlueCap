//
//  Characteristic.swift
//  BlueCap
//
//  Created by Troy Stribling on 6/8/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import Foundation
import CoreBluetooth

public protocol CBCharacteristicWrappable {
    
    var uuid                    : CBUUID    {get}
    var isNotifying             : Bool      {get}
    
    func setNotifyValue(state:Bool)
    func propertyEnabled(property:CBCharacteristicProperties) -> Bool
    func readValueForCharacteristic()
    func writeValue(value:NSData)
    
}

public final class CharacteristicImpl<Wrapper:CharacteristicWrappable> {
    
    public var notificationUpdatePromise          : StreamPromise<Wrapper>?
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
    
    public func startNotifying(characteristic:Wrapper) -> Future<Wrapper> {
        self.notificationStateChangedPromise = Promise<Wrapper>()
        if characteristic.propertyEnabled(.Notify)                     ||
           characteristic.propertyEnabled(.Indicate)                   ||
           characteristic.propertyEnabled(.NotifyEncryptionRequired)   ||
           characteristic.propertyEnabled(.IndicateEncryptionRequired) {
            characteristic.setNotifyValue(true)
        }
        return self.notificationStateChangedPromise.future
    }
    
    public func stopNotifying(characteristic:Wrapper) -> Future<Wrapper> {
        self.notificationStateChangedPromise = Promise<Wrapper>()
        if characteristic.propertyEnabled(.Notify)                     ||
           characteristic.propertyEnabled(.Indicate)                   ||
           characteristic.propertyEnabled(.NotifyEncryptionRequired)   ||
           characteristic.propertyEnabled(.IndicateEncryptionRequired) {
            characteristic.setNotifyValue(false)
        }
        return self.notificationStateChangedPromise.future
    }
    
    public func recieveNotificationUpdates(capacity:Int? = nil) -> FutureStream<Wrapper> {
        self.notificationUpdatePromise = StreamPromise<Wrapper>(capacity:capacity)
        return self.notificationUpdatePromise!.future
    }
    
    public func stopNotificationUpdates() {
        self.notificationUpdatePromise = nil
    }
    
    public func read(characteristic:Wrapper, timeout:Double = 10.0) -> Future<Wrapper> {
        self.readPromise = Promise<Wrapper>()
        if characteristic.propertyEnabled(.Read) {
            Logger.debug("read characteristic \(characteristic.uuid.UUIDString)")
            characteristic.readValueForCharacteristic()
            self.reading = true
            ++self.readSequence
            self.timeoutRead(characteristic, sequence:self.readSequence, timeout:timeout)
        } else {
            self.readPromise.failure(BCError.characteristicReadNotSupported)
        }
        return self.readPromise.future
    }
    
    public func writeData(characteristic:Wrapper, value:NSData, timeout:Double = 10.0) -> Future<Wrapper> {
        self.writePromise = Promise<Wrapper>()
        if characteristic.propertyEnabled(.Write) || characteristic.propertyEnabled(.WriteWithoutResponse) {
            Logger.debug("write characteristic value=\(value.hexStringValue()), uuid=\(characteristic.uuid.UUIDString)")
            characteristic.writeValue(value)
            self.writing = true
            ++self.writeSequence
            self.timeoutWrite(characteristic, sequence:self.writeSequence, timeout:timeout)
        } else {
            self.writePromise.failure(BCError.characteristicWriteNotSupported)
        }
        return self.writePromise.future
    }
    
    public func writeString(characteristic:Wrapper, stringValue:[String:String], timeout:Double = 10.0) -> Future<Wrapper> {
        if let value = characteristic.dataFromStringValue(stringValue) {
            return self.writeData(characteristic, value:value)
        } else {
            self.writePromise = Promise<Wrapper>()
            self.writePromise.failure(BCError.characteristicNotSerilaizable)
            return self.writePromise.future
        }
    }
    
    public func write<T:Deserializable>(characteristic:Wrapper, value:T, timeout:Double = 10.0) -> Future<Wrapper> {
        return self.writeData(characteristic, value:Serde.serialize(value), timeout:timeout)
    }
    
    public func write<T:RawDeserializable>(characteristic:Wrapper, value:T, timeout:Double = 10.0) -> Future<Wrapper> {
        return self.writeData(characteristic, value:Serde.serialize(value), timeout:timeout)
    }
    
    public func write<T:RawArrayDeserializable>(characteristic:Wrapper, value:T, timeout:Double = 10.0) -> Future<Wrapper> {
        return self.writeData(characteristic, value:Serde.serialize(value), timeout:timeout)
    }
    
    public func write<T:RawPairDeserializable>(characteristic:Wrapper, value:T, timeout:Double = 10.0) -> Future<Wrapper> {
        return self.writeData(characteristic, value:Serde.serialize(value), timeout:timeout)
    }
    
    public func write<T:RawArrayPairDeserializable>(characteristic:Wrapper, value:T, timeout:Double = 10.0) -> Future<Wrapper> {
        return self.writeData(characteristic, value:Serde.serialize(value), timeout:timeout)
    }
    
    private func timeoutRead(characteristic:Wrapper, sequence:Int, timeout:Double) {
        Logger.debug("sequence \(sequence), timeout:\(timeout))")
        CentralQueue.delay(timeout) {
            if sequence == self.readSequence && self.reading {
                self.reading = false
                Logger.debug("timing out sequence=\(sequence), current readSequence=\(self.readSequence)")
                self.readPromise.failure(BCError.characteristicReadTimeout)
            } else {
                Logger.debug("timeout expired")
            }
        }
    }
    
    private func timeoutWrite(characteristic:Wrapper, sequence:Int, timeout:Double) {
        Logger.debug("sequence \(sequence), timeout:\(timeout)")
        CentralQueue.delay(timeout) {
            if sequence == self.writeSequence && self.writing {
                self.writing = false
                Logger.debug("timing out sequence=\(sequence), current writeSequence=\(self.writeSequence)")
                self.writePromise.failure(BCError.characteristicWriteTimeout)
            } else {
                Logger.debug("timeout expired")
            }
        }
    }
    
    public func didDiscover(characteristic:Wrapper) {
        Logger.debug("uuid=\(characteristic.uuid.UUIDString), name=\(characteristic.name)")
        if let afterDiscoveredPromise = characteristic.afterDiscoveredPromise {
            afterDiscoveredPromise.success(characteristic)
        }
    }
    
    public func didUpdateNotificationState(characteristic:Wrapper, error:NSError!) {
        if let error = error {
            Logger.debug("failed uuid=\(characteristic.uuid.UUIDString), name=\(characteristic.name)")
            self.notificationStateChangedPromise.failure(error)
        } else {
            Logger.debug("success:  uuid=\(characteristic.uuid.UUIDString), name=\(characteristic.name)")
            self.notificationStateChangedPromise.success(characteristic)
        }
    }
    
    public func didUpdate(characteristic:Wrapper, error:NSError!) {
        self.reading = false
        if let error = error {
            Logger.debug("failed uuid=\(characteristic.uuid.UUIDString), name=\(characteristic.name)")
            if characteristic.isNotifying {
                if let notificationUpdatePromise = self.notificationUpdatePromise {
                    notificationUpdatePromise.failure(error)
                }
            } else {
                self.readPromise.failure(error)
            }
        } else {
            Logger.debug("success uuid=\(characteristic.uuid.UUIDString), name=\(characteristic.name)")
            if characteristic.isNotifying {
                if let notificationUpdatePromise = self.notificationUpdatePromise {
                    notificationUpdatePromise.success(characteristic)
                }
            } else {
                self.readPromise.success(characteristic)
            }
        }
    }
    
    public func didWrite(characteristic:Wrapper, error:NSError!) {
        self.writing = false
        if let error = error {
            Logger.debug("failed:  uuid=\(characteristic.uuid.UUIDString), name=\(characteristic.name)")
            if !self.writePromise.completed {
                self.writePromise.failure(error)
            }
        } else {
            Logger.debug("success:  uuid=\(characteristic.uuid.UUIDString), name=\(characteristic.name)")
            if !self.writePromise.completed {
                self.writePromise.success(characteristic)
            }
        }
    }

}
// CharacteristicImpl
///////////////////////////////////////////

public class Characteristic {

    private var notificationStateChangedPromise     = Promise<Characteristic>()
    private var readPromise                         = Promise<Characteristic>()
    private var writePromise                        = Promise<Characteristic>()
    private var notificationUpdatePromise : StreamPromise<Characteristic>?
    private var peripheral : Peripheral
    
    private var reading                             = false
    private var writing                             = false
    
    private var readSequence                        = 0
    private var writeSequence                       = 0
    private let defaultTimeout                      = 10.0

    // CharacteristicWrappable
    public var uuid : CBUUID {
        return self.cbCharacteristic.UUID
    }
    
    public var name : String {
        return self.profile.name
    }
    
    public var isNotifying : Bool {
        return self.cbCharacteristic.isNotifying
    }
    
    public var stringValues : [String] {
        return self.profile.stringValues
    }
    
    public var afterDiscoveredPromise : StreamPromise<Characteristic>? {
        return self.profile.afterDiscoveredPromise
    }
    
    public func stringValue(data:NSData?) -> [String:String]? {
        if let data = data {
            return self.profile.stringValue(data)
        } else {
            return nil
        }
    }
    
    public func dataFromStringValue(stringValue:[String:String]) -> NSData? {
        return self.profile.dataFromStringValue(stringValue)
    }
    
    public func setNotifyValue(state:Bool) {
        self.peripheral.setNotifyValue(state, forCharacteristic:self)
    }
    
    public func propertyEnabled(property:CBCharacteristicProperties) -> Bool {
        return (self.properties.rawValue & property.rawValue) > 0
    }
    
    public func readValueForCharacteristic() {
        self.service.peripheral.cbPeripheral.readValueForCharacteristic(self.cbCharacteristic)
    }
    
    public func writeValue(value:NSData) {
        self.service.peripheral.cbPeripheral.writeValue(value, forCharacteristic:self.cbCharacteristic, type:.WithResponse)
    }
    // CharacteristicWrappable
    
    internal let cbCharacteristic : CBCharacteristic
    internal let _service         : Service
    internal let profile          : CharacteristicProfile
    
    public var service : Service {
        return self._service
    }
    
    public var dataValue : NSData? {
        return self.cbCharacteristic.value
    }

    public var stringValue :[String:String]? {
        return self.impl.stringValue(self, data:self.dataValue)
    }

    public var properties : CBCharacteristicProperties {
        return self.cbCharacteristic.properties
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
        return self.impl.startNotifying(self)
    }

    public func stopNotifying() -> Future<Characteristic> {
        return self.impl.stopNotifying(self)
    }

    public func recieveNotificationUpdates(capacity:Int? = nil) -> FutureStream<Characteristic> {
        return self.impl.recieveNotificationUpdates(capacity)
    }
    
    public func stopNotificationUpdates() {
        self.impl.stopNotificationUpdates()
    }
    
    public func read(timeout:Double = 10.0) -> Future<Characteristic> {
        return self.impl.read(self, timeout:timeout)
    }

    public func writeData(value:NSData, timeout:Double = 10.0) -> Future<Characteristic> {
        return self.impl.writeData(self, value:value, timeout:timeout)
    }

    public func writeString(stringValue:[String:String], timeout:Double = 10.0) -> Future<Characteristic> {
        return self.impl.writeString(self, stringValue:stringValue, timeout:timeout)
    }

    public func write<T:Deserializable>(value:T, timeout:Double = 10.0) -> Future<Characteristic> {
        return self.impl.write(self, value:value, timeout:timeout)
    }
    
    public func write<T:RawDeserializable>(value:T, timeout:Double = 10.0) -> Future<Characteristic> {
        return self.impl.write(self, value:value, timeout:timeout)
    }

    public func write<T:RawArrayDeserializable>(value:T, timeout:Double = 10.0) -> Future<Characteristic> {
        return self.impl.write(self, value:value, timeout:timeout)
    }

    public func write<T:RawPairDeserializable>(value:T, timeout:Double = 10.0) -> Future<Characteristic> {
        return self.impl.write(self, value:value, timeout:timeout)
    }
    
    public func write<T:RawArrayPairDeserializable>(value:T, timeout:Double = 10.0) -> Future<Characteristic> {
        return self.impl.write(self, value:value, timeout:timeout)
    }

    internal init(cbCharacteristic:CBCharacteristic, service:Service) {
        self.cbCharacteristic = cbCharacteristic
        self._service = service
        if let serviceProfile = ProfileManager.sharedInstance.serviceProfiles[service.uuid] {
            Logger.debug("creating characteristic for service profile: \(service.name):\(service.uuid)")
            if let characteristicProfile = serviceProfile.characteristicProfiles[cbCharacteristic.UUID] {
                Logger.debug("charcteristic profile found creating characteristic: \(characteristicProfile.name):\(characteristicProfile.uuid.UUIDString)")
                self.profile = characteristicProfile
            } else {
                Logger.debug("no characteristic profile found. Creating characteristic with UUID: \(service.uuid.UUIDString)")
                self.profile = CharacteristicProfile(uuid:service.uuid.UUIDString)
            }
        } else {
            Logger.debug("no service profile found. Creating characteristic with UUID: \(service.uuid.UUIDString)")
            self.profile = CharacteristicProfile(uuid:service.uuid.UUIDString)
        }
    }
    
    internal func didDiscover() {
        self.impl.didDiscover(self)
    }
    
    internal func didUpdateNotificationState(error:NSError?) {
        self.impl.didUpdateNotificationState(self, error:error)
    }
    
    internal func didUpdate(error:NSError?) {
        self.impl.didUpdate(self, error:error)
    }
    
    internal func didWrite(error:NSError?) {
        self.impl.didWrite(self, error:error)
    }
    
    private func notifyEnabled() -> Bool {
        return self.propertyEnabled(.Notify) || self.propertyEnabled(.Indicate) || self.propertyEnabled(.NotifyEncryptionRequired) || self .propertyEnabled(.IndicateEncryptionRequired)
    }
}
