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

    class func getPeripheralServices(_ key: String) -> [String: [CBUUID]] {
        if let storedPeripherals = UserDefaults.standard.dictionary(forKey: key) {
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

    class func setPeripheralServices(_ key: String, peripheralServices: [String : [CBUUID]]) {
        var storedPeripherals = [String : [String]]()
        for (name, uuids) in peripheralServices {
            storedPeripherals[name] = uuids.reduce([String]()) {(storedUUIDs, uuid) in
                return storedUUIDs + [uuid.uuidString]
            }
        }
        let userDefaults = UserDefaults.standard
        userDefaults.set(storedPeripherals, forKey:key)
    }
    
    // MARK: Peripheral Supported Services

    class func addPeripheralServices(_ name: String, services: [CBUUID]) {
        var peripherals = self.getPeripheralServices("peripheralServices")
        peripherals[name] = services
        self.setPeripheralServices("peripheralServices", peripheralServices:peripherals)
    }
    
    class func addPeripheralService(_ name: String, service: CBUUID) {
        var peripheralServices = self.getPeripheralServices("peripheralServices")
        if let services = peripheralServices[name] {
            peripheralServices[name] = services + [service]
        } else {
            peripheralServices[name] = [service]
        }
        self.setPeripheralServices("peripheralServices", peripheralServices:peripheralServices)
    }
    
    class func removePeripheralService(_ name: String, service: CBUUID) {
        var peripherals = self.getPeripheralServices("peripheralServices")
        if let services = peripherals[name] {
            peripherals[name] = services.filter{$0 != service}
        }
        self.setPeripheralServices("peripheralServices", peripheralServices:peripherals)
    }
    
    class func removePeripheralServices(_ name: String) {
        var peripheralServices = self.getPeripheralServices("peripheralServices")
        peripheralServices.removeValue(forKey: name)
        self.setPeripheralServices("peripheralServices", peripheralServices:peripheralServices)
    }

    class func getPeripheralServicesForPeripheral(_ peripheral: String) -> [CBUUID] {
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
    
    class func addAdvertisedPeripheralServices(_ name: String, services: [CBUUID]) {
        var peripherals = self.getPeripheralServices("advertisedPeripheralServices")
        peripherals[name] = services
        self.setPeripheralServices("advertisedPeripheralServices", peripheralServices:peripherals)
    }
    
    class func addAdvertisedPeripheralService(_ name: String, service: CBUUID) {
        var peripheralServices = self.getPeripheralServices("advertisedPeripheralServices")
        if let services = peripheralServices[name] {
            peripheralServices[name] = services + [service]
        } else {
            peripheralServices[name] = [service]
        }
        self.setPeripheralServices("advertisedPeripheralServices", peripheralServices:peripheralServices)
    }
    
    class func removeAdvertisedPeripheralService(_ name: String, service: CBUUID) {
        Logger.debug("service \(name), \(service)")
        var peripherals = self.getPeripheralServices("advertisedPeripheralServices")
        Logger.debug("peripherals \(peripherals)")
        if let services = peripherals[name] {
            Logger.debug("services \(services)")
            peripherals[name] = services.filter{$0 != service}
            Logger.debug("services \(services)")
        }
        Logger.debug("peripherals \(peripherals)")
        self.setPeripheralServices("advertisedPeripheralServices", peripheralServices:peripherals)
    }
    
    class func removeAdvertisedPeripheralServices(_ name: String) {
        var peripheralServices = self.getPeripheralServices("advertisedPeripheralServices")
        peripheralServices.removeValue(forKey: name)
        self.setPeripheralServices("advertisedPeripheralServices", peripheralServices:peripheralServices)
    }

    class func getAdvertisedPeripheralServicesForPeripheral(_ peripheral: String) -> [CBUUID] {
        var peripheralServices = self.getPeripheralServices("advertisedPeripheralServices")
        if let services = peripheralServices[peripheral] {
            return services
        } else {
            return []
        }
    }

    // MARK: Periphearl Names

    class func getPeripheralNames() -> [String] {
        if let peripheral = UserDefaults.standard.array(forKey: "peripheralNames") {
            return peripheral.map{$0 as! String}
        } else {
            return []
        }
    }

    class func setPeripheralNames(_ names: [String]) {
        let userDefaults = UserDefaults.standard
        userDefaults.set(names, forKey:"peripheralNames")
    }
    
    class func addPeripheralName(_ name: String) {
        let names = self.getPeripheralNames()
        self.setPeripheralNames(names + [name])
    }
    
    class func removePeripheralName(_ name: String) {
        let names = self.getPeripheralNames()
        self.setPeripheralNames(names.filter{$0 != name})
    }
    
    // MARK: Peripheral

    class func removePeripheral(_ name:String) {
        self.removePeripheralServices(name)
        self.removePeripheralName(name)
        self.removeAdvertisedPeripheralServices(name)
        self.removeAdvertisedBeacon(name)
        self.removeBeaconEnabled(name)
    }
    
    // MSARK: iBeacon

    class func getAdvertisedBeacons() -> [String: String] {
        var beacons: [String: String] = [:]
        if let storedBeacons = UserDefaults.standard.dictionary(forKey: "peripheralAdvertisedBeaconConfigs") {
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
    
    class func setAdvertisedBeacons(_ beacons: [String:String]) {
        UserDefaults.standard.set(beacons, forKey: "peripheralAdvertisedBeaconConfigs")
    }
    
    class func getAdvertisedBeacon(_ peripheral: String) -> String? {
        let beacons = self.getAdvertisedBeacons()
        return beacons[peripheral]
    }
    
    class func setAdvertisedBeacon(_ peripheral: String, beacon: String) {
        var beacons = getAdvertisedBeacons()
        beacons[peripheral] = beacon
        self.setAdvertisedBeacons(beacons)
    }
    
    class func removeAdvertisedBeacon(_ peripheral: String) {
        var beacons = getAdvertisedBeacons()
        beacons.removeValue(forKey: peripheral)
        self.setAdvertisedBeacons(beacons)
    }
    
    // MARK: iBeacon Enabled

    class func getBeaconsEnabled() -> [String: Bool] {
        var beacons = [String: Bool]()
        if let storedBeacons = UserDefaults.standard.dictionary(forKey: "peipheralBeaconsEnabled") {
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
    
    class func setBeaconsEnabled(_ beacons: [String: Bool]) {
        var storedBeacons = [String: NSNumber]()
        for (periheral, enabled) in beacons {
            storedBeacons[periheral] = NSNumber(value: enabled as Bool)
        }
        UserDefaults.standard.set(storedBeacons, forKey:"peipheralBeaconsEnabled")
    }
    
    class func getBeaconEnabled(_ peripheral: String) -> Bool {
        let beacons = self.getBeaconsEnabled()
        if let enabled = beacons[peripheral] {
            return (enabled as NSNumber).boolValue
        } else {
            return false
        }
    }

    class func setBeaconEnabled(_ peripheral: String, enabled: Bool) {
        var beacons = self.getBeaconsEnabled()
        beacons[peripheral] = enabled
        self.setBeaconsEnabled(beacons)
    }
    
    class func removeBeaconEnabled(_ peripheral: String) {
        var beacons = self.getBeaconsEnabled()
        beacons.removeValue(forKey: peripheral)
        self.setBeaconsEnabled(beacons)
    }

    // MARK: Peripheral Beacon
    
    class func getBeacons() -> [String: UUID] {
        if let storedBeacons = UserDefaults.standard.dictionary(forKey: "peripheralBeacons") {
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
    
    class func setBeacons(_ beacons: [String:UUID]) {
        var storedBeacons = [String: String]()
        for (name, uuid) in beacons {
            storedBeacons[name] = uuid.uuidString
        }
        UserDefaults.standard.set(storedBeacons, forKey: "peripheralBeacons")
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
    
    class func getBeacon(_ name: String) -> UUID? {
        let beacons = self.getBeacons()
        return beacons[name]
    }
    
    class func getBeaconConfigs() -> [String : [UInt16]] {
        let userDefaults = UserDefaults.standard
        if let storedConfigs = userDefaults.dictionary(forKey: "peipheralBeaconConfigs") {
            var configs = [String: [UInt16]]()
            for (name, storedConfig) in storedConfigs {
                if (storedConfig as AnyObject).count == 2 {
                    if let config = storedConfig as? [NSNumber] {
                        configs[name] = [config[0].uint16Value, config[1].uint16Value]
                    }
                }
            }
            return configs
        } else {
            return [:]
        }
    }
    
    class func setBeaconConfigs(_ configs: [String : [UInt16]]) {
        let userDefaults = UserDefaults.standard
        var storeConfigs = [String: [NSNumber]]()
        for (name, config) in configs {
            storeConfigs[name] = [NSNumber(value: config[0] as UInt16), NSNumber(value: config[1] as UInt16)]
        }
        userDefaults.set(storeConfigs, forKey:"peipheralBeaconConfigs")
    }
    
    class func addBeaconConfig(_ name: String, config: [UInt16]) {
        var configs = self.getBeaconConfigs()
        configs[name] = config
        self.setBeaconConfigs(configs)
    }
    
    class func getBeaconConfig(_ name: String) -> [UInt16] {
        let configs = self.getBeaconConfigs()
        if let config = configs[name] {
            return config
        } else {
            return [0,0]
        }
    }
    
    class func removeBeaconConfig(_ name: String) {
        var configs = self.getBeaconConfigs()
        configs.removeValue(forKey: name)
        self.setBeaconConfigs(configs)
    }
    

}
