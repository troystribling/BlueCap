//
//  ConfigStore.swift
//  BlueCap
//
//  Created by Troy Stribling on 8/29/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import UIKit
import BlueCapKit

class ConfigStore {
  
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
    
    class func getRegionScanEnabled() -> Bool {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        return userDefaults.boolForKey("regionScanEnabled")
    }
    
    class func setRegionScanEnabled(regionScanEnabled:Bool) {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        userDefaults.setBool(regionScanEnabled, forKey:"regionScanEnabled")
    }

    class func getScannedServices() -> [String] {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        if let services = userDefaults.stringArrayForKey("scannedServices") {
            return services.map{$0 as String}
        } else {
            return []
        }
    }
    
    class func setScannedServices(services:[String]) {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        userDefaults.setObject(services, forKey:"scannedServices")
        userDefaults.synchronize()
    }
    

}