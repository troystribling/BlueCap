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
        let stringUUIDs = services.reduce([String]()){(stringUUIDs, service) in
            if let stringUUID = service.UUIDString {
                return stringUUIDs + [stringUUID]
            } else {
                return stringUUIDs
            }
        }
        userDefaults.setObject(stringUUIDs, forKey:"scannedServices")
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
    class func getScanRegions() -> [String:CLLocationCoordinate2D] {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        if let storedRegions = userDefaults.dictionaryForKey("scannedRegions") {
            var regions = [String:CLLocationCoordinate2D]()
            for (name, location) in storedRegions {
                if let name = name as? String {
                    if location.count == 2 {
                        let lat = location[0] as NSNumber
                        let lon = location[1] as NSNumber
                        regions[name] = CLLocationCoordinate2D(latitude:lat.doubleValue, longitude:lon.doubleValue)
                    }
                }
            }
            return regions
        } else {
            return [:]
        }
    }
    
    class func getScanRegionNames() -> [String] {
        return self.getScanRegions().keys.array
    }
    
    class func getScanRegion(name:String) -> CLLocationCoordinate2D? {
        let regions = self.getScanRegions()
        return regions[name]
    }
    
    class func setScanRegions(regions:[String:CLLocationCoordinate2D]) {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        var storeRegions = [String:[NSNumber]]()
        for (name, location) in regions {
            storeRegions[name] = [NSNumber(double:location.latitude), NSNumber(double:location.longitude)]
        }
        userDefaults.setObject(storeRegions, forKey:"scannedRegions")
    }
    
    class func addScanRegion(name:String, region:CLLocationCoordinate2D) {
        var regions = self.getScanRegions()
        regions[name] = region
        self.setScanRegions(regions)
    }

    class func removeScanRegion(name:String) {
        var regions = self.getScanRegions()
        regions.removeValueForKey(name)
        self.setScanRegions(regions)
    }
}