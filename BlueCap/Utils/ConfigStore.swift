//
//  ConfigStore.swift
//  BlueCap
//
//  Created by Troy Stribling on 8/29/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import Foundation
import BlueCapKit
import CoreBluetooth
import CoreLocation

// MARK: Scan Mode
enum ScanMode: Int {
    case Promiscuous = 0
    case Service = 1

    init?(_ stringValue: String) {
        switch stringValue {
        case "Promiscuous":
            self = .Promiscuous
        case "Service":
            self = .Service
        default:
            return nil
        }
    }

    init?(_ rawValue: Int) {
        switch rawValue {
        case 0:
            self = .Promiscuous
        case 1:
            self = .Service
        default:
            return nil
        }
    }

    var stringValue: String {
        switch self {
        case .Promiscuous:
            return "Promiscuous"
        case .Service:
            return "Service"
        }
    }
}

// MARK: Sort Order
enum SortOrder: Int {
    case DiscoveryDate = 0
    case RSSI = 1

    init?(_ stringValue: String) {
        switch stringValue {
        case "Discovery Date":
            self = .DiscoveryDate
        case "RSSI":
            self = .RSSI
        default:
            return nil
        }
    }

    init?(_ rawValue: Int) {
        switch rawValue {
        case 0:
            self = .DiscoveryDate
        case 1:
            self = .RSSI
        default:
            return nil
        }
    }

    var stringValue: String {
        switch self {
        case .DiscoveryDate:
            return "Discovery Date"
        case .RSSI:
            return "RSSI"
        }
    }
}

// MARK: - ConfigStore -
class ConfigStore {
  
    // MARK: scan mode
    class func getScanMode() -> ScanMode {
        let rawValue = NSUserDefaults.standardUserDefaults().integerForKey("scanMode")
        if let scanMode = ScanMode(rawValue) {
            return scanMode
        } else {
            return .Promiscuous
        }
    }
    
    class func setScanMode(scanMode: ScanMode) {
        NSUserDefaults.standardUserDefaults().setInteger(scanMode.rawValue, forKey:"scanMode")
    }
    
    // MARK: scan timeout
    class func getScanTimeoutEnabled() -> Bool {
        return NSUserDefaults.standardUserDefaults().boolForKey("scanTimeoutEnabled")
    }
    
    class func setScanTimeoutEnabled(timeoutEnabled: Bool) {
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
    
    class func setScanTimeout(timeout: Int) {
        NSUserDefaults.standardUserDefaults().setInteger(timeout, forKey:"scanTimeout")
    }
    
    // MARK: peripheral connection timeout
    class func getPeripheralConnectionTimeout() -> Int {
        let peripheralConnectionTimeout = NSUserDefaults.standardUserDefaults().integerForKey("peripheralConnectionTimeout")
        if peripheralConnectionTimeout == 0 {
            return 10
        } else {
            return peripheralConnectionTimeout
        }
    }
    
    class func setPeripheralConnectionTimeout(peripheralConnectionTimeout: Int) {
        NSUserDefaults.standardUserDefaults().setInteger(peripheralConnectionTimeout, forKey:"peripheralConnectionTimeout")
    }

    // MARK: characteristic read write timeout
    class func getCharacteristicReadWriteTimeout() -> Int {
        let characteristicReadWriteTimeout = NSUserDefaults.standardUserDefaults().integerForKey("characteristicReadWriteTimeout")
        if characteristicReadWriteTimeout == 0 {
            return 10
        } else {
            return characteristicReadWriteTimeout
        }
    }
    
    class func setCharacteristicReadWriteTimeout(characteristicReadWriteTimeout: Int) {
        NSUserDefaults.standardUserDefaults().setInteger(characteristicReadWriteTimeout, forKey:"characteristicReadWriteTimeout")
    }

    // MARK: maximum reconnections
    class func getMaximumReconnections() -> UInt {
        let maximumReconnetions = NSUserDefaults.standardUserDefaults().integerForKey("maximumReconnections")
        if maximumReconnetions == 0 {
            return 5
        } else {
            return UInt(maximumReconnetions)
        }
    }
    
    class func setMaximumReconnections(maximumReconnections: UInt) {
        NSUserDefaults.standardUserDefaults().setInteger(Int(maximumReconnections), forKey:"maximumReconnections")
    }

    // MARK: maximum peripheral connections
    class func getMaximumConnections() -> UInt {
        let maximumReconnetions = NSUserDefaults.standardUserDefaults().integerForKey("maximumConnections")
        if maximumReconnetions == 0 {
            return 20
        } else {
            return UInt(maximumReconnetions)
        }
    }

    class func setMaximumConnections(maximumConnections: UInt) {
        NSUserDefaults.standardUserDefaults().setInteger(Int(maximumConnections), forKey:"maximumConnections")
    }

    // MARK: maximum discovered peripherals
    class func getMaximumPeripherals() -> UInt {
        let maximumReconnetions = NSUserDefaults.standardUserDefaults().integerForKey("maximumDiscovered")
        if maximumReconnetions == 0 {
            return 20
        } else {
            return UInt(maximumReconnetions)
        }
    }

    class func setMaximumPeripherals(maximumPeripherals: UInt) {
        NSUserDefaults.standardUserDefaults().setInteger(Int(maximumPeripherals), forKey:"maximumDiscovered")
    }

    // MARK: sort order
    class func getSortOrder() -> SortOrder {
        let rawValue = NSUserDefaults.standardUserDefaults().integerForKey("sortOrder")
        if let sortOrder = SortOrder(rawValue) {
            return sortOrder
        } else {
            return .DiscoveryDate
        }
    }

    class func setSortOrder(sortOrder: SortOrder) {
        NSUserDefaults.standardUserDefaults().setInteger(sortOrder.rawValue, forKey:"sortOrder")
    }


    // MARK: scanned services
    class func getScannedServices() -> [String: CBUUID] {
        if let storedServices = NSUserDefaults.standardUserDefaults().dictionaryForKey("services") {
            var services = [String:CBUUID]()
            for (name, uuid) in storedServices {
                if let uuid = uuid as? String {
                    services[name] = CBUUID(string: uuid)
                }
            }
            return services
        } else {
            return [:]
        }
    }
    
    class func getScannedServiceNames() -> [String] {
        return Array(self.getScannedServices().keys)
    }
    
    class func getScannedServiceUUIDs() -> [CBUUID] {
        return Array(self.getScannedServices().values)
    }
    
    class func getScannedServiceUUID(name: String) -> CBUUID? {
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
    
}