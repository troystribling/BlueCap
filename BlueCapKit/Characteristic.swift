//
//  Characteristic.swift
//  BlueCap
//
//  Created by Troy Stribling on 6/8/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation
import CoreBluetooth

class Characteristic {

    let CHARACTERISTIC_READ_TIMEOUT : Float  = 10.0
    let CHARACTERISTIC_WRITE_TIMEOUT : Float = 10.0
   
    let cbCharacteristic                    : CBCharacteristic!
    let service                             : Service!
    let profile                             : CharacteristicProfile!
    
    var notificationStateChangedSuccessCallback     : (() -> ())?
    var notificationStateChangedFailedCallback      : ((error:NSError!) -> ())?
    var afterUpdateSuccessCallback                  : (() -> ())?
    var afterUpdateFailedCallback                   : ((error:NSError) -> ())?
    var afterWriteSuccessCallback                   : (() -> ())?
    var afterWriteFailedCallback                    : ((error:NSError) -> ())?
    
    var reading = false
    var writing = false
    
    var readSequence    = 0
    var writeSequence   = 0
    
    var name : String {
        return self.profile.name
    }
    
    var uuid : CBUUID {
        return self.cbCharacteristic.UUID
    }
    
    var properties : CBCharacteristicProperties {
        return self.cbCharacteristic.properties
    }

    var isNotifying : Bool {
        return self.cbCharacteristic.isNotifying
    }
    
    var isBroadcasted : Bool {
        return self.cbCharacteristic.isBroadcasted
    }
    
    var value : NSData! {
        return self.cbCharacteristic.value
    }

    var stringValues : Dictionary<String, String>? {
        if self.value {
            return self.profile.stringValues(self.value)
        } else {
            return nil
        }
    }
    
    // APPLICATION INTERFACE
    init(cbCharacteristic:CBCharacteristic, service:Service) {
        self.cbCharacteristic = cbCharacteristic
        self.service = service
        if let serviceProfile = ProfileManager.sharedInstance().serviceProfiles[service.uuid] {
            self.profile = serviceProfile.characteristicProfiles[cbCharacteristic.UUID]
        } else {
            self.profile = CharacteristicProfile(uuid:self.uuid.UUIDString, name:"Unknown")
        }
    }

    func startNotifying(notificationStateChangedSuccessCallback:(() -> ())? = nil, notificationStateChangedFailedCallback:((error:NSError!) -> ())? = nil) {
        if self.propertyEnabled(.Notify) {
            self.notificationStateChangedSuccessCallback = notificationStateChangedSuccessCallback
            self.notificationStateChangedFailedCallback = notificationStateChangedFailedCallback
            self.service.perpheral.cbPeripheral .setNotifyValue(true, forCharacteristic:self.cbCharacteristic)
        }
    }

    func stopNotifying(notificationStateChangedSuccessCallback:(() -> ())? = nil, notificationStateChangedFailedCallback:((error:NSError!) -> ())? = nil) {
        if self.propertyEnabled(.Notify) {
            self.notificationStateChangedSuccessCallback = notificationStateChangedSuccessCallback
            self.notificationStateChangedFailedCallback = notificationStateChangedFailedCallback
            self.service.perpheral.cbPeripheral .setNotifyValue(false, forCharacteristic:self.cbCharacteristic)
        }
    }

    func startUpdates(afterUpdateSuccessCallback:() -> (), afterUpdateFailedCallback:((error:NSError)->())? = nil) {
        if self.propertyEnabled(.Notify) {
            self.afterUpdateSuccessCallback = afterUpdateSuccessCallback
            self.afterUpdateFailedCallback = afterUpdateFailedCallback
        }
    }

    func stopUpdates(afterReadCallback:() -> ()) {
        if self.propertyEnabled(.Notify) {
            self.afterUpdateSuccessCallback = nil
            self.afterUpdateFailedCallback = nil
        }
    }

    func propertyEnabled(property:CBCharacteristicProperties) -> Bool {
        return (self.properties.toRaw() & property.toRaw()) > 0
    }
    
    func read(afterReadSuccessCallback:() -> (), afterReadFailedCallback:((error:NSError)->())?) {
        if self.propertyEnabled(.Read) {
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

    func write(value:NSData, afterWriteSucessCallback:(()->())? = nil, afterWriteFailedCallback:((error:NSError)->())? = nil) {
        if self.propertyEnabled(.Write) {
            self.afterWriteSuccessCallback = afterWriteSucessCallback
            self.afterWriteFailedCallback = afterWriteFailedCallback
            if afterWriteSucessCallback {
                self.service.perpheral.cbPeripheral.writeValue(value, forCharacteristic:self.cbCharacteristic, type:.WithResponse)
            } else {
                self.service.perpheral.cbPeripheral.writeValue(value, forCharacteristic:self.cbCharacteristic, type:.WithoutResponse)
            }
            self.writing = true
            ++self.writeSequence
            self.timeoutWrite(self.writeSequence)
        } else {
            NSException(name:"Characteristic write error", reason: "write not supported by \(self.uuid.UUIDString)", userInfo: nil).raise()
        }
    }

    // PRIVATE INTERFACE
    func timeoutRead(sequence:Int) {
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

    func timeoutWrite(sequence:Int) {
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

    // INTERNAL INTERFACE
    func didDiscover() {
        if let afterDiscoveredCallback = self.profile?.afterDiscoveredCallback {
            CentralManager.asyncCallback(){afterDiscoveredCallback(characteristic:self)}
        }
    }
    
    func didUpdateNotificationState(error:NSError!) {
        if error {
            if let notificationStateChangedFailedCallback = self.notificationStateChangedFailedCallback {
                CentralManager.asyncCallback(){notificationStateChangedFailedCallback(error:error)}
            }
        } else {
            if let notificationStateChangedSuccessCallback = self.notificationStateChangedSuccessCallback {
                CentralManager.asyncCallback(notificationStateChangedSuccessCallback)
            }
        }
    }
    
    func didUpdate(error:NSError!) {
        self.reading = false
        if error {
            if let afterUpdateFailedCallback = self.afterUpdateFailedCallback {
                CentralManager.asyncCallback(){afterUpdateFailedCallback(error:error)}
            }
        } else {
            if let afterUpdateSuccessCallback = self.afterUpdateSuccessCallback {
                CentralManager.asyncCallback(afterUpdateSuccessCallback)
            }
        }
    }
    
    func didWrite(error:NSError!) {
        self.writing = false
        if error {
            if let afterWriteFailedCallback = self.afterWriteFailedCallback {
                CentralManager.asyncCallback(){afterWriteFailedCallback(error:error)}
            }
        } else {
            if let afterWriteSuccessCallback = self.afterWriteSuccessCallback {
                CentralManager.asyncCallback(afterWriteSuccessCallback)
            }
        }
    }
}
