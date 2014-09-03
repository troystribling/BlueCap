//
//  ConfigStore.swift
//  BlueCap
//
//  Created by Troy Stribling on 8/29/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import UIKit
import BlueCapKit
import CoreBluetooth
import CoreLocation

class ConfigStore {
  
    // scan mode
    class func getScanMode() -> String {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        if let scanMode = userDefaults.stringForKey("scanMode") {
            return scanMode
        } else {
            return "Promiscuous"
        }
    }
    
    class func setScanMode(scanMode:String) {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        userDefaults.setObject(scanMode, forKey:"scanMode")
    }
    
    // region scan enabled
    class func getRegionScanEnabled() -> Bool {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        return userDefaults.boolForKey("regionScanEnabled")
    }
    
    class func setRegionScanEnabled(regionScanEnabled:Bool) {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        userDefaults.setBool(regionScanEnabled, forKey:"regionScanEnabled")
    }

    // scanned services
    class func getScannedServices() -> [CBUUID] {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        if let services = userDefaults.stringArrayForKey("scannedServices") {
            return services.reduce(Array<CBUUID>()) {(uuids, uuid) in
                if let uuid = uuid as? String {
                    if let uuid = CBUUID.UUIDWithString(uuid) {
                        return uuids + [uuid]
                    } else {
                        return uuids
                    }
                } else {
                    return uuids
                }
            }
        } else {
            return []
        }
    }
    
    class func setScannedServices(services:[CBUUID]) {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        let stringUUIDs = services.reduce([String]()){(strings, service) in
            if let stringUUID = service.UUIDString {
                return strings + [stringUUID]
            } else {
                return strings
            }
        }
        userDefaults.setObject(stringUUIDs, forKey:"scannedServices")
        userDefaults.synchronize()
    }
    
    class func addScannedService(service:CBUUID) {
        let services = self.getScannedServices()
        self.setScannedServices(services + [service])
    }
    
    class func removeScannedService(service:CBUUID) {
        let services = self.getScannedServices()
        self.setScannedServices(services.filter{$0 != service})
    }
    
    // scan regions
//    class func getScanRegions() -> [CLLocationCoordinate2D] {
//        let userDefaults = NSUserDefaults.standardUserDefaults()
//        if let regions = userDefaults.arrayForKey("regions") {
//            return regions.reduce([CLLocationCoordinate2D]()) {(locations, location) in
//                if let region = location as? CLLocationCoordinate2D {
//                   return locations + [region]
//                } else {
//                    return locations
//                }
//            }
//        } else {
//            return []
//        }
//    }
//    
//    class func setScanRegions(regions:[CLLocationCoordinate2D]) {
//        let userDefaults = NSUserDefaults.standardUserDefaults()
//        
//        userDefaults.setObject(regions, forKey:"regions")
//    }
//    
//    class func addScanRegion(region:CLLocationCoordinate2D) {
//        let regions = self.getScanRegions()
//        self.setScanRegions(regions + [region])
//    }
//    
//    class func removeScanRegion(region:CLLocationCoordinate2D) {
//        let regions = self.getScanRegions()
//        self.setScanRegions(regions.filter{$0 != region})
//    }
}