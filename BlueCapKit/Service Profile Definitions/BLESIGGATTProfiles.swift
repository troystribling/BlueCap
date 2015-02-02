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
    public struct DeviceInformationService : ServiceConfigurable {

        // ServiceConfigurable
        public static let uuid = "180a"
        public static let name = "Device Information"
        public static let tag  = "BLESIGGATT"
        
        public struct ModelNumber : CharacteristicConfigurable {
            
            // CharacteristicConfigurable
            public static let uuid = "2a24"
            public static let name = "Device Model Number"
            public static let permissions  = CBAttributePermissions.Readable | CBAttributePermissions.Writeable
            public static let properties   = CBCharacteristicProperties.Read
            public static let initialValue = serialize("Model A")
            
        }
        
        public struct SerialNumber : CharacteristicConfigurable {

            // CharacteristicConfigurable
            public static let uuid = "2a25"
            public static let name = "Device Serial Number"
            public static let permissions  = CBAttributePermissions.Readable | CBAttributePermissions.Writeable
            public static let properties   = CBCharacteristicProperties.Read
            public static let initialValue = serialize("AAA11")
            
        }
        
        public struct FirmwareRevision : CharacteristicConfigurable {

            // CharacteristicConfigurable
            public static let uuid = "2a26"
            public static let name = "Device Firmware Revision"
            public static let permissions  = CBAttributePermissions.Readable | CBAttributePermissions.Writeable
            public static let properties   = CBCharacteristicProperties.Read
            public static let initialValue = serialize("1.0")

        }
        
        public struct HardwareRevision : CharacteristicConfigurable {
            
            // CharacteristicConfigurable
            public static let uuid = "2a27"
            public static let name = "Device Hardware Revision"
            public static let permissions  = CBAttributePermissions.Readable | CBAttributePermissions.Writeable
            public static let properties   = CBCharacteristicProperties.Read
            public static let initialValue = serialize("1.0")
            
        }
        
        public struct SoftwareRevision : CharacteristicConfigurable {
            
            // CharacteristicConfigurable
            public static let uuid = "2a28"
            public static let name = "Device Software Revision"
            public static let permissions  = CBAttributePermissions.Readable | CBAttributePermissions.Writeable
            public static let properties   = CBCharacteristicProperties.Read
            public static let initialValue = serialize("1.0")

        }
        
        public struct ManufacturerName : CharacteristicConfigurable {
            
            // CharacteristicConfigurable
            public static let uuid = "2a29"
            public static let name = "Device Manufacturer Name"
            public static let permissions  = CBAttributePermissions.Readable | CBAttributePermissions.Writeable
            public static let properties   = CBCharacteristicProperties.Read
            public static let initialValue = serialize("gnos.us")
            
        }
    }
    
    //***************************************************************************************************
    // Battery Service
    public struct BatteryService : ServiceConfigurable {

        // ServiceConfigurable
        public static let uuid = "180f"
        public static let name = "Battery"
        public static let tag  = "BLESIGGATT"
        
        public struct Level : RawDeserializable, CharacteristicConfigurable, StringDeserializable {
            
            public let value : UInt8
            
            // CharacteristicConfigurable
            public static let uuid                      = "2a19"
            public static let name                      = "Battery Level"
            public static let permissions               = CBAttributePermissions.Readable | CBAttributePermissions.Writeable
            public static let properties                = CBCharacteristicProperties.Notify | CBCharacteristicProperties.Read
            public static let initialValue : NSData?    = serialize(UInt8(100))

            // RawDeserializable
            public var rawValue : UInt8 {
                return self.value
            }
            public init?(rawValue:UInt8) {
                self.value = rawValue
            }
            
            // StringDeserializable
            public static let stringValues = [String]()
            
            public var stringValue : [String:String] {
                return [Level.name:"\(self.value)"]
            }
            
            public init?(stringValue:[String:String]) {
                if let valueInit = uint8ValueFromStringValue(Level.name, stringValue) {
                    self.value = valueInit
                } else {
                    return nil
                }
            }

        }
    }

    //***************************************************************************************************
    // Tx Power Service
    public struct TxPowerService : ServiceConfigurable {

        // ServiceConfigurable
        public static let uuid = "1804"
        public static let name = "Tx Power Level"
        public static let tag  = "BLESIGGATT"

        public struct Level : RawDeserializable, CharacteristicConfigurable, StringDeserializable {
            
            public let value : Int8
            
            // CharacteristicConfigurable
            public static let uuid                      = "2a07"
            public static let name                      = "Tx Power Level"
            public static let permissions               = CBAttributePermissions.Readable | CBAttributePermissions.Writeable
            public static let properties                = CBCharacteristicProperties.Notify | CBCharacteristicProperties.Read
            public static let initialValue : NSData?    = serialize(Int8(-40))
            
            // RawDeserializable
            public var rawValue : Int8 {
                return self.value
            }
            public init?(rawValue:Int8) {
                self.value = rawValue
            }
            
            // StringDeserializable
            public static let stringValues = [String]()
            
            public var stringValue : [String:String] {
                return [Level.name:"\(self.value)"]
            }
            
            public init?(stringValue:[String:String]) {
                if let valueInit = int8ValueFromStringValue(Level.name, stringValue) {
                    self.value = valueInit
                } else {
                    return nil
                }
            }

        }
    }
    
}
//
//public class BLESIGGATTProfiles {
//    
//    public class func create () {
//        
//        let profileManager = ProfileManager.sharedInstance
//        
//        //***************************************************************************************************
//        // Device Information Service
//        //***************************************************************************************************
//        profileManager.addService(ServiceProfile(uuid:BLESIGGATT.DeviceInformationService.uuid, name:BLESIGGATT.DeviceInformationService.name){(serviceProfile) in
//            serviceProfile.tag = "BLESIGGATT"
//            serviceProfile.addCharacteristic(StringCharacteristicProfile(uuid:BLESIGGATT.DeviceInformationService.ModelNumber.uuid, name:BLESIGGATT.DeviceInformationService.ModelNumber.name)
//                {(characteristicProfile:StringCharacteristicProfile) in
//                    characteristicProfile.properties = CBCharacteristicProperties.Read
//                    characteristicProfile.initialValue = "Model A".dataUsingEncoding(NSUTF8StringEncoding)
//                })
//            serviceProfile.addCharacteristic(StringCharacteristicProfile(uuid:BLESIGGATT.DeviceInformationService.SerialNumber.uuid, name:BLESIGGATT.DeviceInformationService.SerialNumber.name)
//                {(characteristicProfile:StringCharacteristicProfile) in
//                    characteristicProfile.properties = CBCharacteristicProperties.Read
//                    characteristicProfile.initialValue = "AAA11".dataUsingEncoding(NSUTF8StringEncoding)
//                })
//            serviceProfile.addCharacteristic(StringCharacteristicProfile(uuid:BLESIGGATT.DeviceInformationService.FirmwareRevision.uuid, name:BLESIGGATT.DeviceInformationService.FirmwareRevision.name)
//                {(characteristicProfile:StringCharacteristicProfile) in
//                    characteristicProfile.properties = CBCharacteristicProperties.Read
//                    characteristicProfile.initialValue = "1.0".dataUsingEncoding(NSUTF8StringEncoding)
//                })
//            serviceProfile.addCharacteristic(StringCharacteristicProfile(uuid:BLESIGGATT.DeviceInformationService.HardwareRevision.uuid, name:BLESIGGATT.DeviceInformationService.HardwareRevision.name)
//                {(characteristicProfile:StringCharacteristicProfile) in
//                    characteristicProfile.properties = CBCharacteristicProperties.Read
//                    characteristicProfile.initialValue = "1.0".dataUsingEncoding(NSUTF8StringEncoding)
//                })
//            serviceProfile.addCharacteristic(StringCharacteristicProfile(uuid:BLESIGGATT.DeviceInformationService.SoftwareRevision.uuid, name:BLESIGGATT.DeviceInformationService.SoftwareRevision.name)
//                {(characteristicProfile:StringCharacteristicProfile) in
//                    characteristicProfile.properties = CBCharacteristicProperties.Read
//                    characteristicProfile.initialValue = "1.0".dataUsingEncoding(NSUTF8StringEncoding)
//                })
//            serviceProfile.addCharacteristic(StringCharacteristicProfile(uuid:BLESIGGATT.DeviceInformationService.ManufacturerName.uuid, name:BLESIGGATT.DeviceInformationService.ManufacturerName.name)
//                {(characteristicProfile:StringCharacteristicProfile) in
//                    characteristicProfile.properties = CBCharacteristicProperties.Read
//                    characteristicProfile.initialValue = "gnos.us".dataUsingEncoding(NSUTF8StringEncoding)
//                })
//        })
//
//        //***************************************************************************************************
//        // Battery Service
//        //***************************************************************************************************
//        profileManager.addService(ServiceProfile(uuid:BLESIGGATT.BatteryService.uuid, name:BLESIGGATT.BatteryService.name){(serviceProfile) in
//            serviceProfile.tag = "BLESIGGATT"
//            serviceProfile.addCharacteristic(DeserializedCharacteristicProfile<UInt8>(uuid:BLESIGGATT.BatteryService.Level.uuid, name:BLESIGGATT.BatteryService.Level.name)
//                {(characteristicProfile) in
//                    characteristicProfile.initialValue = NSData.serialize(UInt8(100))
//                    characteristicProfile.properties = CBCharacteristicProperties.Notify | CBCharacteristicProperties.Read
//                })
//        })
//
//        //***************************************************************************************************
//        // Tx Power Service
//        //***************************************************************************************************
//        profileManager.addService(ServiceProfile(uuid:BLESIGGATT.TxPowerService.uuid, name:BLESIGGATT.TxPowerService.name){(serviceProfile) in
//            serviceProfile.tag = "BLESIGGATT"
//            serviceProfile.addCharacteristic(DeserializedCharacteristicProfile<Int8>(uuid:BLESIGGATT.TxPowerService.uuid, name:BLESIGGATT.TxPowerService.name)
//                {(characteristicProfile) in
//                    characteristicProfile.initialValue = NSData.serialize(Int8(-40))
//                    characteristicProfile.properties = CBCharacteristicProperties.Read
//                })
//        })
//    }
//}