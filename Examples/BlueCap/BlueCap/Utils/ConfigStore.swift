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

// MARK: Defaults
struct Defaults {
    static let serviceScanMode: ServiceScanMode = .Promiscuous
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
class ConfigStore {
  
    // MARK: Scan Mode
    class func getScanMode() -> ServiceScanMode {
        let rawValue = NSUserDefaults.standardUserDefaults().integerForKey("scanMode")
        if let serviceScanMode = ServiceScanMode(rawValue) {
            return serviceScanMode
        } else {
            return Defaults.serviceScanMode
        }
    }
    
    class func setScanMode(scanMode: ServiceScanMode) {
        NSUserDefaults.standardUserDefaults().setInteger(scanMode.rawValue, forKey:"scanMode")
    }
    
    // MARK: Scan Timeout
    class func getScanTimeoutEnabled() -> Bool {
        return NSUserDefaults.standardUserDefaults().boolForKey("scanTimeoutEnabled")
    }
    
    class func setScanTimeoutEnabled(timeoutEnabled: Bool) {
        NSUserDefaults.standardUserDefaults().setBool(timeoutEnabled, forKey:"scanTimeoutEnabled")
    }
    
    class func getScanTimeout() -> UInt {
        let timeout = NSUserDefaults.standardUserDefaults().integerForKey("scanTimeout")
        return UInt(timeout)
    }
    
    class func setScanTimeout(timeout: UInt) {
        NSUserDefaults.standardUserDefaults().setInteger(Int(timeout), forKey:"scanTimeout")
    }
    
    // MARK: Peripheral Connection Timeout
    class func getPeripheralConnectionTimeoutEnabled() -> Bool {
        return NSUserDefaults.standardUserDefaults().boolForKey("peripheralConnectionTimeoutEnabled")
    }

    class func setPeripheralConnectionTimeoutEnabled(timeoutEnabled: Bool) {
        NSUserDefaults.standardUserDefaults().setBool(timeoutEnabled, forKey:"peripheralConnectionTimeoutEnabled")
    }

    class func getPeripheralConnectionTimeout () -> UInt {
        let timeout = NSUserDefaults.standardUserDefaults().integerForKey("peripheralConnectionTimeout")
        return UInt(timeout)
    }
    
    class func setPeripheralConnectionTimeout(peripheralConnectionTimeout: UInt) {
        NSUserDefaults.standardUserDefaults().setInteger(Int(peripheralConnectionTimeout), forKey:"peripheralConnectionTimeout")
    }

    // MARK: Characteristic Read Write Timeout
    class func getCharacteristicReadWriteTimeout() -> UInt {
        let characteristicReadWriteTimeout = NSUserDefaults.standardUserDefaults().integerForKey("characteristicReadWriteTimeout")
        return UInt(characteristicReadWriteTimeout)
    }
    
    class func setCharacteristicReadWriteTimeout(characteristicReadWriteTimeout: UInt) {
        NSUserDefaults.standardUserDefaults().setInteger(Int(characteristicReadWriteTimeout), forKey:"characteristicReadWriteTimeout")
    }

    // MARK: Maximum Disconnections
    class func getPeripheralMaximumDisconnectionsEnabled() -> Bool {
        return NSUserDefaults.standardUserDefaults().boolForKey("peripheralMaximumDisconnectionsEnabled")
    }

    class func setPeripheralMaximumDisconnectionsEnabled(timeoutEnabled: Bool) {
        NSUserDefaults.standardUserDefaults().setBool(timeoutEnabled, forKey:"peripheralMaximumDisconnectionsEnabled")
    }

    class func getPeripheralMaximumDisconnections() -> UInt {
        let maximumDisconnections = NSUserDefaults.standardUserDefaults().integerForKey("peripheralMaximumDisconnections")
        return UInt(maximumDisconnections)
    }
    
    class func setPeripheralMaximumDisconnections(maximumDisconnections: UInt) {
        NSUserDefaults.standardUserDefaults().setInteger(Int(maximumDisconnections), forKey:"peripheralMaximumDisconnections")
    }

    // MARK: Maximum Timeouts
    class func getPeripheralMaximumTimeoutsEnabled() -> Bool {
        return NSUserDefaults.standardUserDefaults().boolForKey("peripheralMaximumTimeoutsEnabled")
    }

    class func setPeripheralMaximumTimeoutsEnabled(timeoutEnabled: Bool) {
        NSUserDefaults.standardUserDefaults().setBool(timeoutEnabled, forKey:"peripheralMaximumTimeoutsEnabled")
    }


    class func getPeripheralMaximumTimeouts() -> UInt {
        let maximumTimeouts = NSUserDefaults.standardUserDefaults().integerForKey("peripheralMaximumTimeouts")
        return UInt(maximumTimeouts)
    }

    class func setPeripheralMaximumTimeouts(maximumTimeouts: UInt) {
        NSUserDefaults.standardUserDefaults().setInteger(Int(maximumTimeouts), forKey:"peripheralMaximumTimeouts")
    }

    // MARK: Maximum Peripherals Connected
    class func getMaximumPeripheralsConnected() -> Int {
        return NSUserDefaults.standardUserDefaults().integerForKey("maximumPeripheralsConnected")
    }

    class func setMaximumPeripheralsConnected(maximumConnections: Int) {
        NSUserDefaults.standardUserDefaults().setInteger(maximumConnections, forKey:"maximumPeripheralsConnected")
    }

    // MARK: Maximum Discovered Peripherals
    class func getMaximumPeripheralsDiscovered() -> Int {
        return NSUserDefaults.standardUserDefaults().integerForKey("maximumPeripheralsDiscovered")
    }

    class func setMaximumPeripheralsDiscovered(maximumPeripherals: Int) {
        NSUserDefaults.standardUserDefaults().setInteger(maximumPeripherals, forKey:"maximumPeripheralsDiscovered")
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
    }
    
    // MARK: Scanned Services
    class func getScannedServices() -> [String: CBUUID] {
        if let storedServices = NSUserDefaults.standardUserDefaults().dictionaryForKey("services") {
            var services = [String: CBUUID]()
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
    
    class func setScannedServices(services:[String: CBUUID]) {
        var storedServices = [String:String]()
        for (name, uuid) in services {
            storedServices[name] = uuid.UUIDString
        }
        NSUserDefaults.standardUserDefaults().setObject(storedServices, forKey:"services")
    }
    
    class func addScannedService(name :String, uuid: CBUUID) {
        var services = self.getScannedServices()
        services[name] = uuid
        self.setScannedServices(services)
    }
    
    class func removeScannedService(name: String) {
        var beacons = self.getScannedServices()
        beacons.removeValueForKey(name)
        self.setScannedServices(beacons)
    }
    
}