//
//  BLESIGGATTProfiles.swift
//  BlueCap
//
//  Created by Troy Stribling on 7/25/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation
import CoreBluetooth
import BlueCapKit

public struct BLESIGGATT {
    
    //***************************************************************************************************
    // Device Information Service
    //***************************************************************************************************
    struct DeviceInformationService {
        static let uuid = "180a"
        static let name = "Device Information"
        struct ModelNumber {
            static let uuid = "2a24"
            static let name = "Device Model Number"
        }
        struct SerialNumber {
            static let uuid = "2a25"
            static let name = "Device Serial Number"
        }
        struct FirmwareRevision {
            static let uuid = "2a26"
            static let name = "Device Firmware Revision"
        }
        struct HardwareRevision {
            static let uuid = "2a27"
            static let name = "Device Hardware Revision"
        }
        struct SoftwareRevision {
            static let uuid = "2a28"
            static let name = "Device Software Revision"
        }
        struct ManufacturerName {
            static let uuid = "2a29"
            static let name = "Device Manufacturer Name"
        }
    }
    
    //***************************************************************************************************
    // Battery Service
    //***************************************************************************************************
    struct BatteryService {
        static let uuid = "180f"
        static let name = "Battery"
        struct Level {
            static let uuid = "2a19"
            static let name = "Battery Level"
        }
    }

    //***************************************************************************************************
    // Tx Power Service
    //***************************************************************************************************
    struct TxPowerService {
        static let uuid = "1804"
        static let name = "Tx Power Level"
        struct Level {
            static let uuid = "2a07"
            static let name = "Tx Power Level"
        }
    }
    
}

public class BLESIGGATTProfiles {
    
    public class func create () {
        
        let profileManager = ProfileManager.sharedInstance
        
        //***************************************************************************************************
        // Device Information Service
        //***************************************************************************************************
        profileManager.addService(ServiceProfile(uuid:BLESIGGATT.DeviceInformationService.uuid, name:BLESIGGATT.DeviceInformationService.name){(serviceProfile) in
            serviceProfile.tag = "BLESIGGATT"
            serviceProfile.addCharacteristic(StringCharacteristicProfile(uuid:BLESIGGATT.DeviceInformationService.ModelNumber.uuid, name:BLESIGGATT.DeviceInformationService.ModelNumber.name)
                {(characteristicProfile:StringCharacteristicProfile) in
                    characteristicProfile.properties = CBCharacteristicProperties.Read
                    characteristicProfile.initialValue = "Model A".dataUsingEncoding(NSUTF8StringEncoding)
                })
            serviceProfile.addCharacteristic(StringCharacteristicProfile(uuid:BLESIGGATT.DeviceInformationService.SerialNumber.uuid, name:BLESIGGATT.DeviceInformationService.SerialNumber.name)
                {(characteristicProfile:StringCharacteristicProfile) in
                    characteristicProfile.properties = CBCharacteristicProperties.Read
                    characteristicProfile.initialValue = "AAA11".dataUsingEncoding(NSUTF8StringEncoding)
                })
            serviceProfile.addCharacteristic(StringCharacteristicProfile(uuid:BLESIGGATT.DeviceInformationService.FirmwareRevision.uuid, name:BLESIGGATT.DeviceInformationService.FirmwareRevision.name)
                {(characteristicProfile:StringCharacteristicProfile) in
                    characteristicProfile.properties = CBCharacteristicProperties.Read
                    characteristicProfile.initialValue = "1.0".dataUsingEncoding(NSUTF8StringEncoding)
                })
            serviceProfile.addCharacteristic(StringCharacteristicProfile(uuid:BLESIGGATT.DeviceInformationService.HardwareRevision.uuid, name:BLESIGGATT.DeviceInformationService.HardwareRevision.name)
                {(characteristicProfile:StringCharacteristicProfile) in
                    characteristicProfile.properties = CBCharacteristicProperties.Read
                    characteristicProfile.initialValue = "1.0".dataUsingEncoding(NSUTF8StringEncoding)
                })
            serviceProfile.addCharacteristic(StringCharacteristicProfile(uuid:BLESIGGATT.DeviceInformationService.SoftwareRevision.uuid, name:BLESIGGATT.DeviceInformationService.SoftwareRevision.name)
                {(characteristicProfile:StringCharacteristicProfile) in
                    characteristicProfile.properties = CBCharacteristicProperties.Read
                    characteristicProfile.initialValue = "1.0".dataUsingEncoding(NSUTF8StringEncoding)
                })
            serviceProfile.addCharacteristic(StringCharacteristicProfile(uuid:BLESIGGATT.DeviceInformationService.ManufacturerName.uuid, name:BLESIGGATT.DeviceInformationService.ManufacturerName.name)
                {(characteristicProfile:StringCharacteristicProfile) in
                    characteristicProfile.properties = CBCharacteristicProperties.Read
                    characteristicProfile.initialValue = "gnos.us".dataUsingEncoding(NSUTF8StringEncoding)
                })
        })

        //***************************************************************************************************
        // Battery Service
        //***************************************************************************************************
        profileManager.addService(ServiceProfile(uuid:BLESIGGATT.BatteryService.uuid, name:BLESIGGATT.BatteryService.name){(serviceProfile) in
            serviceProfile.tag = "BLESIGGATT"
            serviceProfile.addCharacteristic(DeserializedCharacteristicProfile<UInt8>(uuid:BLESIGGATT.BatteryService.Level.uuid, name:BLESIGGATT.BatteryService.Level.name)
                {(characteristicProfile) in
                    characteristicProfile.initialValue = NSData.serialize(UInt8(100))
                    characteristicProfile.properties = CBCharacteristicProperties.Notify | CBCharacteristicProperties.Read
                })
        })

        //***************************************************************************************************
        // Tx Power Service
        //***************************************************************************************************
        profileManager.addService(ServiceProfile(uuid:BLESIGGATT.TxPowerService.uuid, name:BLESIGGATT.TxPowerService.name){(serviceProfile) in
            serviceProfile.tag = "BLESIGGATT"
            serviceProfile.addCharacteristic(DeserializedCharacteristicProfile<Int8>(uuid:BLESIGGATT.TxPowerService.uuid, name:BLESIGGATT.TxPowerService.name)
                {(characteristicProfile) in
                    characteristicProfile.initialValue = NSData.serialize(Int8(-40))
                    characteristicProfile.properties = CBCharacteristicProperties.Read
                })
        })
    }
}