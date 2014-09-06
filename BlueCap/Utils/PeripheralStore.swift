//
//  PeripheralStore.swift
//  BlueCap
//
//  Created by Troy Stribling on 8/10/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import UIKit
import BlueCapKit
import CoreBluetooth

class PeripheralStore {
    
    class func getPeripherals() -> [String:[CBUUID]] {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        if let storedPeripherals = userDefaults.dictionaryForKey("peripherals") {
            var peripherals = Dictionary<String,[CBUUID]>()
            for (name, services) in storedPeripherals {
                if let name = name as? String {
                    if let services = services as? [String] {
                        let uuids = services.reduce([CBUUID]()){(uuids, uuidString) in
                            if let uuid = CBUUID.UUIDWithString(uuidString) {
                                return uuids + [uuid]
                            } else {
                                return uuids
                            }
                        }
                    }
                }
            }
            return peripherals
        } else {
            return [:]
        }
    }

    class func setPeripherals(peripherals:[String:[CBUUID]]) {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        var storedPeripherals = Dictionary<String, [String]>()
        for (name, uuids) in peripherals {
            let storedUUIDs = uuids.reduce([String]()) {(storedUUIDs, uuid) in
                if let storedUUID = uuid.UUIDString {
                    return storedUUIDs + [storedUUID]
                } else {
                    return storedUUIDs
                }
            }
        }
        userDefaults.setObject(storedPeripherals, forKey:"peripherals")
    }
    
    class func removePeripheral(name:String) {
        var peripherals = self.getPeripherals()
        peripherals.removeValueForKey(name)
        self.setPeripherals(peripherals)
    }
    
    class func addPeripheral(name:String) {
        var peripherals = self.getPeripherals()
        peripherals[name] = [CBUUID]()
        self.setPeripherals(peripherals)
    }
    
    class func getPeripheralNames() -> [String] {
        return Array(self.getPeripherals().keys)
    }

    class func getPeripheralServices(peripheral:String) -> [CBUUID] {
        let peripherals = self.getPeripherals()
        if let services = peripherals[peripheral] {
            return services
        } else {
            return []
        }
    }
    
    class func setPeripheralServices(name:String, services:[CBUUID]) {
        var peripherals = self.getPeripherals()
        peripherals[name] = services
        self.setPeripherals(peripherals)
    }

    class func addPeripheralService(name:String, service:CBUUID) {
        var peripherals = self.getPeripherals()
        if let services = peripherals[name] {
            peripherals[name] = services + [service]
        }
        self.setPeripherals(peripherals)
    }
    
    class func removePeripheralService(name:String, service:CBUUID) {
        var peripherals = self.getPeripherals()
        if let services = peripherals[name] {
            peripherals[name] = services.filter{$0 != service}
        }
        self.setPeripherals(peripherals)
    }
    
}
