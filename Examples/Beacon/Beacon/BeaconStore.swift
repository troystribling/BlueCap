//
//  BeaconStore.swift
//  Beacon
//
//  Created by Troy Stribling on 4/13/15.
//  Copyright (c) 2015 Troy Stribling. The MIT License (MIT).
//

import UIKit

//
//  PeripheralStore.swift
//  BlueCap
//
//  Created by Troy Stribling on 8/10/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import Foundation
import BlueCapKit
import CoreBluetooth

class BeaconStore {
    
    class func getBeaconUUID() -> NSUUID? {
        if let uuid = NSUserDefaults.standardUserDefaults().stringForKey("beaconUUID") {
            return NSUUID(UUIDString:uuid)
        } else {
            return nil
        }
    }
    
    class func setBeaconUUID(uuid:NSUUID) {
        NSUserDefaults.standardUserDefaults().setObject(uuid.UUIDString, forKey:"beaconUUID")
    }

    class func getBeaconName() -> String? {
        return NSUserDefaults.standardUserDefaults().stringForKey("beaconName")
    }

    class func setBeaconName(name:String) {
        NSUserDefaults.standardUserDefaults().setObject(name, forKey:"beaconName")
    }
        

    class func getBeaconConfig() -> [UInt16] {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        if let storedConfig = userDefaults.arrayForKey("beaconConfig") {
            var config = [UInt16]()
            if storedConfig.count == 2 {
                let minor = storedConfig[0] as! NSNumber
                let major = storedConfig[1] as! NSNumber
                config = [minor.unsignedShortValue, major.unsignedShortValue]
            }
            return config
        } else {
            return []
        }
    }
    
    class func setBeaconConfig(config:[UInt16]) {
        if config.count == 2 {
            let userDefaults = NSUserDefaults.standardUserDefaults()
            let storeConfigs = [NSNumber(unsignedShort:config[0]), NSNumber(unsignedShort:config[1])]
            userDefaults.setObject(storeConfigs, forKey:"beaconConfig")
        }
    }
    

}
