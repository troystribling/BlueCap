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
    
    var UUID : CBUUID                           {get}
    var isNotifying : Bool                      {get}
    var value : NSData?                         {get}
    var properties : CBCharacteristicProperties {get}
    
}

extension CBCharacteristic : CBCharacteristicWrappable {}

public class Characteristic {

    private var notificationStateChangedPromise     = Promise<Characteristic>()
    private var readPromise                         = Promise<Characteristic>()
    private var writePromise                        = Promise<Characteristic>()
    private var notificationUpdatePromise : StreamPromise<Characteristic>?
    private weak var _service : Service?
    private let profile : CharacteristicProfile
    
    private var reading                             = false
    private var writing                             = false
    
    private var readSequence                        = 0
    private var writeSequence                       = 0
    private let defaultTimeout                      = 10.0

    internal let cbCharacteristic : CBCharacteristicWrappable
    
    public var uuid : CBUUID {
        return self.cbCharacteristic.UUID
    }
    
    public var name : String {
        return self.profile.name
    }
    
    public var isNotifying : Bool {
        return self.cbCharacteristic.isNotifying
    }
    
    public var afterDiscoveredPromise : StreamPromise<Characteristic>? {
        return self.profile.afterDiscoveredPromise
    }
    
    public var canNotify : Bool {
        return self.propertyEnabled(.Notify)                    ||
               self.propertyEnabled(.Indicate)                  ||
               self.propertyEnabled(.NotifyEncryptionRequired)  ||
               self.propertyEnabled(.IndicateEncryptionRequired)
    }
    
    public var canRead : Bool {
        return self.propertyEnabled(.Read)
    }
    
    public var canWrite : Bool {
        return self.propertyEnabled(.Write) || self.propertyEnabled(.WriteWithoutResponse)
    }
    
    public var service : Service? {
        return self._service
    }
    
    public var dataValue : NSData? {
        return self.cbCharacteristic.value
    }
    
    public var stringValues : [String] {
        return self.profile.stringValues
    }

    public var stringValue :[String:String]? {
        return self.stringValue(self.dataValue)
    }
    
