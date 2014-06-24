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
    
    let cbCharacteristic    : CBCharacteristic!
    let service             : Service!
    let profile             : CharacteristicProfile?
    
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

    // APPLICATION INTERFACE
    init(cbCharacteristic:CBCharacteristic, service:Service) {
        self.cbCharacteristic = cbCharacteristic
        self.service = service
        if let serviceProfile = ProfileManager.sharedInstance().serviceProfiles[service.uuid] {
            self.profile = serviceProfile.characteristicProfiles[cbCharacteristic.UUID]
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
