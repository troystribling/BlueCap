//
//  PeripheralsStore.swift
//  BlueCap
//
//  Created by Troy Stribling on 8/10/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import UIKit
import CoreBluetooth

class PeripheralsStore {
    
    class func getPeripherals() -> [String] {
        if let userDefaults = NSUserDefaults.standardUserDefaults() {
            if let peripherals = userDefaults.stringArrayForKey("peripherals") {
                return peripherals.map{$0 as String}
            } else {
                return []
            }
        } else {
            return []
        }
    }
    
    class func getPeripheralServices(peripheral:String) -> [CBUUID!] {
        if let userDefaults = NSUserDefaults.standardUserDefaults() {
            if let services = userDefaults.stringArrayForKey(peripheral) {
                return services.map{CBUUID.UUIDWithString($0 as String)}
            } else {
                return []
            }
        } else {
            return []
        }
    }
    
    class func addPeripheral(peripheral:String, services:[String]) {
        if let userDefaults = NSUserDefaults.standardUserDefaults() {
            
        }
    }
    
    class func removePeripheral(peripheral:String) {
        if let userDefaults = NSUserDefaults.standardUserDefaults() {
            userDefaults.removeObjectForKey(peripheral)
            
        }
    }

}
