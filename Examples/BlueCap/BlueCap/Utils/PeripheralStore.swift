//
//  PeripheralStore.swift
//  BlueCap
//
//  Created by Troy Stribling on 8/10/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import Foundation
import BlueCapKit
import CoreBluetooth

// MARK: - PeripheralStore -
class PeripheralStore {
    
    // MARK: Services
    class func getPeripheralServices(key: String) -> [String: [CBUUID]] {
        if let storedPeripherals = NSUserDefaults.standardUserDefaults().dictionaryForKey(key) {
            var peripherals = [String:[CBUUID]]()
            for (name, services) in storedPeripherals {
                if let services = services as? [String] {
                    let uuids = services.reduce([CBUUID]()){(uuids, uuidString) in
                        let uuid = CBUUID(string:uuidString)
                            return uuids + [uuid]
                    }
                    peripherals[name] = uuids
                }
            }
            return peripherals
        } else {
            return [:]
        }
    }

    class func setPeripheralServices(key: String, peripheralServices: [String:[CBUUID]]) {
        var storedPeripherals = [String: [String]]()
        for (name, uuids) in peripheralServices {
            storedPeripherals[name] = uuids.reduce([String]()) {(storedUUIDs, uuid) in
                return storedUUIDs + [uuid.UUIDString]
            }
        }
        let userDefaults = NSUserDefaults.standardUserDefaults()
        userDefaults.setObject(storedPeripherals, forKey:key)
    }
    
    // MARK: Peripheral Supported Services
    class func addPeripheralServices(name: String, services: [CBUUID]) {
        var peripherals = self.getPeripheralServices("peripheralServices")
        peripherals[name] = services
        self.setPeripheralServices("peripheralServices", peripheralServices:peripherals)
    }
    
    class func addPeripheralService(name: String, service: CBUUID) {
        var peripheralServices = self.getPeripheralServices("peripheralServices")
        if let services = peripheralServices[name] {
            peripheralServices[name] = services + [service]
        } else {
            peripheralServices[name] = [service]
        }
        self.setPeripheralServices("peripheralServices", peripheralServices:peripheralServices)
    }
    
    class func removePeripheralService(name: String, service: CBUUID) {
        var peripherals = self.getPeripheralServices("peripheralServices")
        if let services = peripherals[name] {
            peripherals[name] = services.filter{$0 != service}
        }
        self.setPeripheralServices("peripheralServices", peripheralServices:peripherals)
    }
    
    class func removePeripheralServices(name: String) {
        var peripheralServices = self.getPeripheralServices("peripheralServices")
        peripheralServices.removeValueForKey(name)
        self.setPeripheralServices("peripheralServices", peripheralServices:peripheralServices)
    }

    class func getPeripheralServicesForPeripheral(peripheral: String) -> [CBUUID] {
        var peripheralServices = self.getPeripheralServices("peripheralServices")
        if let services = peripheralServices[peripheral] {
            return services
        } else {
            return []
        }
    }
    
    // MARK: Advertised Peripheral Services
    class func getAdvertisedPeripheralServices() -> [String: [CBUUID]] {
        return self.getPeripheralServices("advertisedPeripheralServices")
    }
    
    class func addAdvertisedPeripheralServices(name: String, services: [CBUUID]) {
        var peripherals = self.getPeripheralServices("advertisedPeripheralServices")
        peripherals[name] = services
        self.setPeripheralServices("advertisedPeripheralServices", peripheralServices:peripherals)
    }
    
    class func addAdvertisedPeripheralService(name: String, service: CBUUID) {
        var peripheralServices = self.getPeripheralServices("advertisedPeripheralServices")
        if let services = peripheralServices[name] {
            peripheralServices[name] = services + [service]
        } else {
            peripheralServices[name] = [service]
        }
        self.setPeripheralServices("advertisedPeripheralServices", peripheralServices:peripheralServices)
    }
    
    class func removeAdvertisedPeripheralService(name: String, service: CBUUID) {
        BCLogger.debug("service \(name), \(service)")
        var peripherals = self.getPeripheralServices("advertisedPeripheralServices")
        BCLogger.debug("peripherals \(peripherals)")
        if let services = peripherals[name] {
            BCLogger.debug("services \(services)")
            peripherals[name] = services.filter{$0 != service}
            BCLogger.debug("services \(services)")
        }
        BCLogger.debug("peripherals \(peripherals)")
        self.setPeripheralServices("advertisedPeripheralServices", peripheralServices:peripherals)
    }
    
    class func removeAdvertisedPeripheralServices(name: String) {
        var peripheralServices = self.getPeripheralServices("advertisedPeripheralServices")
        peripheralServices.removeValueForKey(name)
        self.setPeripheralServices("advertisedPeripheralServices", peripheralServices:peripheralServices)
    }

    class func getAdvertisedPeripheralServicesForPeripheral(peripheral: String) -> [CBUUID] {
        var peripheralServices = self.getPeripheralServices("advertisedPeripheralServices")
        if let services = peripheralServices[peripheral] {
            return services
        } else {
            return []
        }
    }

    // MARK: Periphearl Names
    class func getPeripheralNames() -> [String] {
        if let peripheral = NSUserDefaults.standardUserDefaults().arrayForKey("peripheralNames") {
            return peripheral.map{$0 as! String}
        } else {
            return []
        }
    }

    class func setPeripheralNames(names: [String]) {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        userDefaults.setObject(names, forKey:"peripheralNames")
    }
    
    class func addPeripheralName(name: String) {
        let names = self.getPeripheralNames()
        self.setPeripheralNames(names + [name])
    }
    
