//
//  BeaconStore.swift
//  Beacon
//
//  Created by Troy Stribling on 4/13/15.
//  Copyright (c) 2015 gnos.us. All rights reserved.
//

import UIKit

//
//  PeripheralStore.swift
//  BlueCap
//
//  Created by Troy Stribling on 8/10/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
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
    
    class func setBeacon(uuid:NSUUID) {
        NSUserDefaults.standardUserDefaults().setObject(uuid.UUIDString, forKey:"beaconUUID")
    }

    class func getBeaconName() -> String {
        return NSUserDefaults.standardUserDefaults().stringForKey("beaconName")
    }

    class func setBeaconName(name:String) {
        NSUserDefaults.standardUserDefaults().setObject(name, forKey:"beaconName")
    }
        

    class func addBeacon(name:String, uuid:NSUUID) {
        var beacons = self.getBeacons()
        beacons[name] = uuid
        self.setBeacons(beacons)
    }
    
    class func removeBeacon(name:String) {
        var beacons = self.getBeacons()
        beacons.removeValueForKey(name)
        self.setBeacons(beacons)
    }
    
    class func getBeacon(name:String) -> NSUUID? {
        let beacons = self.getBeacons()
        return beacons[name]
    }
    
    class func getBeaconConfigs() -> [String:[UInt16]] {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        if let storedConfigs = userDefaults.dictionaryForKey("beaconConfig") {
            var configs = [String:[UInt16]]()
            for (name, config) in storedConfigs {
                if let name = name as? String {
                    if config.count == 2 {
                        let minor = config[0] as! NSNumber
                        let major = config[1] as! NSNumber
                        configs[name] = [minor.unsignedShortValue, major.unsignedShortValue]
                    }
                }
            }
            return configs
        } else {
            return [:]
        }
    }
    
    class func setBeaconConfigs(configs:[String:[UInt16]]) {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        var storeConfigs = [String:[NSNumber]]()
        for (name, config) in configs {
            storeConfigs[name] = [NSNumber(unsignedShort:config[0]), NSNumber(unsignedShort:config[1])]
        }
        userDefaults.setObject(storeConfigs, forKey:"beaconConfig")
    }
    

}
