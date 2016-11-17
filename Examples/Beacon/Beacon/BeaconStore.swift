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
    
    class func getBeaconUUID() -> UUID? {
        if let uuid = UserDefaults.standard.string(forKey: "beaconUUID") {
            return UUID(uuidString:uuid)
        } else {
            return nil
        }
    }
    
    class func setBeaconUUID(_ uuid:UUID) {
        UserDefaults.standard.set(uuid.uuidString, forKey:"beaconUUID")
    }

    class func getBeaconName() -> String? {
        return UserDefaults.standard.string(forKey: "beaconName")
    }

    class func setBeaconName(_ name:String) {
        UserDefaults.standard.set(name, forKey:"beaconName")
    }
        

    class func getBeaconConfig() -> [UInt16] {
        let userDefaults = UserDefaults.standard
        if let storedConfig = userDefaults.array(forKey: "beaconConfig") {
            var config = [UInt16]()
            if storedConfig.count == 2 {
                let minor = storedConfig[0] as! NSNumber
                let major = storedConfig[1] as! NSNumber
                config = [minor.uint16Value, major.uint16Value]
            }
            return config
        } else {
            return []
        }
    }
    
    class func setBeaconConfig(_ config:[UInt16]) {
        if config.count == 2 {
            let userDefaults = UserDefaults.standard
            let storeConfigs = [NSNumber(value: config[0] as UInt16), NSNumber(value: config[1] as UInt16)]
            userDefaults.set(storeConfigs, forKey:"beaconConfig")
        }
    }
    

}
