//
//  BLESIGGATTProfiles.swift
//  BlueCap
//
//  Created by Troy Stribling on 7/25/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation
import CoreBluetooth
import BlueCapKit

struct BLESIGGATT {
    
    //***************************************************************************************************
    // Key Pressed Service
    //***************************************************************************************************
    struct KeyPressedService {
        static let uuid = "ffe0"
        static let name = "BLE SIG GATT Key Pressed Service"
    }
    
}

class BLESIGGATTProfiles {
    
    class func create () {
        
        let profileManage = ProfileManager.sharedInstance()

    }
}