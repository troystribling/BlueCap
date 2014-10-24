//
//  ConfigStore.swift
//  BlueCap
//
//  Created by Troy Stribling on 8/29/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation
import BlueCapKit
import CoreBluetooth
import CoreLocation

class ConfigStore {
  
    // scan mode
    class func getScanMode() -> String {
        if let scanMode = NSUserDefaults.standardUserDefaults().stringForKey("scanMode") {
            return scanMode
        } else {
            return "Promiscuous"
        }
    }
    
    class func setScanMode(scanMode:String) {
        NSUserDefaults.standardUserDefaults().setObject(scanMode, forKey:"scanMode")
    }
    
    // region scan enabled
    class func getRegionScanEnabled() -> Bool {
        return NSUserDefaults.standardUserDefaults().boolForKey("regionScanEnabled")
    }
    
    class func setRegionScanEnabled(regionScanEnabled:Bool) {
        NSUserDefaults.standardUserDefaults().setBool(regionScanEnabled, forKey:"regionScanEnabled")
    }

    // scan timeout
    class func getScanTimeoutEnabled() -> Bool {
        return NSUserDefaults.standardUserDefaults().boolForKey("scanTimeoutEnabled")
    }
    
    class func setScanTimeoutEnabled(timeoutEnabled:Bool) {
        NSUserDefaults.standardUserDefaults().setBool(timeoutEnabled, forKey:"scanTimeoutEnabled")
    }
    
    class func getScanTimeout() -> Int {
        let timeout = NSUserDefaults.standardUserDefaults().integerForKey("scanTimeout")
        if timeout == 0 {
            return 10
        } else {
            return timeout
        }
    }
    
    class func setScanTimeout(timeout:Int) {
        NSUserDefaults.standardUserDefaults().setInteger(timeout, forKey:"scanTimeout")
    }
    
    // peripheral connection timeout
    class func getPeripheralConnectionTimeout() -> Int {
        let peripheralConnectionTimeout = NSUserDefaults.standardUserDefaults().integerForKey("peripheralConnectionTimeout")
        if peripheralConnectionTimeout == 0 {
            return 10
        } else {
            return peripheralConnectionTimeout
        }
    }
    
    class func setPeripheralConnectionTimeout(peripheralConnectionTimeout:Int) {
        NSUserDefaults.standardUserDefaults().setInteger(peripheralConnectionTimeout, forKey:"peripheralConnectionTimeout")
    }

    // characteristic read write timeout
    class func getCharacteristicReadWriteTimeout() -> Int {
        let characteristicReadWriteTimeout = NSUserDefaults.standardUserDefaults().integerForKey("characteristicReadWriteTimeout")
        if characteristicReadWriteTimeout == 0 {
            return 10
        } else {
            return characteristicReadWriteTimeout
        }
    }
    
    class func setCharacteristicReadWriteTimeout(characteristicReadWriteTimeout:Int) {
        NSUserDefaults.standardUserDefaults().setInteger(characteristicReadWriteTimeout, forKey:"characteristicReadWriteTimeout")
    }

    // maximum reconnections
    class func getMaximumReconnections() -> Int {
        let maximumReconnetions = NSUserDefaults.standardUserDefaults().integerForKey("maximumReconnections")
        if maximumReconnetions == 0 {
            return 5
        } else {
            return maximumReconnetions
        }
    }
    
    class func setMaximumReconnections(maximumReconnetions:Int) {
        NSUserDefaults.standardUserDefaults().setInteger(maximumReconnetions, forKey:"maximumReconnections")
    }
    
    // scanned services
    class func getScannedServices() -> [String:CBUUID] {
        if let storedServices = NSUserDefaults.standardUserDefaults().dictionaryForKey("services") {
            var services = [String:CBUUID]()
            for (name, uuid) in storedServices {
                if let name = name as? String {
                    if let uuid = uuid as? String {
                        services[name] = CBUUID(string: uuid)
                    }
                }
            }
            return services
        } else {
            return [:]
        }
    }
    
    class func getScannedServiceNames() -> [String] {
        return self.getScannedServices().keys.array
    }
    
    class func getScannedServiceUUIDs() -> [CBUUID] {
        return self.getScannedServices().values.array
    }
    
    class func getScannedServiceUUID(name:String) -> CBUUID? {
        let services = self.getScannedServices()
        if let uuid = services[name] {
            return uuid
        } else {
            return nil
        }
    }
    
    class func setScannedServices(services:[String:CBUUID]) {
        var storedServices = [String:String]()
        for (name, uuid) in services {
            storedServices[name] = uuid.UUIDString
        }
        NSUserDefaults.standardUserDefaults().setObject(storedServices, forKey:"services")
    }
    
    class func addScannedService(name:String, uuid:CBUUID) {
        var services = self.getScannedServices()
        services[name] = uuid
        self.setScannedServices(services)
    }
    
    class func removeScannedService(name:String) {
        var beacons = self.getScannedServices()
        beacons.removeValueForKey(name)
        self.setScannedServices(beacons)
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