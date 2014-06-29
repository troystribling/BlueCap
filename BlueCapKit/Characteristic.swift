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
    let profile                             : CharacteristicProfile?
    
    var notificationStateChangedCallback    : (() -> ())?
    var afterReadCallback                   : (() -> ())?
    var afterWriteCallback                  : (() -> ())?
    
    var name : String {
        if let profile = self.profile {
            return profile.name
        } else {
            return "Unknown"
        }
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
    return [self.name: "value"]
    }
    
    // APPLICATION INTERFACE
    init(cbCharacteristic:CBCharacteristic, service:Service) {
        self.cbCharacteristic = cbCharacteristic
        self.service = service
        if let serviceProfile = ProfileManager.sharedInstance().serviceProfiles[service.uuid] {
            self.profile = serviceProfile.characteristicProfiles[cbCharacteristic.UUID]
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
    
    // INTERNAL INTERFACE
    func didDiscover() {
        if let afterDiscoveredCallback = self.profile?.afterDiscoveredCallback {
            CentralManager.asyncCallback(){afterDiscoveredCallback(characteristic:self)}
        }
    }
}