    public var properties : CBCharacteristicProperties {
        return self.cbCharacteristic.properties
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
    
    public func propertyEnabled(property:CBCharacteristicProperties) -> Bool {
        return (self.properties.rawValue & property.rawValue) > 0
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
        if self.canNotify {
            self.setNotifyValue(true)
        } else {
            self.notificationStateChangedPromise.failure(BCError.characteristicNotifyNotSupported)
        }
        return self.notificationStateChangedPromise.future
    }

    public func stopNotifying() -> Future<Characteristic> {
        self.notificationStateChangedPromise = Promise<Characteristic>()
        if self.canNotify {
            self.setNotifyValue(false)
        } else {
            self.notificationStateChangedPromise.failure(BCError.characteristicNotifyNotSupported)
        }
        return self.notificationStateChangedPromise.future
    }

    public func recieveNotificationUpdates(capacity:Int? = nil) -> FutureStream<Characteristic> {
        if self.canNotify {
            self.notificationUpdatePromise = StreamPromise<Characteristic>(capacity:capacity)
        } else {
            self.notificationStateChangedPromise.failure(BCError.characteristicNotifyNotSupported)
        }
        return self.notificationUpdatePromise!.future
    }
    
    public func stopNotificationUpdates() {
        self.notificationUpdatePromise = nil
    }
    
    public func read(timeout:Double = 10.0) -> Future<Characteristic> {
        self.readPromise = Promise<Characteristic>()
        if self.canRead {
            Logger.debug("read characteristic \(self.uuid.UUIDString)")
            self.readValueForCharacteristic()
            self.reading = true
            ++self.readSequence
            self.timeoutRead(self.readSequence, timeout:timeout)
        } else {
            self.readPromise.failure(BCError.characteristicReadNotSupported)
        }
        return self.readPromise.future
    }

    public func writeData(value:NSData, timeout:Double = 10.0, type:CBCharacteristicWriteType = .WithResponse) -> Future<Characteristic> {
        self.writePromise = Promise<Characteristic>()
        if self.canWrite {
            Logger.debug("write characteristic value=\(value.hexStringValue()), uuid=\(self.uuid.UUIDString)")
            self.writeValue(value, type:type)
            self.writing = true
            ++self.writeSequence
            self.timeoutWrite(self.writeSequence, timeout:timeout)
        } else {
            self.writePromise.failure(BCError.characteristicWriteNotSupported)
        }
        return self.writePromise.future
    }

    public func writeString(stringValue:[String:String], timeout:Double = 10.0, type:CBCharacteristicWriteType = .WithResponse) -> Future<Characteristic> {
        if let value = self.dataFromStringValue(stringValue) {
            return self.writeData(value, timeout:timeout, type:type)
        } else {
            self.writePromise = Promise<Characteristic>()
            self.writePromise.failure(BCError.characteristicNotSerilaizable)
            return self.writePromise.future
        }
    }

    public func write<T:Deserializable>(value:T, timeout:Double = 10.0, type:CBCharacteristicWriteType = .WithResponse) -> Future<Characteristic> {
        return self.writeData(Serde.serialize(value), timeout:timeout, type:type)
    }
    
    public func write<T:RawDeserializable>(value:T, timeout:Double = 10.0, type:CBCharacteristicWriteType = .WithResponse) -> Future<Characteristic> {
        return self.writeData(Serde.serialize(value), timeout:timeout, type:type)
    }

    public func write<T:RawArrayDeserializable>(value:T, timeout:Double = 10.0, type:CBCharacteristicWriteType = .WithResponse) -> Future<Characteristic> {
        return self.writeData(Serde.serialize(value), timeout:timeout, type:type)
    }

    public func write<T:RawPairDeserializable>(value:T, timeout:Double = 10.0, type:CBCharacteristicWriteType = .WithResponse) -> Future<Characteristic> {
        return self.writeData(Serde.serialize(value), timeout:timeout, type:type)
    }
    
    public func write<T:RawArrayPairDeserializable>(value:T, timeout:Double = 10.0, type:CBCharacteristicWriteType = .WithResponse) -> Future<Characteristic> {
        return self.writeData(Serde.serialize(value), timeout:timeout, type:type)
    }

    internal init(cbCharacteristic:CBCharacteristicWrappable, service:Service) {
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
    
    internal func didUpdateNotificationState(error:NSError?) {
        if let error = error {
            Logger.debug("failed uuid=\(self.uuid.UUIDString), name=\(self.name)")
            self.notificationStateChangedPromise.failure(error)
        } else {
            Logger.debug("success:  uuid=\(self.uuid.UUIDString), name=\(self.name)")
            self.notificationStateChangedPromise.success(self)
        }
    }
    
    internal func didUpdate(error:NSError?) {
        self.reading = false
        if let error = error {
            Logger.debug("failed uuid=\(self.uuid.UUIDString), name=\(self.name)")
            if self.isNotifying {
                if let notificationUpdatePromise = self.notificationUpdatePromise {
                    notificationUpdatePromise.failure(error)
                }
            } else {
                self.readPromise.failure(error)
            }
        } else {
            Logger.debug("success uuid=\(self.uuid.UUIDString), name=\(self.name)")
            if self.isNotifying {
                if let notificationUpdatePromise = self.notificationUpdatePromise {
                    notificationUpdatePromise.success(self)
                }
            } else {
                self.readPromise.success(self)
            }
        }
    }
    
    internal func didWrite(error:NSError?) {
        self.writing = false
        if let error = error {
            Logger.debug("failed:  uuid=\(self.uuid.UUIDString), name=\(self.name)")
            if !self.writePromise.completed {
                self.writePromise.failure(error)
            }
        } else {
            Logger.debug("success:  uuid=\(self.uuid.UUIDString), name=\(self.name)")
            if !self.writePromise.completed {
                self.writePromise.success(self)
            }
        }
    }
    
    private func timeoutRead(sequence:Int, timeout:Double) {
        Logger.debug("sequence \(sequence), timeout:\(timeout))")
        self.service?.peripheral?.centralManager?.centralQueue.delay(timeout) {
            if sequence == self.readSequence && self.reading {
                self.reading = false
                Logger.debug("timing out sequence=\(sequence), current readSequence=\(self.readSequence)")
                self.readPromise.failure(BCError.characteristicReadTimeout)
            } else {
                Logger.debug("timeout expired")
            }
        }
    }
    
    private func timeoutWrite(sequence:Int, timeout:Double) {
        Logger.debug("sequence \(sequence), timeout:\(timeout)")
        self.service?.peripheral?.centralManager?.centralQueue.delay(timeout) {
            if sequence == self.writeSequence && self.writing {
                self.writing = false
                Logger.debug("timing out sequence=\(sequence), current writeSequence=\(self.writeSequence)")
                self.writePromise.failure(BCError.characteristicWriteTimeout)
            } else {
                Logger.debug("timeout expired")
            }
        }
    }
    
    private func setNotifyValue(state:Bool) {
        self.service?.peripheral?.setNotifyValue(state, forCharacteristic:self)
    }
    
    private func readValueForCharacteristic() {
        self.service?.peripheral?.readValueForCharacteristic(self)
    }
    
    private func writeValue(value:NSData, type:CBCharacteristicWriteType = .WithResponse) {
        self.service?.peripheral?.writeValue(value, forCharacteristic:self, type:type)
    }
    

}
