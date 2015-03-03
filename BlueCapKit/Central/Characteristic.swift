//
//  Characteristic.swift
//  BlueCap
//
//  Created by Troy Stribling on 6/8/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation
import CoreBluetooth

///////////////////////////////////////////
// CharacteristicImpl
public protocol CharacteristicWrappable {

    var uuid                    : CBUUID!                   {get}
    var name                    : String                    {get}
    var connectorator           : Connectorator?            {get}
    var isNotifying             : Bool                      {get}
    var stringValues            : [String]                  {get}
    var afterDiscoveredPromise  : StreamPromise<Self>?      {get}
    
    
    func stringValue(data:NSData?) -> [String:String]?
    func dataFromStringValue(stringValue:[String:String]) -> NSData?
    
    func setNotifyValue(state:Bool)
    func propertyEnabled(property:CBCharacteristicProperties) -> Bool
    func readValueForCharacteristic()
    func writeValue(value:NSData)
    
}

public final class CharacteristicImpl<Wrapper:CharacteristicWrappable> {
    
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
    
    public func startNotifying(characteristic:Wrapper) -> Future<Wrapper> {
        self.notificationStateChangedPromise = Promise<Wrapper>()
        if characteristic.propertyEnabled(.Notify) {
            characteristic.setNotifyValue(true)
        }
        return self.notificationStateChangedPromise.future
    }
    
    public func stopNotifying(characteristic:Wrapper) -> Future<Wrapper> {
        self.notificationStateChangedPromise = Promise<Wrapper>()
        if characteristic.propertyEnabled(.Notify) {
            characteristic.setNotifyValue(false)
        }
        return self.notificationStateChangedPromise.future
    }
    
    public func recieveNotificationUpdates(capacity:Int? = nil) -> FutureStream<Wrapper> {
        if let capacity = capacity {
            self.notificationUpdatePromise = StreamPromise<Wrapper>(capacity:capacity)
        } else {
            self.notificationUpdatePromise = StreamPromise<Wrapper>()
        }
        return self.notificationUpdatePromise!.future
    }
    
    public func stopNotificationUpdates() {
        self.notificationUpdatePromise = nil
    }
    
