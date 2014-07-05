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
    
    var notificationStateChangedCallback    : (() -> ())?
    var afterUpdateSuccesCallback           : (() -> ())?
    var afterUpdateFailedCallback           : (() -> ())?
    var afterWriteSuccessCallback           : (() -> ())?
    var afterWriteFailedCallback            : (() -> ())?
    
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
    
    var value : NSData {
        return self.cbCharacteristic.value
    }

    var stringValue : Dictionary<String, String> {
        return self.profile.stringValue(self.value)
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

    func startNotifying(notificationStateChangedCallback:() -> ()) {
        if self.propertyEnabled(.Notify) {
            self.notificationStateChangedCallback = notificationStateChangedCallback
            self.service.perpheral.cbPeripheral .setNotifyValue(true, forCharacteristic:self.cbCharacteristic)
        }
    }

    func stopNotifying(notificationStateChangedCallback:() -> ()) {
        if self.propertyEnabled(.Notify) {
            self.notificationStateChangedCallback = notificationStateChangedCallback
            self.service.perpheral.cbPeripheral .setNotifyValue(false, forCharacteristic:self.cbCharacteristic)
        }
    }

    func startUpdates(afterUpdateSuccesCallback:() -> (), afterUpdateFailedCallback:()->()) {
        if self.propertyEnabled(.Notify) {
            self.afterUpdateSuccesCallback = afterUpdateSuccesCallback
            self.afterUpdateFailedCallback = afterUpdateFailedCallback
        }
    }

    func startUpdates(afterUpdateSuccesCallback:() -> ()) {
        if self.propertyEnabled(.Notify) {
            self.afterUpdateSuccesCallback = afterUpdateSuccesCallback
            self.afterUpdateFailedCallback = nil
        }
    }

    func stopUpdates(afterReadCallback:() -> ()) {
        if self.propertyEnabled(.Notify) {
            self.afterUpdateSuccesCallback = nil
            self.afterUpdateFailedCallback = nil
        }
    }

    func propertyEnabled(property:CBCharacteristicProperties) -> Bool {
        return (self.properties.toRaw() & property.toRaw()) > 0
    }
    
    func read(afterUpdateSuccesCallback:(() -> ())? = nil, afterUpdateFailedCallback:(()->())?) {
        if self.propertyEnabled(.Read) {
            self.afterUpdateSuccesCallback = afterUpdateSuccesCallback
            self.afterUpdateFailedCallback = afterUpdateFailedCallback
            self.service.perpheral.cbPeripheral.readValueForCharacteristic(self.cbCharacteristic)
            self.reading = true
            ++self.readSequence
            self.timeoutRead(self.readSequence)
        } else {
            NSException(name:"Characteristic read error", reason: "read not supported by \(self.uuid.UUIDString)", userInfo: nil).raise()
        }
    }

    func write(value:NSData, afterWriteSucessCallback:(()->())? = nil, afterWriteFailedCallback:(()->())? = nil) {
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
        let central = CentralManager.sharedinstance()
        Logger.debug("Characteristic#timeoutRead: sequence \(sequence)")
        central.delayCallback(CHARACTERISTIC_READ_TIMEOUT) {
            if sequence == self.readSequence && self.reading {
                self.reading = false
                Logger.debug("Characteristic#timeoutRead: timing out sequence=\(sequence), current readSequence=\(self.readSequence)")
            } else {
                Logger.debug("Characteristic#timeoutRead: expired")
            }
        }
    }

    func timeoutWrite(sequence:Int) {
        let central = CentralManager.sharedinstance()
        Logger.debug("Characteristic#timeoutWrite: sequence \(sequence)")
        central.delayCallback(CHARACTERISTIC_WRITE_TIMEOUT) {
            if sequence == self.writeSequence && self.writing {
                self.writing = false
                Logger.debug("Characteristic#timeoutWrite: timing out sequence=\(sequence), current writeSequence=\(self.writeSequence)")
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
}
