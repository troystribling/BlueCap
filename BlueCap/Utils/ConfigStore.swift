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

<<<<<<< Updated upstream
=======
// MARK: Defaults
struct Defaults {
    static let serviceScanMode: ServiceScanMode = .Promiscuous
    static let scanTimeout: UInt = 10
    static let connectionTimeout: UInt = 10
    static let peripheralConnectionTimeout: UInt = 10
    static let characteristicReadWriteTimeout: UInt = 10
    static let maximumReconnections: UInt = 5
    static let maximumPeripheralsConnected: Int = 20
    static let maximumPeripheralsDiscovered: Int = 100
    static let peripheralSortOrder: PeripheralSortOrder = .DiscoveryDate
}

// MARK: Service Scan Mode
enum ServiceScanMode: Int {
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

// MARK: Peripheral Sort Order
enum PeripheralSortOrder: Int {
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
>>>>>>> Stashed changes
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
    class func getMaximumReconnections() -> UInt {
        let maximumReconnetions = NSUserDefaults.standardUserDefaults().integerForKey("maximumReconnections")
        if maximumReconnetions == 0 {
            return 5
        } else {
            return UInt(maximumReconnetions)
        }
    }
    
<<<<<<< Updated upstream
    class func setMaximumReconnections(maximumReconnetions:UInt) {
        NSUserDefaults.standardUserDefaults().setInteger(Int(maximumReconnetions), forKey:"maximumReconnections")
=======
    class func setMaximumReconnections(maximumReconnections: UInt) {
        NSUserDefaults.standardUserDefaults().setInteger(Int(maximumReconnections), forKey:"maximumReconnections")
    }

    // MARK: Maximum Peripherals Connected
    class func getMaximumPeripheralsConnected() -> Int {
        let maximumPeripheralsConnected = NSUserDefaults.standardUserDefaults().integerForKey("maximumPeripheralsConnected")
        if maximumPeripheralsConnected == 0 {
            return Defaults.maximumPeripheralsConnected
        } else {
            return maximumPeripheralsConnected
        }
    }

    class func setMaximumPeripheralsConnected(maximumConnections: UInt) {
        NSUserDefaults.standardUserDefaults().setInteger(Int(maximumConnections), forKey:"maximumPeripheralsConnected")
    }

    // MARK: Maximum Discovered Peripherals
    class func getMaximumPeripheralsDiscovered() -> Int {
        let maximumPeripheralsDiscovered = NSUserDefaults.standardUserDefaults().integerForKey("maximumPeripheralsDiscovered")
        if maximumPeripheralsDiscovered == 0 {
            return Defaults.maximumPeripheralsDiscovered
        } else {
            return maximumPeripheralsDiscovered
        }
    }

    class func setMaximumPeripheralsDiscovered(maximumPeripherals: UInt) {
        NSUserDefaults.standardUserDefaults().setInteger(Int(maximumPeripherals), forKey:"maximumPeripheralsDiscovered")
    }

    // MARK: Peripheral Sort Order
    class func getPeripheralSortOrder() -> PeripheralSortOrder {
        let rawValue = NSUserDefaults.standardUserDefaults().integerForKey("peripheralSortOrder")
        if let peripheralSortOrder = PeripheralSortOrder(rawValue) {
            return peripheralSortOrder
        } else {
            return Defaults.peripheralSortOrder
        }
    }

    class func setPeripheralSortOrder(sortOrder: PeripheralSortOrder) {
        NSUserDefaults.standardUserDefaults().setInteger(sortOrder.rawValue, forKey:"peripheralSortOrder")
>>>>>>> Stashed changes
    }
    
    // scanned services
    class func getScannedServices() -> [String:CBUUID] {
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
    
}