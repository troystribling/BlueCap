//
//  BeaconStore.swift
//  BlueCap
//
//  Created by Troy Stribling on 9/16/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import Foundation
import BlueCapKit

class BeaconStore {
    
    class func getBeacons() -> [String: NSUUID] {
        if let storedBeacons = NSUserDefaults.standardUserDefaults().dictionaryForKey("beacons") {
            var beacons = [String: NSUUID]()
            for (name, uuid) in storedBeacons {
                if let uuid = uuid as? String {
                    beacons[name] = NSUUID(UUIDString: uuid)
                }
            }
            return beacons
        } else {
            return [:]
        }
    }
    
    class func setBeacons(beacons: [String: NSUUID]) {
        var storedBeacons = [String: String]()
        for (name, uuid) in beacons {
            storedBeacons[name] = uuid.UUIDString
        }
        NSUserDefaults.standardUserDefaults().setObject(storedBeacons, forKey: "beacons")
    }

    class func getBeaconNames() -> [String] {
        return Array(self.getBeacons().keys)
    }
    
    class func addBeacon(name: String, uuid: NSUUID) {
        var beacons = self.getBeacons()
        beacons[name] = uuid
        self.setBeacons(beacons)
    }
    
    class func removeBeacon(name: String) {
        var beacons = self.getBeacons()
        beacons.removeValueForKey(name)
        self.setBeacons(beacons)
    }
}