//
//  BLESIGGATTProfiles.swift
//  BlueCap
//
//  Created by Troy Stribling on 7/25/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import Foundation
import CoreBluetooth

// MARK: - BLESIGGATT -
public struct BLESIGGATT {

    // MARK: - Device Information Service -
    public struct DeviceInformationService: BCServiceConfigurable {

        // ServiceConfigurable
        public static let UUID = "180a"
        public static let name = "Device Information"
        public static let tag  = "BLESIGGATT"
        
        public struct ModelNumber: BCCharacteristicConfigurable {
            
            // CharacteristicConfigurable
            public static let UUID                                     = "2a24"
            public static let name                                     = "Device Model Number"
            public static let permissions: CBAttributePermissions      = [.Readable, .Writeable]
            public static let properties: CBCharacteristicProperties   = .Read
            public static let initialValue                             = BCSerDe.serialize("Model A")
            
        }
        
        public struct SerialNumber: BCCharacteristicConfigurable {

            // CharacteristicConfigurable
            public static let UUID                                      = "2a25"
            public static let name                                      = "Device Serial Number"
            public static let permissions: CBAttributePermissions       = [.Readable, .Writeable]
            public static let properties: CBCharacteristicProperties    = .Read
            public static let initialValue                              = BCSerDe.serialize("AAA11")
            
        }
        
        public struct FirmwareRevision: BCCharacteristicConfigurable {

            // CharacteristicConfigurable
            public static let UUID                                      = "2a26"
            public static let name                                      = "Device Firmware Revision"
            public static let permissions: CBAttributePermissions       = [.Readable, .Writeable]
            public static let properties: CBCharacteristicProperties    = .Read
            public static let initialValue                              = BCSerDe.serialize("1.0")

        }
        
        public struct HardwareRevision: BCCharacteristicConfigurable {
            
            // CharacteristicConfigurable
            public static let UUID = "2a27"
            public static let name = "Device Hardware Revision"
            public static let permissions: CBAttributePermissions       = [.Readable, .Writeable]
            public static let properties: CBCharacteristicProperties    = .Read
            public static let initialValue = BCSerDe.serialize("1.0")
            
        }
        
        public struct SoftwareRevision: BCCharacteristicConfigurable {
            
            // CharacteristicConfigurable
            public static let UUID = "2a28"
            public static let name = "Device Software Revision"
            public static let permissions: CBAttributePermissions       = [.Readable, .Writeable]
            public static let properties: CBCharacteristicProperties    = .Read
            public static let initialValue = BCSerDe.serialize("1.0")

        }
        
        public struct ManufacturerName: BCCharacteristicConfigurable {
            
            // CharacteristicConfigurable
            public static let UUID                                      = "2a29"
            public static let name                                      = "Device Manufacturer Name"
            public static let permissions: CBAttributePermissions       = [.Readable, .Writeable]
            public static let properties: CBCharacteristicProperties    = .Read
            public static let initialValue = BCSerDe.serialize("gnos.us")
            
        }
    }
    
    // MARK: - Battery Service -
    public struct BatteryService: BCServiceConfigurable {

        // ServiceConfigurable
        public static let UUID = "180f"
        public static let name = "Battery"
        public static let tag  = "BLESIGGATT"
        
        public struct Level: BCRawDeserializable, BCCharacteristicConfigurable, BCStringDeserializable {
            
            public let value: UInt8
            
            // CharacteristicConfigurable
            public static let UUID                                      = "2a19"
            public static let name                                      = "Battery Level"
            public static let permissions: CBAttributePermissions       = [.Readable, .Writeable]
            public static let properties: CBCharacteristicProperties    = [.Notify, .Read]
            public static let initialValue: NSData?                     = BCSerDe.serialize(UInt8(100))

            // RawDeserializable
            public var rawValue: UInt8 {
                return self.value
            }
            public init?(rawValue: UInt8) {
                self.value = rawValue
            }
            
            // StringDeserializable
            public static let stringValues = [String]()
            
            public var stringValue: [String: String] {
                return [Level.name:"\(self.value)"]
            }
            
            public init?(stringValue: [String: String]) {
                if let valueInit = uint8ValueFromStringValue(Level.name, values:stringValue) {
                    self.value = valueInit
                } else {
                    return nil
                }
            }

        }
    }

    // MARK: - Tx Power Service -
    public struct TxPowerService: BCServiceConfigurable {

        // ServiceConfigurable
        public static let UUID = "1804"
        public static let name = "Tx Power Level"
        public static let tag  = "BLESIGGATT"

        public struct Level: BCRawDeserializable, BCCharacteristicConfigurable, BCStringDeserializable {
            
            public let value : Int8
            
            // CharacteristicConfigurable
            public static let UUID                                      = "2a07"
            public static let name                                      = "Tx Power Level"
            public static let permissions: CBAttributePermissions       = [.Readable, .Writeable]
            public static let properties: CBCharacteristicProperties    = [.Notify, .Read]
            public static let initialValue: NSData?                     = BCSerDe.serialize(Int8(-40))
            
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
                if let valueInit = int8ValueFromStringValue(Level.name, values:stringValue) {
                    self.value = valueInit
                } else {
                    return nil
                }
            }

        }
    }
    
}

// MARK: - Profile Definition -
public class BLESIGGATTProfiles {
    
    public class func create () {
        
        let profileManager = BCProfileManager.sharedInstance
        
        // Device Information Service
        let deviceInformationService = BCConfiguredServiceProfile<BLESIGGATT.DeviceInformationService>()
        let deviceModelNumberCharacteristic = BCStringCharacteristicProfile<BLESIGGATT.DeviceInformationService.ModelNumber>()
        let deviceSerialNumberCharacteristic = BCStringCharacteristicProfile<BLESIGGATT.DeviceInformationService.SerialNumber>()
        let deviceFirmwareVersion = BCStringCharacteristicProfile<BLESIGGATT.DeviceInformationService.FirmwareRevision>()
        let deviceHardwareRevision = BCStringCharacteristicProfile<BLESIGGATT.DeviceInformationService.HardwareRevision>()
        let deviceSoftwareRevision = BCStringCharacteristicProfile<BLESIGGATT.DeviceInformationService.SoftwareRevision>()
        let deviceManufactureName = BCStringCharacteristicProfile<BLESIGGATT.DeviceInformationService.ManufacturerName>()
        
        deviceInformationService.addCharacteristic(deviceModelNumberCharacteristic)
        deviceInformationService.addCharacteristic(deviceSerialNumberCharacteristic)
        deviceInformationService.addCharacteristic(deviceFirmwareVersion)
        deviceInformationService.addCharacteristic(deviceHardwareRevision)
        deviceInformationService.addCharacteristic(deviceSoftwareRevision)
        deviceInformationService.addCharacteristic(deviceManufactureName)
        profileManager.addService(deviceInformationService)
        

        // Battery Service
        let batteryService = BCConfiguredServiceProfile<BLESIGGATT.BatteryService>()
        let batteryLevelCharcteristic = BCRawCharacteristicProfile<BLESIGGATT.BatteryService.Level>()
        
        batteryService.addCharacteristic(batteryLevelCharcteristic)
        profileManager.addService(batteryService)

        // Tx Power Service
        let txPowerService = BCConfiguredServiceProfile<BLESIGGATT.TxPowerService>()
        let txPowerLevel = BCRawCharacteristicProfile<BLESIGGATT.TxPowerService.Level>()
        
        txPowerService.addCharacteristic(txPowerLevel)
        profileManager.addService(txPowerService)
    }
}