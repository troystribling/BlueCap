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
    static let serviceScanMode: ServiceScanMode = .promiscuous
    static let peripheralSortOrder: PeripheralSortOrder = .discoveryDate
}

// MARK: Service Scan Mode
enum ServiceScanMode: Int {
    case promiscuous = 0
    case service = 1

    init?(_ stringValue: String) {
        switch stringValue {
        case "Promiscuous":
            self = .promiscuous
        case "Service":
            self = .service
        default:
            return nil
        }
    }

    init?(_ rawValue: Int) {
        switch rawValue {
        case 0:
            self = .promiscuous
        case 1:
            self = .service
        default:
            return nil
        }
    }

    var stringValue: String {
        switch self {
        case .promiscuous:
            return "Promiscuous"
        case .service:
            return "Service"
        }
    }
}

// MARK: Peripheral Sort Order
enum PeripheralSortOrder: Int {
    case discoveryDate = 0
    case rssi = 1

    init?(_ stringValue: String) {
        switch stringValue {
        case "Discovery Date":
            self = .discoveryDate
        case "RSSI":
            self = .rssi
        default:
            return nil
        }
    }

    init?(_ rawValue: Int) {
        switch rawValue {
        case 0:
            self = .discoveryDate
        case 1:
            self = .rssi
        default:
            return nil
        }
    }

    var stringValue: String {
        switch self {
        case .discoveryDate:
            return "Discovery Date"
        case .rssi:
            return "RSSI"
        }
    }
}

// MARK: - ConfigStore -
class ConfigStore {
  
    // MARK: Scan Mode
    class func getScanMode() -> ServiceScanMode {
        let rawValue = UserDefaults.standard.integer(forKey: "scanMode")
        if let serviceScanMode = ServiceScanMode(rawValue) {
            return serviceScanMode
        } else {
            return Defaults.serviceScanMode
        }
    }
    
    class func setScanMode(_ scanMode: ServiceScanMode) {
        UserDefaults.standard.set(scanMode.rawValue, forKey:"scanMode")
    }
    
    // MARK: Scan Duration
    class func getScanDurationEnabled() -> Bool {
        return UserDefaults.standard.bool(forKey: "scanDurationEnabled")
    }
    
    class func setScanDurationEnabled(_ timeoutEnabled: Bool) {
        UserDefaults.standard.set(timeoutEnabled, forKey:"scanDurationEnabled")
    }
    
    class func getScanDuration() -> UInt {
        let timeout = UserDefaults.standard.integer(forKey: "scanDuration")
        return UInt(timeout)
    }
    
    class func setScanDuration(_ duration: UInt) {
        UserDefaults.standard.set(Int(duration), forKey:"scanDuration")
    }
    
    // MARK: Peripheral Connection Timeout
    class func getPeripheralConnectionTimeoutEnabled() -> Bool {
        return UserDefaults.standard.bool(forKey: "peripheralConnectionTimeoutEnabled")
    }

    class func setPeripheralConnectionTimeoutEnabled(_ timeoutEnabled: Bool) {
        UserDefaults.standard.set(timeoutEnabled, forKey:"peripheralConnectionTimeoutEnabled")
    }

    class func getPeripheralConnectionTimeout () -> UInt {
        let timeout = UserDefaults.standard.integer(forKey: "peripheralConnectionTimeout")
        return UInt(timeout)
    }
    
    class func setPeripheralConnectionTimeout(_ peripheralConnectionTimeout: UInt) {
        UserDefaults.standard.set(Int(peripheralConnectionTimeout), forKey:"peripheralConnectionTimeout")
    }

    // MARK: Characteristic Read Write Timeout
    class func getCharacteristicReadWriteTimeout() -> UInt {
        let characteristicReadWriteTimeout = UserDefaults.standard.integer(forKey: "characteristicReadWriteTimeout")
        return UInt(characteristicReadWriteTimeout)
    }
    
    class func setCharacteristicReadWriteTimeout(_ characteristicReadWriteTimeout: UInt) {
        UserDefaults.standard.set(Int(characteristicReadWriteTimeout), forKey:"characteristicReadWriteTimeout")
    }

