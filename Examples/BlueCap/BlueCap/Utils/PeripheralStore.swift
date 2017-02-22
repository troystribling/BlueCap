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

    class func getPeripheralServices(forKey key: String) -> [CBUUID] {
        guard let storedServices = UserDefaults.standard.array(forKey: key) else {
            return []
        }
        return storedServices.reduce([CBUUID]()) { (uuids, uuid) in
            guard let uuidString = uuid as? String  else {
                return uuids
            }
            return uuids + [CBUUID(string: uuidString)]
        }
    }

    class func setPeripheralServices(forKey key: String, uuids: [CBUUID]) {
        let storedServices = uuids.map { $0.uuidString }
        UserDefaults.standard.set(storedServices, forKey:key)
    }
    
    // MARK: Peripheral Supported Services

    class func getSupportedPeripheralServices() -> [CBUUID] {
        return getPeripheralServices(forKey: "supportedPeripheralServices")
    }

    class func setSupportedPeripheralServices(_ uuids: [CBUUID]) {
        setPeripheralServices(forKey: "supportedPeripheralServices", uuids: uuids)
    }

    class func addSupportedPeripheralService(_ uuid: CBUUID) {
        let uuids = getSupportedPeripheralServices() + [uuid]
        setSupportedPeripheralServices(uuids)
    }

    class func removeSupportedPeripheralService(_ uuid: CBUUID) {
        let remainingServices =  getSupportedPeripheralServices().filter { $0 != uuid }
        let remmovedServices = getSupportedPeripheralServices().filter { $0 == uuid }.dropFirst()
        setSupportedPeripheralServices(remainingServices + remmovedServices)
    }

    // MARK: Advertised Peripheral Services

    class func getAdvertisedPeripheralServices() -> [CBUUID] {
        return getPeripheralServices(forKey: "advertisedPeripheralServices")
    }

    class func setAdvertisedPeripheralServices(_ uuids: [CBUUID]) {
        setPeripheralServices(forKey: "advertisedPeripheralServices", uuids: uuids)
    }

    class func addAdvertisedPeripheralService(_ uuid: CBUUID) {
        let uuids = getAdvertisedPeripheralServices() + [uuid]
        setAdvertisedPeripheralServices(uuids)
    }

    class func removeAdvertisedPeripheralService(_ uuid: CBUUID) {
        let uuids = getAdvertisedPeripheralServices().filter { $0 != uuid }
        setAdvertisedPeripheralServices(uuids)
    }

    // MARK: Periphearl Name

    class func getPeripheralName() -> String? {
        return UserDefaults.standard.string(forKey: "peripheralName")
    }

    class func setPeripheralName(_ name: String) {
        UserDefaults.standard.set(name, forKey:"peripheralName")
    }

    // MARK: Peripheral Beacon
    
    class func getBeaconUUID() -> UUID? {
        return UserDefaults.standard.string(forKey: "peripheralBeaconUUID").flatMap { UUID(uuidString: $0) }
    }
    
    class func setBeaconUUID(_ uuid: UUID) {
        UserDefaults.standard.set(uuid.uuidString, forKey: "peripheralBeaconUUID")
    }
    
    class func getBeaconName() -> String? {
        return UserDefaults.standard.string(forKey: "peripheralBeaconName")
    }

    class func setBeaconName(_ name: String) {
        UserDefaults.standard.set(name, forKey:"peripheralBeaconName")
    }

    class func getBeaconMinorMajor() -> [UInt16] {
        guard let storedConfig = UserDefaults.standard.array(forKey: "peipheralBeaconConfig") as? [NSNumber], storedConfig.count == 2 else {
            return []
        }
        return [storedConfig[0].uint16Value, storedConfig[1].uint16Value]
    }
    
    class func setBeaconMinorMajor(_ config: [UInt16]) {
        let storedConfig = [NSNumber(value: config[0]), NSNumber(value: config[1])]
        UserDefaults.standard.set(storedConfig, forKey:"peipheralBeaconConfig")
    }

}
