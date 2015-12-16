//
//  Characteristic.swift
//  BlueCap
//
//  Created by Troy Stribling on 6/8/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import Foundation
import CoreBluetooth

struct WriteParameters {
    let value : NSData
    let timeout : Double
    let type : CBCharacteristicWriteType
}

struct ReadParameters {
    let timeout : Double
}

public class Characteristic {

    private var notificationStateChangedPromise : Promise<Characteristic>
    private var readPromises = [Promise<Characteristic>]()
    private var writePromises = [Promise<Characteristic>]()
    private var notificationUpdatePromise : StreamPromise<Characteristic>?
    
    private var writeParameters = [WriteParameters]()
    private var readParameters = [ReadParameters]()
    
    private weak var _service : Service?
    
    private let profile : CharacteristicProfile
    private let ioQueue : Queue
    private let futureQueue : Queue

    private var reading         = false
    private var writing         = false
    
    private var readSequence    = 0
    private var writeSequence   = 0
    private let defaultTimeout  = 10.0

    internal let cbCharacteristic : CBCharacteristic
    
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
    
    public init(cbCharacteristic:CBCharacteristic, service:Service) {
        self.cbCharacteristic = cbCharacteristic
        self._service = service
        self.futureQueue = Queue("us.gnos.characteristic-future-\(cbCharacteristic.UUID.UUIDString)")
        self.ioQueue = Queue("us.gnos.characteristic-timeout-\(cbCharacteristic.UUID.UUIDString)")
        self.notificationStateChangedPromise = Promise<Characteristic>(queue:self.futureQueue)
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
        let promise = Promise<Characteristic>(queue:self.futureQueue)
        if self.canNotify {
            self.ioQueue.async() {
                self.notificationStateChangedPromise = promise
                self.setNotifyValue(true)
            }
        } else {
            promise.failure(BCError.characteristicNotifyNotSupported)
        }
        return promise.future
    }

    public func stopNotifying() -> Future<Characteristic> {
        let promise = Promise<Characteristic>(queue:self.futureQueue)
        if self.canNotify {
            self.ioQueue.async() {
                self.notificationStateChangedPromise = promise
                self.setNotifyValue(false)
            }
        } else {
            promise.failure(BCError.characteristicNotifyNotSupported)
        }
        return promise.future
    }

    public func recieveNotificationUpdates(capacity:Int? = nil) -> FutureStream<Characteristic> {
        let promise = StreamPromise<Characteristic>(queue:self.futureQueue, capacity:capacity)
        if self.canNotify {
            self.ioQueue.async() {self.notificationUpdatePromise = promise}
        } else {
            promise.failure(BCError.characteristicNotifyNotSupported)
        }
        return promise.future
    }
    
    public func stopNotificationUpdates() {
        self.ioQueue.async() {
            self.notificationUpdatePromise = nil
        }
    }
    
    public func read(timeout:Double = 10.0) -> Future<Characteristic> {
        let promise = Promise<Characteristic>(queue:self.futureQueue)
        if self.canRead {
            self.ioQueue.async() {
                self.readPromises.append(promise)
                self.readParameters.append(ReadParameters(timeout:timeout))
                self.readNext()
            }
        } else {
            promise.failure(BCError.characteristicReadNotSupported)
        }
        return promise.future
    }

    public func writeData(value:NSData, timeout:Double = 10.0, type:CBCharacteristicWriteType = .WithResponse) -> Future<Characteristic> {
        let promise = Promise<Characteristic>(queue:self.futureQueue)
        if self.canWrite {
            self.ioQueue.async() {
                self.writePromises.append(promise)
                self.writeParameters.append(WriteParameters(value:value, timeout:timeout, type:type))
                self.writeNext()
            }
        } else {
            promise.failure(BCError.characteristicWriteNotSupported)
        }
        return promise.future
    }

