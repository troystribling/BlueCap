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
    
    var discoveredDescriptors       = Dictionary<CBUUID, Descriptor>()
    var descriptorsDiscovered       : ((descriptors:Descriptor[]!) -> ())?

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
    

    var descriptors : Descriptor[] {
        return Array(self.discoveredDescriptors.values)
    }
    
    init(cbCharacteristic:CBCharacteristic, service:Service) {
        self.cbCharacteristic = cbCharacteristic
        self.service = service
        let serviceProfile = ProfileManager.sharedInstance().serviceProfiles[service.uuid]
        if serviceProfile {
            self.profile = serviceProfile!.characteristicProfiles[cbCharacteristic.UUID]
        }
    }
    
}
