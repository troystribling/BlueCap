//
//  Characteristic.swift
//  BlueCap
//
//  Created by Troy Stribling on 6/8/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation
import CoreBluetooth

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
    internal let profile          : CharacteristicProfile!
    
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
    
    public var value : NSData! {
        return self.cbCharacteristic.value
    }

    public var stringValues : Dictionary<String, String>? {
        if self.value != nil {
            return self.profile.stringValue(self.value)
        } else {
            return nil
        }
    }
    
    public var discreteStringValues : [String] {
        return self.profile.discreteStringValues
    }
    
    public func startNotifying() -> Future<Characteristic> {
        self.notificationStateChangedPromise = Promise<Characteristic>()
        if self.propertyEnabled(.Notify) {
            self.service.peripheral.cbPeripheral .setNotifyValue(true, forCharacteristic:self.cbCharacteristic)
        }
        return self.notificationStateChangedPromise.future
    }

    public func stopNotifying() -> Future<Characteristic> {
        self.notificationStateChangedPromise = Promise<Characteristic>()
        if self.propertyEnabled(.Notify) {
            self.service.peripheral.cbPeripheral .setNotifyValue(false, forCharacteristic:self.cbCharacteristic)
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

    public func write<T:RawDeserializable>(anyValue:T) -> Future<Characteristic> {
        if let value = self.profile.dataFromAnyValue(anyValue) {
            return self.writeData(value)
        } else {
            self.writePromise = Promise<Characteristic>()
            self.writePromise.failure(BCError.characteristicNotSerilaizable)
            return self.writePromise.future
        }
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
        self.profile = CharacteristicProfile(uuid:self.uuid.UUIDString, name:"Unknown")
        if let serviceProfile = ProfileManager.sharedInstance.serviceProfiles[service.uuid] {
            if let characteristicProfile = serviceProfile.characteristicProfiles[cbCharacteristic.UUID] {
                self.profile = characteristicProfile
            }
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