    public func writeString(stringValue:[String:String], timeout:Double = 10.0, type:CBCharacteristicWriteType = .WithResponse) -> Future<Characteristic> {
        if let value = self.dataFromStringValue(stringValue) {
            return self.writeData(value, timeout:timeout, type:type)
        } else {
            let promise = Promise<Characteristic>(queue:self.futureQueue)
            promise.failure(BCError.characteristicNotSerilaizable)
            return promise.future
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

    public func didUpdateNotificationState(error:NSError?) {
        self.ioQueue.async() {
            if let error = error {
                Logger.debug("failed uuid=\(self.uuid.UUIDString), name=\(self.name)")
                self.notificationStateChangedPromise.failure(error)
            } else {
                Logger.debug("success:  uuid=\(self.uuid.UUIDString), name=\(self.name)")
                self.notificationStateChangedPromise.success(self)
            }
        }
    }
    
    public func didUpdate(error:NSError?) {
        self.ioQueue.async() {
            if self.isNotifying {
                self.didNotify(error)
            } else {
                self.didRead(error)
            }
        }
    }
    
    internal func didWrite(error:NSError?) {
        self.ioQueue.async() {
            if let promise = self.writePromises.first {
                self.writePromises.removeAtIndex(0)
                if let error = error {
                    Logger.debug("failed:  uuid=\(self.uuid.UUIDString), name=\(self.name)")
                    if !promise.completed {
                        promise.failure(error)
                    }
                } else {
                    Logger.debug("success:  uuid=\(self.uuid.UUIDString), name=\(self.name)")
                    if !promise.completed {
                        promise.success(self)
                    }
                }
            }
            self.writing = false
            self.writeNext()
        }
    }

    private func didRead(error:NSError?) {
        if let promise = self.readPromises.first {
            self.readPromises.removeAtIndex(0)
            if let error = error {
                if !promise.completed {
                    promise.failure(error)
                }
            } else {
                if !promise.completed {
                    promise.success(self)
                }
            }
        }
        self.reading = false
        self.readNext()
    }


    private func didNotify(error:NSError?) {
        if let error = error {
            if let notificationUpdatePromise = self.notificationUpdatePromise {
                notificationUpdatePromise.failure(error)
            }
        } else {
            if let notificationUpdatePromise = self.notificationUpdatePromise {
                notificationUpdatePromise.success(self)
            }
        }
    }
    
    private func timeoutRead(sequence:Int, timeout:Double) {
        Logger.debug("sequence \(sequence), timeout:\(timeout))")
        self.ioQueue.delay(timeout) {
            if sequence == self.readSequence && self.reading {
                Logger.debug("timing out sequence=\(sequence), current readSequence=\(self.readSequence)")
                self.didUpdate(BCError.characteristicReadTimeout)
            } else {
                Logger.debug("timeout expired")
            }
        }
    }
    
    private func timeoutWrite(sequence:Int, timeout:Double) {
        Logger.debug("sequence \(sequence), timeout:\(timeout)")
        self.ioQueue.delay(timeout) {
            if sequence == self.writeSequence && self.writing {
                Logger.debug("timing out sequence=\(sequence), current writeSequence=\(self.writeSequence)")
                self.didWrite(BCError.characteristicWriteTimeout)
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
    
    private func writeNext() {
        if self.writing == false && self.writeParameters.count > 0 {
            let parameters = self.writeParameters[0]
            self.writeParameters.removeAtIndex(0)
            Logger.debug("write characteristic value=\(parameters.value.hexStringValue()), uuid=\(self.uuid.UUIDString)")
            self.writeValue(parameters.value, type:parameters.type)
            self.writing = true
            ++self.writeSequence
            self.timeoutWrite(self.writeSequence, timeout:parameters.timeout)
        }
    }
    
    private func readNext() {
        if self.reading == false && self.readParameters.count > 0 {
            Logger.debug("read characteristic \(self.uuid.UUIDString)")
            let parameters = self.readParameters[0]
            self.readParameters.removeAtIndex(0)
            self.readValueForCharacteristic()
            self.reading = true
            ++self.readSequence
            self.timeoutRead(self.readSequence, timeout:parameters.timeout)
        }
    }
}