    public func read(characteristic:Wrapper) -> Future<Wrapper> {
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
    
    public func writeData(characteristic:Wrapper, value:NSData) -> Future<Wrapper> {
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
    
    public func writeString(characteristic:Wrapper, stringValue:[String:String]) -> Future<Wrapper> {
        if let value = characteristic.dataFromStringValue(stringValue) {
            return self.writeData(characteristic, value:value)
        } else {
            self.writePromise = Promise<Wrapper>()
            self.writePromise.failure(BCError.characteristicNotSerilaizable)
            return self.writePromise.future
        }
    }
    
    public func write<T:Deserializable>(characteristic:Wrapper, value:T) -> Future<Wrapper> {
        return self.writeData(characteristic, value:Serde.serialize(value))
    }
    
    public func write<T:RawDeserializable>(characteristic:Wrapper, value:T) -> Future<Wrapper> {
        return self.writeData(characteristic, value:Serde.serialize(value))
    }
    
    public func write<T:RawArrayDeserializable>(characteristic:Wrapper, value:T) -> Future<Wrapper> {
        return self.writeData(characteristic, value:Serde.serialize(value))
    }
    
    public func write<T:RawPairDeserializable>(characteristic:Wrapper, value:T) -> Future<Wrapper> {
        return self.writeData(characteristic, value:Serde.serialize(value))
    }
    
    public func write<T:RawArrayPairDeserializable>(characteristic:Wrapper, value:T) -> Future<Wrapper> {
        return self.writeData(characteristic, value:Serde.serialize(value))
    }
    
    private func timeoutRead(characteristic:Wrapper, sequence:Int) {
        Logger.debug("CharacteristicImpl#timeoutRead: sequence \(sequence), timeout:\(self.readWriteTimeout(characteristic))")
        CentralQueue.delay(self.readWriteTimeout(characteristic)) {
            if sequence == self.readSequence && self.reading {
                self.reading = false
                Logger.debug("CharacteristicImpl#timeoutRead: timing out sequence=\(sequence), current readSequence=\(self.readSequence)")
                self.readPromise.failure(BCError.characteristicReadTimeout)
            } else {
                Logger.debug("CharacteristicImpl#timeoutRead: expired")
            }
        }
    }
    
    private func timeoutWrite(characteristic:Wrapper, sequence:Int) {
        Logger.debug("CharacteristicImpl#timeoutWrite: sequence \(sequence), timeout:\(self.readWriteTimeout(characteristic))")
        CentralQueue.delay(self.readWriteTimeout(characteristic)) {
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
    
    internal func didUpdate(characteristic:Wrapper, error:NSError!) {
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
    
    internal func didWrite(characteristic:Wrapper, error:NSError!) {
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
// CharacteristicImpl
///////////////////////////////////////////

public final class Characteristic : CharacteristicWrappable {

    internal var impl = CharacteristicImpl<Characteristic>()
    
    // CharacteristicWrappable
    public var uuid : CBUUID! {
        return self.cbCharacteristic.UUID
    }
    
    public var name : String {
        return self.profile.name
    }
    
    public var connectorator : Connectorator? {
        return self.service.peripheral.connectorator
    }
    
    public var isNotifying : Bool {
        return self.cbCharacteristic.isNotifying
    }
    
    public var stringValues : [String] {
        return self.profile.stringValues
    }
    
    public var afterDiscoveredPromise  : StreamPromise<Characteristic>? {
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
        self.service.peripheral.cbPeripheral.setNotifyValue(state, forCharacteristic:self.cbCharacteristic)
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

    public var isBroadcasted : Bool {
        return self.cbCharacteristic.isBroadcasted
    }
    
    public var dataValue : NSData! {
        return self.cbCharacteristic.value
    }

    public var stringValue :[String:String]? {
        return self.impl.stringValue(self, data:self.dataValue)
    }

    public var properties : CBCharacteristicProperties {
        return self.cbCharacteristic.properties
    }
    
    public func value<T:Deserializable>() -> T? {
        return self.impl.value(self.dataValue)
    }

    public func value<T:RawDeserializable where T.RawType:Deserializable>() -> T? {
        return self.impl.value(self.dataValue)
    }

    public func value<T:RawArrayDeserializable where T.RawType:Deserializable>() -> T? {
        return self.impl.value(self.dataValue)
    }

    public func value<T:RawPairDeserializable where T.RawType1:Deserializable, T.RawType2:Deserializable>() -> T? {
        return self.impl.value(self.dataValue)
    }

    public func value<T:RawArrayPairDeserializable where T.RawType1:Deserializable, T.RawType2:Deserializable>() -> T? { 
        return self.impl.value(self.dataValue)
    }

    public func startNotifying() -> Future<Characteristic> {
        return self.impl.startNotifying(self)
    }

    public func stopNotifying() -> Future<Characteristic> {
        return self.impl.stopNotifying(self)
    }

    public func recieveNotificationUpdates(capacity:Int? = nil) -> FutureStream<Characteristic> {
        return self.impl.recieveNotificationUpdates(capacity:capacity)
    }
    
    public func stopNotificationUpdates() {
        self.impl.stopNotificationUpdates()
    }
    
    public func read() -> Future<Characteristic> {
        return self.impl.read(self)
    }

    public func writeData(value:NSData) -> Future<Characteristic> {
        return self.impl.writeData(self, value:value)
    }

    public func writeString(stringValue:[String:String]) -> Future<Characteristic> {
        return self.impl.writeString(self, stringValue:stringValue)
    }

    public func write<T:Deserializable>(value:T) -> Future<Characteristic> {
        return self.impl.write(self, value:value)
    }
    
    public func write<T:RawDeserializable>(value:T) -> Future<Characteristic> {
        return self.impl.write(self, value:value)
    }

    public func write<T:RawArrayDeserializable>(value:T) -> Future<Characteristic> {
        return self.impl.write(self, value:value)
    }

    public func write<T:RawPairDeserializable>(value:T) -> Future<Characteristic> {
        return self.impl.write(self, value:value)
    }
    
    public func write<T:RawArrayPairDeserializable>(value:T) -> Future<Characteristic> {
        return self.impl.write(self, value:value)
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
        self.impl.didDiscover(self)
    }
    
    internal func didUpdateNotificationState(error:NSError!) {
        self.impl.didUpdateNotificationState(self, error:error)
    }
    
    internal func didUpdate(error:NSError!) {
        self.impl.didUpdate(self, error:error)
    }
    
    internal func didWrite(error:NSError!) {
        self.impl.didWrite(self, error:error)
    }
}
