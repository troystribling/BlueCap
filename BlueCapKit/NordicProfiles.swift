//
//  NordicProfiles.swift
//  BlueCap
//
//  Created by Troy Stribling on 7/25/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation
import CoreBluetooth
import BlueCapKit

struct Nordic {
    
    //***************************************************************************************************
    // Nordic Device Temperature Service
    //***************************************************************************************************
    struct DeviceTemperature {
        static let uuid = "2f0a0003-69aa-f316-3e78-4194989a6c1a"
        static let name = "Noric Device Temperature"
        struct Data {
            static let uuid = "2f0a0004-69aa-f316-3e78-4194989a6c1a"
            static let name = "Device Temperature Data"
        }
    }

    //***************************************************************************************************
    // Nordic BLE Address Service
    //***************************************************************************************************
    struct BLEAddress {
        static let uuid = "2f0a0005-69aa-f316-3e78-4194989a6c1a"
        static let name = "Noric BLE Address"
        struct Address {
            static let uuid = "2f0a0006-69aa-f316-3e78-4194989a6c1a"
            static let name = "BLE Addresss"
        }
        struct Type {
            static let uuid = "2f0a0007-69aa-f316-3e78-4194989a6c1a"
            static let name = "BLE Address Type"
        }
    }
    
}

class NordicProfiles {
    
    class func create() {
        
        let profileManager = ProfileManager.sharedInstance()
        
        //***************************************************************************************************
        // Nordic Device Temperature Service
        //***************************************************************************************************
        profileManager.addService(ServiceProfile(uuid:Nordic.DeviceTemperature.uuid, name:Nordic.DeviceTemperature.name){(serviceProfile:ServiceProfile) in
        })

        //***************************************************************************************************
        // Nordic BLE Address Service
        //***************************************************************************************************
        profileManager.addService(ServiceProfile(uuid:Nordic.BLEAddress.uuid, name:Nordic.BLEAddress.name){(serviceProfile:ServiceProfile) in
        })

    }
}
