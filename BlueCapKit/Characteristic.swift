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
    
    let cbCharacteristic                    : CBCharacteristic!
    let service                             : Service!
    let profile                             : CharacteristicProfile!
    
    var notificationStateChangedCallback    : (() -> ())?
    var afterReadCallback                   : (() -> ())?
    var afterWriteCallback                  : (() -> ())?
    
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

    func startUpdates(afterReadCallback:() -> ()) {
        if self.propertyEnabled(.Notify) {
            self.afterReadCallback = afterReadCallback
        }
    }

    func stopUpdates(afterReadCallback:() -> ()) {
        if self.propertyEnabled(.Notify) {
            self.afterReadCallback = nil
        }
    }

    func propertyEnabled(property:CBCharacteristicProperties) -> Bool {
        return (self.properties.toRaw() & property.toRaw()) > 0
    }
    
    func read(afterReadCallback:()->()) {
        if self.propertyEnabled(.Read) {
            self.afterReadCallback = afterReadCallback
            self.service.perpheral.cbPeripheral.readValueForCharacteristic(self.cbCharacteristic)
        } else {
            NSException(name:"Characteristic read error", reason: "read not supported by \(self.uuid.UUIDString)", userInfo: nil).raise()
        }
    }
    
    func write(value:NSData, afterWriteCallback:()->()) {
        if self.propertyEnabled(.Write) {
            self.afterWriteCallback = afterWriteCallback
            self.service.perpheral.cbPeripheral.writeValue(value, forCharacteristic:self.cbCharacteristic, type:.WithResponse)
        } else {
            NSException(name:"Characteristic write error", reason: "write not supported by \(self.uuid.UUIDString)", userInfo: nil).raise()
        }
    }

    func write(value:NSData) {
        if self.propertyEnabled(.WriteWithoutResponse) {
            self.afterWriteCallback = nil
            self.service.perpheral.cbPeripheral.writeValue(value, forCharacteristic:self.cbCharacteristic, type:.WithoutResponse)
        } else {
            NSException(name:"Characteristic write error", reason: "write  without responsde not supported by \(self.uuid.UUIDString)", userInfo: nil).raise()
        }
    }

    // INTERNAL INTERFACE
    func didDiscover() {
        if let afterDiscoveredCallback = self.profile?.afterDiscoveredCallback {
            CentralManager.asyncCallback(){afterDiscoveredCallback(characteristic:self)}
        }
    }
}
