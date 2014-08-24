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
    private let CHARACTERISTIC_READ_TIMEOUT     : Float  = 10.0
    private let CHARACTERISTIC_WRITE_TIMEOUT    : Float = 10.0
   
    private var notificationStateChangedSuccessCallback     : (() -> ())?
    private var notificationStateChangedFailedCallback      : ((error:NSError!) -> ())?
    private var afterUpdateSuccessCallback                  : (() -> ())?
    private var afterUpdateFailedCallback                   : ((error:NSError) -> ())?
    private var afterWriteSuccessCallback                   : (() -> ())?
    private var afterWriteFailedCallback                    : ((error:NSError) -> ())?
    
    private var reading = false
    private var writing = false
    
    private var readSequence    = 0
    private var writeSequence   = 0
    
    // INTERNAL
    internal let cbCharacteristic : CBCharacteristic
    internal let service          : Service
    internal let profile          : CharacteristicProfile!
    
    // PUBLIC
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
        if self.value {
            return self.profile.stringValues(self.value)
        } else {
            return nil
        }
    }
    
    public var anyValue : Any? {
        if self.value {
            return self.profile.anyValue(self.value)
        } else {
            return nil
        }
    }
    
    public var discreteStringValues : [String] {
        return self.profile.discreteStringValues
    }
    
    public func startNotifying(notificationStateChangedSuccessCallback:(() -> ())? = nil, notificationStateChangedFailedCallback:((error:NSError!) -> ())? = nil) {
        if self.propertyEnabled(.Notify) {
            self.notificationStateChangedSuccessCallback = notificationStateChangedSuccessCallback
            self.notificationStateChangedFailedCallback = notificationStateChangedFailedCallback
            self.service.perpheral.cbPeripheral .setNotifyValue(true, forCharacteristic:self.cbCharacteristic)
        }
    }

    public func stopNotifying(notificationStateChangedSuccessCallback:(() -> ())? = nil, notificationStateChangedFailedCallback:((error:NSError!) -> ())? = nil) {
        if self.propertyEnabled(.Notify) {
            self.notificationStateChangedSuccessCallback = notificationStateChangedSuccessCallback
            self.notificationStateChangedFailedCallback = notificationStateChangedFailedCallback
            self.service.perpheral.cbPeripheral .setNotifyValue(false, forCharacteristic:self.cbCharacteristic)
        }
    }

    public func startUpdates(afterUpdateSuccessCallback:() -> (), afterUpdateFailedCallback:((error:NSError)->())? = nil) {
        if self.propertyEnabled(.Notify) {
            self.afterUpdateSuccessCallback = afterUpdateSuccessCallback
            self.afterUpdateFailedCallback = afterUpdateFailedCallback
        }
    }

    public func stopUpdates() {
        if self.propertyEnabled(.Notify) {
            self.afterUpdateSuccessCallback = nil
            self.afterUpdateFailedCallback = nil
        }
    }

    public func propertyEnabled(property:CBCharacteristicProperties) -> Bool {
        return (self.properties.toRaw() & property.toRaw()) > 0
    }
    
    public func read(afterReadSuccessCallback:() -> (), afterReadFailedCallback:((error:NSError)->())?) {
        if self.propertyEnabled(.Read) {
            Logger.debug("Characteristic#read: \(self.uuid.UUIDString)")
            self.afterUpdateSuccessCallback = afterReadSuccessCallback
            self.afterUpdateFailedCallback = afterReadFailedCallback
            self.service.perpheral.cbPeripheral.readValueForCharacteristic(self.cbCharacteristic)
            self.reading = true
            ++self.readSequence
            self.timeoutRead(self.readSequence)
        } else {
            NSException(name:"Characteristic read error", reason: "read not supported by \(self.uuid.UUIDString)", userInfo: nil).raise()
        }
    }

    public func write(value:NSData, afterWriteSucessCallback:()->(), afterWriteFailedCallback:((error:NSError)->())? = nil) {
        if self.propertyEnabled(.Write) {
            Logger.debug("Characteristic#write: value=\(value.hexStringValue()), uuid=\(self.uuid.UUIDString)")
            self.afterWriteSuccessCallback = afterWriteSucessCallback
            self.afterWriteFailedCallback = afterWriteFailedCallback
            self.service.perpheral.cbPeripheral.writeValue(value, forCharacteristic:self.cbCharacteristic, type:.WithResponse)
            self.writing = true
            ++self.writeSequence
            self.timeoutWrite(self.writeSequence)
        } else {
            NSException(name:"Characteristic write error", reason: "write not supported by \(self.uuid.UUIDString)", userInfo: nil).raise()
        }
    }

    public func write(value:NSData, afterWriteFailedCallback:((error:NSError)->())? = nil) {
        if self.propertyEnabled(.WriteWithoutResponse) {
            Logger.debug("Characteristic#write: value=\(value.hexStringValue()), uuid=\(self.uuid.UUIDString)")
            self.afterWriteSuccessCallback = nil
            self.afterWriteFailedCallback = afterWriteFailedCallback
            self.service.perpheral.cbPeripheral.writeValue(value, forCharacteristic:self.cbCharacteristic, type:.WithoutResponse)
            self.writing = true
            ++self.writeSequence
            self.timeoutWrite(self.writeSequence)
        } else {
            NSException(name:"Characteristic write error", reason: "write without response not supported by \(self.uuid.UUIDString)", userInfo: nil).raise()
        }
    }

    public func write(stringValue:Dictionary<String, String>, afterWriteSuccessCallback:()->(), afterWriteFailedCallback:((error:NSError)->())? = nil) {
        if let value = self.profile.dataFromStringValue(stringValue) {
            self.write(value, afterWriteSucessCallback:afterWriteSuccessCallback, afterWriteFailedCallback:afterWriteFailedCallback)
        } else {
            NSException(name:"Characteristic write error", reason: "unable to serialize \(self.uuid.UUIDString)", userInfo: nil).raise()
        }
    }

    public func write(stringValue:Dictionary<String, String>, afterWriteFailedCallback:((error:NSError)->())? = nil) {
        if let value = self.profile.dataFromStringValue(stringValue) {
            self.write(value, afterWriteFailedCallback)
        } else {
            NSException(name:"Characteristic write error", reason: "unable to serialize \(self.uuid.UUIDString)", userInfo: nil).raise()
        }
    }

    public func write(anyValue:Any, afterWriteSuccessCallback:()->(), afterWriteFailedCallback:((error:NSError)->())? = nil) {
        if let value = self.profile.dataFromAnyValue(anyValue) {
            self.write(value, afterWriteSucessCallback:afterWriteSuccessCallback, afterWriteFailedCallback:afterWriteFailedCallback)
        } else {
            NSException(name:"Characteristic write error", reason: "unable to serialize \(self.uuid.UUIDString)", userInfo: nil).raise()
        }
    }

    public func write(anyValue:Any, afterWriteFailedCallback:((error:NSError)->())? = nil) {
        if let value = self.profile.dataFromAnyValue(anyValue) {
            self.write(value, afterWriteFailedCallback)
        } else {
            NSException(name:"Characteristic write error", reason: "unable to serialize \(self.uuid.UUIDString)", userInfo: nil).raise()
        }
    }

    // PRIVATE
    private func timeoutRead(sequence:Int) {
        Logger.debug("Characteristic#timeoutRead: sequence \(sequence)")
        CentralManager.delayCallback(CHARACTERISTIC_READ_TIMEOUT) {
            if sequence == self.readSequence && self.reading {
                self.reading = false
                Logger.debug("Characteristic#timeoutRead: timing out sequence=\(sequence), current readSequence=\(self.readSequence)")
                if let afterUpdateFailedCallback = self.afterUpdateFailedCallback {
                    CentralManager.asyncCallback(){
                        afterUpdateFailedCallback(error:NSError.errorWithDomain(BCError.domain, code:BCError.CharacteristicReadTimeout.code, userInfo:[NSLocalizedDescriptionKey:BCError.CharacteristicReadTimeout.description]))
                    }
                }
            } else {
                Logger.debug("Characteristic#timeoutRead: expired")
            }
        }
    }

    private func timeoutWrite(sequence:Int) {
        Logger.debug("Characteristic#timeoutWrite: sequence \(sequence)")
        CentralManager.delayCallback(CHARACTERISTIC_WRITE_TIMEOUT) {
            if sequence == self.writeSequence && self.writing {
                self.writing = false
                Logger.debug("Characteristic#timeoutWrite: timing out sequence=\(sequence), current writeSequence=\(self.writeSequence)")
                if let afterWriteFailedCallback = self.afterWriteFailedCallback {
                    CentralManager.asyncCallback(){
                        afterWriteFailedCallback(error:NSError.errorWithDomain(BCError.domain, code:BCError.CharacteristicWriteTimeout.code, userInfo:[NSLocalizedDescriptionKey:BCError.CharacteristicWriteTimeout.description]))
                    }
                }
            } else {
                Logger.debug("Characteristic#timeoutWrite: expired")
            }
        }
    }

    // INTERNAL
    internal init(cbCharacteristic:CBCharacteristic, service:Service) {
        self.cbCharacteristic = cbCharacteristic
        self.service = service
        self.profile = CharacteristicProfile(uuid:self.uuid.UUIDString, name:"Unknown")
        if let serviceProfile = ProfileManager.sharedInstance().serviceProfiles[service.uuid] {
            if let characteristicProfile = serviceProfile.characteristicProfiles[cbCharacteristic.UUID] {
                self.profile = characteristicProfile
            }
        }
    }
    
    internal func didDiscover() {
        Logger.debug("Characteristic#didDiscover:  uuid=\(self.uuid.UUIDString), name=\(self.name)")
        if let afterDiscovered = self.profile.afterDiscovered {
            CentralManager.asyncCallback(){afterDiscovered(characteristic:self)}
        }
    }
    
    internal func didUpdateNotificationState(error:NSError!) {
        if error {
            Logger.debug("Characteristic#didUpdateNotificationState Failed:  uuid=\(self.uuid.UUIDString), name=\(self.name)")
            if let notificationStateChangedFailedCallback = self.notificationStateChangedFailedCallback {
                CentralManager.asyncCallback(){notificationStateChangedFailedCallback(error:error)}
            }
        } else {
            Logger.debug("Characteristic#didUpdateNotificationState Success:  uuid=\(self.uuid.UUIDString), name=\(self.name)")
            if let notificationStateChangedSuccessCallback = self.notificationStateChangedSuccessCallback {
                CentralManager.asyncCallback(notificationStateChangedSuccessCallback)
            }
        }
    }
    
    internal func didUpdate(error:NSError!) {
        self.reading = false
        if error {
            Logger.debug("Characteristic#didUpdate Failed:  uuid=\(self.uuid.UUIDString), name=\(self.name)")
            if let afterUpdateFailedCallback = self.afterUpdateFailedCallback {
                CentralManager.asyncCallback(){afterUpdateFailedCallback(error:error)}
            }
        } else {
            Logger.debug("Characteristic#didUpdate Success:  uuid=\(self.uuid.UUIDString), name=\(self.name)")
            if let afterUpdateSuccessCallback = self.afterUpdateSuccessCallback {
                CentralManager.asyncCallback(afterUpdateSuccessCallback)
            }
        }
    }
    
    internal func didWrite(error:NSError!) {
        self.writing = false
        if error {
            Logger.debug("Characteristic#didWrite Failed:  uuid=\(self.uuid.UUIDString), name=\(self.name)")
            if let afterWriteFailedCallback = self.afterWriteFailedCallback {
                CentralManager.asyncCallback(){afterWriteFailedCallback(error:error)}
            }
        } else {
            Logger.debug("Characteristic#didWrite Success:  uuid=\(self.uuid.UUIDString), name=\(self.name)")
            if let afterWriteSuccessCallback = self.afterWriteSuccessCallback {
                CentralManager.asyncCallback(afterWriteSuccessCallback)
            }
        }
    }
}