    // MARK: Maximum Disconnections
    class func getPeripheralMaximumDisconnectionsEnabled() -> Bool {
        return UserDefaults.standard.bool(forKey: "peripheralMaximumDisconnectionsEnabled")
    }

    class func setPeripheralMaximumDisconnectionsEnabled(_ timeoutEnabled: Bool) {
        UserDefaults.standard.set(timeoutEnabled, forKey:"peripheralMaximumDisconnectionsEnabled")
    }

    class func getPeripheralMaximumDisconnections() -> UInt {
        let maximumDisconnections = UserDefaults.standard.integer(forKey: "peripheralMaximumDisconnections")
        return UInt(maximumDisconnections)
    }
    
    class func setPeripheralMaximumDisconnections(_ maximumDisconnections: UInt) {
        UserDefaults.standard.set(Int(maximumDisconnections), forKey:"peripheralMaximumDisconnections")
    }

    // MARK: Maximum Timeouts
    class func getPeripheralMaximumTimeoutsEnabled() -> Bool {
        return UserDefaults.standard.bool(forKey: "peripheralMaximumTimeoutsEnabled")
    }

    class func setPeripheralMaximumTimeoutsEnabled(_ timeoutEnabled: Bool) {
        UserDefaults.standard.set(timeoutEnabled, forKey:"peripheralMaximumTimeoutsEnabled")
    }


    class func getPeripheralMaximumTimeouts() -> UInt {
        let maximumTimeouts = UserDefaults.standard.integer(forKey: "peripheralMaximumTimeouts")
        return UInt(maximumTimeouts)
    }

    class func setPeripheralMaximumTimeouts(_ maximumTimeouts: UInt) {
        UserDefaults.standard.set(Int(maximumTimeouts), forKey:"peripheralMaximumTimeouts")
    }

    // MARK: Maximum Peripherals Connected
    class func getMaximumPeripheralsConnected() -> Int {
        return UserDefaults.standard.integer(forKey: "maximumPeripheralsConnected")
    }

    class func setMaximumPeripheralsConnected(_ maximumConnections: Int) {
        UserDefaults.standard.set(maximumConnections, forKey:"maximumPeripheralsConnected")
    }

    // MARK: Maximum Discovered Peripherals
    class func getMaximumPeripheralsDiscovered() -> Int {
        return UserDefaults.standard.integer(forKey: "maximumPeripheralsDiscovered")
    }

    class func setMaximumPeripheralsDiscovered(_ maximumPeripherals: Int) {
        UserDefaults.standard.set(maximumPeripherals, forKey:"maximumPeripheralsDiscovered")
    }

    // MARK: Peripheral Sort Order
    class func getPeripheralSortOrder() -> PeripheralSortOrder {
        let rawValue = UserDefaults.standard.integer(forKey: "peripheralSortOrder")
        if let peripheralSortOrder = PeripheralSortOrder(rawValue) {
            return peripheralSortOrder
        } else {
            return Defaults.peripheralSortOrder
        }
    }

    class func setPeripheralSortOrder(_ sortOrder: PeripheralSortOrder) {
        UserDefaults.standard.set(sortOrder.rawValue, forKey:"peripheralSortOrder")
    }
    
    // MARK: Scanned Services
    class func getScannedServices() -> [String : CBUUID] {
        if let storedServices = UserDefaults.standard.dictionary(forKey: "services") {
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
    
    class func getScannedServiceUUID(_ name: String) -> CBUUID? {
        let services = self.getScannedServices()
        if let uuid = services[name] {
            return uuid
        } else {
            return nil
        }
    }
    
    class func setScannedServices(_ services:[String: CBUUID]) {
        var storedServices = [String:String]()
        for (name, uuid) in services {
            storedServices[name] = uuid.uuidString
        }
        UserDefaults.standard.set(storedServices, forKey:"services")
    }
    
    class func addScannedService(_ name :String, uuid: CBUUID) {
        var services = self.getScannedServices()
        services[name] = uuid
        self.setScannedServices(services)
    }
    
    class func removeScannedService(_ name: String) {
        var beacons = self.getScannedServices()
        beacons.removeValue(forKey: name)
        self.setScannedServices(beacons)
    }
    
}
