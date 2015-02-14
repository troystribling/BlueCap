//
//  NordicProfiles.swift
//  BlueCap
//
//  Created by Troy Stribling on 7/25/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation
import CoreBluetooth
import BlueCapKit

//public struct Nordic {
//
//    //***************************************************************************************************
//    // Nordic Device Temperature Service
//    public struct DeviceTemperatureService : ServiceConfigurable {
//        
//        // ServiceConfigurable
//        public static let uuid  = "2f0a0003-69aa-f316-3e78-4194989a6c1a"
//        public static let name  = "Nordic Device Temperature"
//        public static let tag   = "Nordic"
//        
//        public struct Data : RawDeserializable, CharacteristicConfigurable, StringDeserializable {
//
//            private let temperatureRaw  : Int16
//            public let temperature      : Double
//
//            private static func valueFromRaw(rawValue:Int16) -> Double {
//                return Double(rawValue)/4.0
//            }
//
//            // CharacteristicConfigurable
//            public static let uuid                      = "2f0a0004-69aa-f316-3e78-4194989a6c1a"
//            public static let name                      = "Device Temperature Data"
//            public static let properties                = CBCharacteristicProperties.Read | CBCharacteristicProperties.Notify
//            public static let permissions               = CBAttributePermissions.Readable | CBAttributePermissions.Writeable
//            public static let initialValue : NSData?    = Serde.serialize(Int16(100))
//
//            // RawDeserializable
//            public var rawValue : Int16 {
//                return self.temperatureRaw
//            }
//            
//            public init?(rawValue:Int16) {
//                self.temperatureRaw = rawValue
//                self.temperature = Data.valueFromRaw(self.temperatureRaw)
//            }
//            
//            // StringDeserializable
//            public static let stringValues = [String]()
//            
//            public init?(stringValue:[String:String]) {
//                let temperatureRawInit = int16ValueFromStringValue("temperatureRaw", stringValue)
//                if temperatureRawInit != nil {
//                    self.temperatureRaw = temperatureRawInit!
//                    self.temperature = Data.valueFromRaw(self.temperatureRaw)
//                } else {
//                    return nil
//                }
//            }
//            public var stringValue : [String:String] {
//                return ["temperatureRaw":"\(temperatureRaw)", "temperature":"\(temperature)"]
//            }
//        }
//    }
//
//    //***************************************************************************************************
//    // Nordic BLE Address Service
//    public struct BLEAddressService : ServiceConfigurable {
//        
//        // ServiceConfigurable
//        public static let uuid = "2f0a0005-69aa-f316-3e78-4194989a6c1a"
//        public static let name = "Nordic BLE Address"
//        public static let tag   = "Nordic"
//
//        public struct Address : RawArrayDeserializable, CharacteristicConfigurable, StringDeserializable {
//            
//            public let addr1 : UInt8
//            public let addr2 : UInt8
//            public let addr3 : UInt8
//            public let addr4 : UInt8
//            public let addr5 : UInt8
//            public let addr6 : UInt8
//
//            // CharacteristicConfigurable
//            public static let uuid                      = "2f0a0006-69aa-f316-3e78-4194989a6c1a"
//            public static let name                      = "BLE Addresss"
//            public static let properties                = CBCharacteristicProperties.Read | CBCharacteristicProperties.Notify
//            public static let permissions               = CBAttributePermissions.Readable | CBAttributePermissions.Writeable
//            public static let initialValue : NSData?    = Serde.serialize(Int16(100))
//
//            // RawArrayDeserializable
//            public var rawValue : [UInt8] {
//                return [self.addr1, self.addr2, self.addr3, self.addr4, self.addr5, self.addr5]
//            }
//
//            public init?(rawValue:[UInt8]) {
//                if rawValue.count == 6 {
//                    self.addr1 = rawValue[0]
//                    self.addr2 = rawValue[1]
//                    self.addr3 = rawValue[2]
//                    self.addr4 = rawValue[3]
//                    self.addr5 = rawValue[4]
//                    self.addr6 = rawValue[5]
//                } else {
//                    return nil
//                }
//            }
//            
//            // StringDeserializable
//            public static let stringValues = [String]()
//            
//            public var stringValue : [String:String] {
//                return ["addr1":"\(addr1)", "addr2":"\(addr2)", "addr3":"\(addr3)",
//                        "addr4":"\(addr4)", "addr5":"\(addr5)", "addr6":"\(addr6)"]
//            }
//            
//            public init?(stringValue:[String:String]) {
//                let addr1Init = uint8ValueFromStringValue("addr1", stringValue)
//                let addr2Init = uint8ValueFromStringValue("addr2", stringValue)
//                let addr3Init = uint8ValueFromStringValue("addr3", stringValue)
//                let addr4Init = uint8ValueFromStringValue("addr4", stringValue)
//                let addr5Init = uint8ValueFromStringValue("addr5", stringValue)
//                let addr6Init = uint8ValueFromStringValue("addr6", stringValue)
//                if addr1Init != nil && addr2Init != nil && addr3Init != nil && addr4Init != nil && addr5Init != nil && addr6Init != nil {
//                    self.addr1 = addr1Init!
//                    self.addr2 = addr2Init!
//                    self.addr3 = addr3Init!
//                    self.addr4 = addr4Init!
//                    self.addr5 = addr5Init!
//                    self.addr6 = addr6Init!
//                } else {
//                    return nil
//                }
//            }
//
//        }
//        
//        public enum AddressType : UInt8, RawDeserializable, StringDeserializable, CharacteristicConfigurable  {
//            
//            case Unknown                    = 0
//            case Public                     = 1
//            case RandomStatic               = 2
//            case RandomPrivateResolvable    = 3
//            case RandomPrivateUnresolvable  = 4
//            
//            // CharacteristicConfigurable
//            public static let uuid                      = "2f0a0007-69aa-f316-3e78-4194989a6c1a"
//            public static let name                      = "BLE Address Type"
//            public static let properties                = CBCharacteristicProperties.Read
//            public static let permissions               = CBAttributePermissions.Readable | CBAttributePermissions.Writeable
//            public static let initialValue : NSData?    = Serde.serialize(AddressType.Public)
//
//
//            // StringDeserializable
//            public static let stringValues = ["Unknown", "Public", "RandomStatic",
//                                              "RandomPrivateResolvable", "RandomPrivateUnresolvable"]
//
//            public var stringValue : [String:String] {
//                switch self {
//                case .Unknown:
//                    return [AddressType.name:"Unknown"]
//                case .Public:
//                    return [AddressType.name:"Public"]
//                case .RandomStatic:
//                    return [AddressType.name:"RandomStatic"]
//                case .RandomPrivateResolvable:
//                    return [AddressType.name:"RandomPrivateResolvable"]
//                case .RandomPrivateUnresolvable:
//                    return [AddressType.name:"RandomPrivateUnresolvable"]
//                }
//            }
//
//            public init?(stringValue:[String:String]) {
//                if let value = stringValue[AddressType.name] {
//                    switch value {
//                    case "Unknown":
//                        self = AddressType.Unknown
//                    case "Public":
//                        self = AddressType.Public
//                    case "RandomStatic":
//                        self = AddressType.RandomStatic
//                    case "RandomPrivateResolvable":
//                        self = AddressType.RandomPrivateResolvable
//                    case "RandomPrivateUnresolvable":
//                        self = AddressType.RandomPrivateUnresolvable
//                    default:
//                        return nil
//                   
//                    }
//                } else {
//                    return nil
//                }
//            }
//        }
//    }
//}
//
//
//public class NordicProfiles {
//    
//    public class func create() {
//        
//        let profileManager = ProfileManager.sharedInstance
//        
//        //***************************************************************************************************
//        // Nordic Device Temperature Service
//        let temperatureService = ConfiguredServiceProfile<Nordic.DeviceTemperatureService>()
//        let temperatureDataCharcteristic = RawCharacteristicProfile<Nordic.DeviceTemperatureService.Data>()
//
//        temperatureService.addCharacteristic(temperatureDataCharcteristic)
//        profileManager.addService(temperatureService)
//
//        //***************************************************************************************************
//        // Nordic BLE Address Service
//        let bleAddressService = ConfiguredServiceProfile<Nordic.BLEAddressService>()
//        let bleAddressCharacteristic = RawArrayCharacteristicProfile<Nordic.BLEAddressService.Address>()
//        let bleAddressTypeCharacteristic = RawCharacteristicProfile<Nordic.BLEAddressService.AddressType>()
//        
//        bleAddressService.addCharacteristic(bleAddressCharacteristic)
//        bleAddressService.addCharacteristic(bleAddressTypeCharacteristic)
//        profileManager.addService(bleAddressService)
//    }
//}