    class func removePeripheralName(name: String) {
        let names = self.getPeripheralNames()
        self.setPeripheralNames(names.filter{$0 != name})
    }
    
    // MARK: Peripheral
    class func removePeripheral(name:String) {
        self.removePeripheralServices(name)
        self.removePeripheralName(name)
        self.removeAdvertisedPeripheralServices(name)
        self.removeAdvertisedBeacon(name)
        self.removeBeaconEnabled(name)
    }
    
    // MSARK: iBeacon
    class func getAdvertisedBeacons() -> [String: String] {
        var beacons: [String: String] = [:]
        if let storedBeacons = NSUserDefaults.standardUserDefaults().dictionaryForKey("peripheralAdvertisedBeaconConfigs") {
            for (peripheral, beacon) in storedBeacons {
                if let beacon = beacon as? String {
                    beacons[peripheral] = beacon
                }
            }
            return beacons
        } else {
            return [:]
        }
    }
    
    class func setAdvertisedBeacons(beacons: [String:String]) {
        NSUserDefaults.standardUserDefaults().setObject(beacons, forKey: "peripheralAdvertisedBeaconConfigs")
    }
    
    class func getAdvertisedBeacon(peripheral: String) -> String? {
        let beacons = self.getAdvertisedBeacons()
        return beacons[peripheral]
    }
    
    class func setAdvertisedBeacon(peripheral: String, beacon: String) {
        var beacons = getAdvertisedBeacons()
        beacons[peripheral] = beacon
        self.setAdvertisedBeacons(beacons)
    }
    
    class func removeAdvertisedBeacon(peripheral: String) {
        var beacons = getAdvertisedBeacons()
        beacons.removeValueForKey(peripheral)
        self.setAdvertisedBeacons(beacons)
    }
    
    // MARK: iBeacon Enabled
    class func getBeaconsEnabled() -> [String: Bool] {
        var beacons = [String: Bool]()
        if let storedBeacons = NSUserDefaults.standardUserDefaults().dictionaryForKey("peipheralBeaconsEnabled") {
            for (peripheral, enabled) in storedBeacons {
                if let enabled = enabled as? NSNumber {
                    beacons[peripheral] = enabled.boolValue
                }
            }
            return beacons
        } else {
            return [:]
        }
    }
    
    class func setBeaconsEnabled(beacons: [String: Bool]) {
        var storedBeacons = [String: NSNumber]()
        for (periheral, enabled) in beacons {
            storedBeacons[periheral] = NSNumber(bool:enabled)
        }
        NSUserDefaults.standardUserDefaults().setObject(storedBeacons, forKey:"peipheralBeaconsEnabled")
    }
    
    class func getBeaconEnabled(peripheral: String) -> Bool {
        let beacons = self.getBeaconsEnabled()
        if let enabled = beacons[peripheral] {
            return (enabled as NSNumber).boolValue
        } else {
            return false
        }
    }

    class func setBeaconEnabled(peripheral: String, enabled: Bool) {
        var beacons = self.getBeaconsEnabled()
        beacons[peripheral] = enabled
        self.setBeaconsEnabled(beacons)
    }
    
    class func removeBeaconEnabled(peripheral: String) {
        var beacons = self.getBeaconsEnabled()
        beacons.removeValueForKey(peripheral)
        self.setBeaconsEnabled(beacons)
    }

    // MARK: Peripheral Beacon
    class func getBeacons() -> [String: NSUUID] {
        if let storedBeacons = NSUserDefaults.standardUserDefaults().dictionaryForKey("peripheralBeacons") {
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
    
    class func setBeacons(beacons: [String:NSUUID]) {
        var storedBeacons = [String: String]()
        for (name, uuid) in beacons {
            storedBeacons[name] = uuid.UUIDString
        }
        NSUserDefaults.standardUserDefaults().setObject(storedBeacons, forKey: "peripheralBeacons")
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
    
    class func getBeacon(name: String) -> NSUUID? {
        let beacons = self.getBeacons()
        return beacons[name]
    }
    
    class func getBeaconConfigs() -> [String: [UInt16]] {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        if let storedConfigs = userDefaults.dictionaryForKey("peipheralBeaconConfigs") {
            var configs = [String: [UInt16]]()
            for (name, storedConfig) in storedConfigs {
                if storedConfig.count == 2 {
                    if let config = storedConfig as? [NSNumber] {
                        configs[name] = [config[0].unsignedShortValue, config[1].unsignedShortValue]
                    }
                }
            }
            return configs
        } else {
            return [:]
        }
    }
    
    class func setBeaconConfigs(configs: [String:[UInt16]]) {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        var storeConfigs = [String: [NSNumber]]()
        for (name, config) in configs {
            storeConfigs[name] = [NSNumber(unsignedShort: config[0]), NSNumber(unsignedShort: config[1])]
        }
        userDefaults.setObject(storeConfigs, forKey:"peipheralBeaconConfigs")
    }
    
    class func addBeaconConfig(name: String, config: [UInt16]) {
        var configs = self.getBeaconConfigs()
        configs[name] = config
        self.setBeaconConfigs(configs)
    }
    
    class func getBeaconConfig(name: String) -> [UInt16] {
        let configs = self.getBeaconConfigs()
        if let config = configs[name] {
            return config
        } else {
            return [0,0]
        }
    }
    
    class func removeBeaconConfig(name: String) {
        var configs = self.getBeaconConfigs()
        configs.removeValueForKey(name)
        self.setBeaconConfigs(configs)
    }
    

}
