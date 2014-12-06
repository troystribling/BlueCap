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

    // PRIVATE
    private var notificationStateChangedSuccess     : (() -> ())?
    private var notificationStateChangedFailed      : ((error:NSError) -> ())?
    private var afterUpdateSuccess                  : (() -> ())?
    private var afterUpdateFailed                   : ((error:NSError) -> ())?
    private var afterWritePromise                   : Promise<Void>!
    
    private var reading = false
    private var writing = false
    
    private var readSequence    = 0
    private var writeSequence   = 0
    private let defaultTimeout  = 10.0
    
    // INTERNAL
    internal let cbCharacteristic : CBCharacteristic
    internal let _service         : Service
    internal let profile          : CharacteristicProfile!
    
    // PUBLIC
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
            return self.profile.stringValues(self.value)
        } else {
            return nil
        }
    }
    
    public var anyValue : Any? {
        if self.value != nil {
            return self.profile.anyValue(self.value)
        } else {
            return nil
        }
    }
    
    public var discreteStringValues : [String] {
        return self.profile.discreteStringValues
    }
    
    public func startNotifying(notificationStateChangedSuccess:(() -> ())? = nil, notificationStateChangedFailed:((error:NSError) -> ())? = nil) {
        if self.propertyEnabled(.Notify) {
            self.notificationStateChangedSuccess = notificationStateChangedSuccess
            self.notificationStateChangedFailed = notificationStateChangedFailed
            self.service.peripheral.cbPeripheral .setNotifyValue(true, forCharacteristic:self.cbCharacteristic)
        }
    }

    public func stopNotifying(notificationStateChangedSuccess:(() -> ())? = nil, notificationStateChangedFailed:((error:NSError) -> ())? = nil) {
        if self.propertyEnabled(.Notify) {
            self.notificationStateChangedSuccess = notificationStateChangedSuccess
            self.notificationStateChangedFailed = notificationStateChangedFailed
            self.service.peripheral.cbPeripheral .setNotifyValue(false, forCharacteristic:self.cbCharacteristic)
        }
    }

    public func startUpdates(afterUpdateSuccess:() -> (), afterUpdateFailed:((error:NSError)->())? = nil) {
        if self.propertyEnabled(.Notify) {
            self.afterUpdateSuccess = afterUpdateSuccess
            self.afterUpdateFailed = afterUpdateFailed
        }
    }

    public func stopUpdates() {
        if self.propertyEnabled(.Notify) {
            self.afterUpdateSuccess = nil
            self.afterUpdateFailed = nil
        }
    }

    public func propertyEnabled(property:CBCharacteristicProperties) -> Bool {
        return (self.properties.rawValue & property.rawValue) > 0
    }
    
    public func read(afterReadSuccess:() -> (), afterReadFailed:((error:NSError)->())?) {
        if self.propertyEnabled(.Read) {
            Logger.debug("Characteristic#read: \(self.uuid.UUIDString)")
            self.afterUpdateSuccess = afterReadSuccess
            self.afterUpdateFailed = afterReadFailed
            self.service.peripheral.cbPeripheral.readValueForCharacteristic(self.cbCharacteristic)
            self.reading = true
            ++self.readSequence
            self.timeoutRead(self.readSequence)
        } else {
            NSException(name:"Characteristic read error", reason: "read not supported by \(self.uuid.UUIDString)", userInfo: nil).raise()
        }
    }

    public func writeData(value:NSData) -> Future<Void> {
        self.afterWritePromise = Promise<Void>()
        if self.propertyEnabled(.Write) {
            Logger.debug("Characteristic#write: value=\(value.hexStringValue()), uuid=\(self.uuid.UUIDString)")
            self.service.peripheral.cbPeripheral.writeValue(value, forCharacteristic:self.cbCharacteristic, type:.WithResponse)
            self.writing = true
            ++self.writeSequence
            self.timeoutWrite(self.writeSequence)
        } else {
            self.afterWritePromise.failure(NSError(domain:BCError.domain, code:BCError.CharateristicNotWritable.code, userInfo:[NSLocalizedDescriptionKey:BCError.CharateristicNotWritable.description]))
        }
        return self.afterWritePromise.future
    }

    public func writeString(stringValue:Dictionary<String, String>) -> Future<Void> {
        if let value = self.profile.dataFromStringValue(stringValue) {
            return self.writeData(value)
        } else {
            let promise = Promise<Void>()
            promise.failure(NSError(domain:BCError.domain, code:BCError.CharateristicNotSerializable.code, userInfo:[NSLocalizedDescriptionKey:BCError.CharateristicNotSerializable.description]))
            return promise.future
        }
    }

    public func write(anyValue:Any) -> Future<Void> {
        if let value = self.profile.dataFromAnyValue(anyValue) {
            return self.writeData(value)
        } else {
            let promise = Promise<Void>()
            promise.failure(NSError(domain:BCError.domain, code:BCError.CharateristicNotSerializable.code, userInfo:[NSLocalizedDescriptionKey:BCError.CharateristicNotSerializable.description]))
            return promise.future
        }
    }

    // PRIVATE
    private func timeoutRead(sequence:Int) {
        Logger.debug("Characteristic#timeoutRead: sequence \(sequence), timeout:\(self.readWriteTimeout())")
        CentralManager.delayCallback(self.readWriteTimeout()) {
            if sequence == self.readSequence && self.reading {
                self.reading = false
                Logger.debug("Characteristic#timeoutRead: timing out sequence=\(sequence), current readSequence=\(self.readSequence)")
                if let afterUpdateFailed = self.afterUpdateFailed {
                    CentralManager.asyncCallback {
                        afterUpdateFailed(error:
                            NSError(domain:BCError.domain, code:BCError.CharacteristicReadTimeout.code, userInfo:[NSLocalizedDescriptionKey:BCError.CharacteristicReadTimeout.description]))
                    }
                }
            } else {
                Logger.debug("Characteristic#timeoutRead: expired")
            }
        }
    }

    private func timeoutWrite(sequence:Int) {
        Logger.debug("Characteristic#timeoutWrite: sequence \(sequence), timeout:\(self.readWriteTimeout())")
        CentralManager.delayCallback(self.readWriteTimeout()) {
            if sequence == self.writeSequence && self.writing {
                self.writing = false
                Logger.debug("Characteristic#timeoutWrite: timing out sequence=\(sequence), current writeSequence=\(self.writeSequence)")
                if let afterWritePromise = self.afterWritePromise {
                    afterWritePromise.failure(NSError(domain:BCError.domain, code:BCError.CharacteristicWriteTimeout.code, userInfo:[NSLocalizedDescriptionKey:BCError.CharacteristicWriteTimeout.description]))
                }
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

    // INTERNAL
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
            if let notificationStateChangedFailed = self.notificationStateChangedFailed {
                CentralManager.asyncCallback {notificationStateChangedFailed(error:error)}
            }
        } else {
            Logger.debug("Characteristic#didUpdateNotificationState Success:  uuid=\(self.uuid.UUIDString), name=\(self.name)")
            if let notificationStateChangedSuccess = self.notificationStateChangedSuccess {
                CentralManager.asyncCallback(notificationStateChangedSuccess)
            }
        }
    }
    
    internal func didUpdate(error:NSError!) {
        self.reading = false
        if let error = error {
            Logger.debug("Characteristic#didUpdate Failed:  uuid=\(self.uuid.UUIDString), name=\(self.name)")
            if let afterUpdateFailed = self.afterUpdateFailed {
                CentralManager.asyncCallback {afterUpdateFailed(error:error)}
            }
        } else {
            Logger.debug("Characteristic#didUpdate Success:  uuid=\(self.uuid.UUIDString), name=\(self.name)")
            if let afterUpdateSuccess = self.afterUpdateSuccess {
                CentralManager.asyncCallback(afterUpdateSuccess)
            }
        }
    }
    
    internal func didWrite(error:NSError!) {
        self.writing = false
        if let afterWritePromise = self.afterWritePromise {
            if let error = error {
                Logger.debug("Characteristic#didWrite Failed:  uuid=\(self.uuid.UUIDString), name=\(self.name)")
                afterWritePromise.failure(error)
            } else {
                Logger.debug("Characteristic#didWrite Success:  uuid=\(self.uuid.UUIDString), name=\(self.name)")
                afterWritePromise.success()
            }
        }
    }
}
