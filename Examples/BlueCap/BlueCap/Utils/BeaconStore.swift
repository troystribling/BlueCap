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
    
    class func getBeacons() -> [String: UUID] {
        if let storedBeacons = UserDefaults.standard.dictionary(forKey: "beacons") {
            var beacons = [String: UUID]()
            for (name, uuid) in storedBeacons {
                if let uuid = uuid as? String {
                    beacons[name] = UUID(uuidString: uuid)
                }
            }
            return beacons
        } else {
            return [:]
        }
    }
    
    class func setBeacons(_ beacons: [String: UUID]) {
        var storedBeacons = [String: String]()
        for (name, uuid) in beacons {
            storedBeacons[name] = uuid.uuidString
        }
        UserDefaults.standard.set(storedBeacons, forKey: "beacons")
    }

    class func getBeaconNames() -> [String] {
        return Array(self.getBeacons().keys)
    }
    
    class func addBeacon(_ name: String, uuid: UUID) {
        var beacons = self.getBeacons()
        beacons[name] = uuid
        self.setBeacons(beacons)
    }
    
    class func removeBeacon(_ name: String) {
        var beacons = self.getBeacons()
        beacons.removeValue(forKey: name)
        self.setBeacons(beacons)
    }
}
