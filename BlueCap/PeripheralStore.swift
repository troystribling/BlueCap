//
//  PeripheralStore.swift
//  BlueCap
//
//  Created by Troy Stribling on 8/10/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import UIKit
import CoreBluetooth
import BlueCapKit

class PeripheralStore {
    
    class func getPeripherals() -> [String] {
        if let userDefaults = NSUserDefaults.standardUserDefaults() {
            if let peripherals = userDefaults.stringArrayForKey("peripherals") {
                Logger.debug("PeripheralStore#getPeripherals: \(peripherals)")
                return peripherals.map{$0 as String}
            } else {
                return []
            }
        } else {
            return []
        }
    }
    
    class func getPeripheralServices(peripheral:String) -> [String] {
        if let userDefaults = NSUserDefaults.standardUserDefaults() {
            if let services = userDefaults.stringArrayForKey(peripheral) {
                Logger.debug("PeripheralStore#getPeripheralServices: \(peripheral), \(services)")
                return services.map{$0 as String}
            } else {
                return []
            }
        } else {
            return []
        }
    }
    
    class func addPeripheral(peripheral:String) {
        if let userDefaults = NSUserDefaults.standardUserDefaults() {
            var peripherals = self.getPeripherals()
            Logger.debug("PeripheralStore#addPeripheral: \(peripheral)")
            userDefaults.setObject(peripherals + [peripheral], forKey:"peripherals")
        }
    }

    class func addPeripheralServices(peripheral:String, services:[String]) {
        if let userDefaults = NSUserDefaults.standardUserDefaults() {
            Logger.debug("PeripheralStore#addPeripheralServices: \(peripheral), \(services)")
            userDefaults.setObject(services, forKey:peripheral)
        }
    }

    class func removePeripheral(peripheral:String) {
        if let userDefaults = NSUserDefaults.standardUserDefaults() {
            Logger.debug("PeripheralStore#removePeripheral: \(peripheral)")
            userDefaults.removeObjectForKey(peripheral)
            var peripherals = self.getPeripherals()
            userDefaults.setObject(peripherals.filter{$0 != peripheral}, forKey:"peripherals")
        }
    }

}
