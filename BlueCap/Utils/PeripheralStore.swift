//
//  PeripheralStore.swift
//  BlueCap
//
//  Created by Troy Stribling on 8/10/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation
import BlueCapKit
import CoreBluetooth

class PeripheralStore {
    
    // peripherl services
    class func getPeripheralServices() -> [String:[CBUUID]] {
        if let storedPeripherals = NSUserDefaults.standardUserDefaults().dictionaryForKey("peripheralServices") {
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
                        peripherals[name] = uuids
                    }
                }
            }
            Logger.debug("getPeripheralServices peripheralServices: \(peripherals)")
            return peripherals
        } else {
            return [:]
        }
    }

    class func setPeripheralServices(peripheralServices:[String:[CBUUID]]) {
        Logger.debug("setPeripheralServices peripheralServices: \(peripheralServices)")
        var storedPeripherals = Dictionary<String, [String]>()
        for (name, uuids) in peripheralServices {
            storedPeripherals[name] = uuids.reduce([String]()) {(storedUUIDs, uuid) in
                if let storedUUID = uuid.UUIDString {
                    return storedUUIDs + [storedUUID]
                } else {
                    return storedUUIDs
                }
            }
        }
        let userDefaults = NSUserDefaults.standardUserDefaults()
        userDefaults.setObject(storedPeripherals, forKey:"peripheralServices")
    }
    
    class func addPeripheralServices(name:String, services:[CBUUID]) {
        var peripherals = self.getPeripheralServices()
        peripherals[name] = services
        self.setPeripheralServices(peripherals)
    }
    
    class func addPeripheralService(name:String, service:CBUUID) {
        var peripheralServices = self.getPeripheralServices()
        if let services = peripheralServices[name] {
            peripheralServices[name] = services + [service]
        } else {
            peripheralServices[name] = [service]
        }
        self.setPeripheralServices(peripheralServices)
    }
    
    class func removePeripheralService(name:String, service:CBUUID) {
        var peripherals = self.getPeripheralServices()
        if let services = peripherals[name] {
            peripherals[name] = services.filter{$0 != service}
        }
        self.setPeripheralServices(peripherals)
    }
    
    class func removePeripheralServices(name:String) {
        var peripheralServices = self.getPeripheralServices()
        peripheralServices.removeValueForKey(name)
        self.setPeripheralServices(peripheralServices)
    }

    class func getPeripheralServices(peripheral:String) -> [CBUUID] {
        let peripheralServices = self.getPeripheralServices()
        if let services = peripheralServices[peripheral] {
            return services
        } else {
            return []
        }
    }
    
    // periphear names
    class func getPeripheralNames() -> [String] {
        if let peripheral = NSUserDefaults.standardUserDefaults().arrayForKey("peripheralNames") {
            return peripheral.map{$0 as String}
        } else {
            return []
        }
    }

    class func setPeripheralNames(names:[String]) {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        userDefaults.setObject(names, forKey:"peripheralNames")
    }
    
    class func addPeripheralName(name:String) {
        var names = self.getPeripheralNames()
        self.setPeripheralNames(names + [name])
    }
    
    class func removePeripheralName(name:String) {
        var names = self.getPeripheralNames()
        self.setPeripheralNames(names.filter{$0 != name})
    }
    
    // peripheral
    class func removePeripheral(name:String) {
        self.removePeripheralServices(name)
        self.removePeripheralName(name)
    }
    
}
