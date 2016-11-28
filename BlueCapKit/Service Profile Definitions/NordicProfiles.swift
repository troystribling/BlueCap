//
//  NordicProfiles.swift
//  BlueCap
//
//  Created by Troy Stribling on 7/25/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import Foundation
import CoreBluetooth

// MARK: - Nordic -
public struct Nordic {

    // MARK - Nordic Device Temperature Service -
    public struct DeviceTemperatureService : ServiceConfigurable {
        
        // ServiceConfigurable
        public static let uuid  = "2f0a0003-69aa-f316-3e78-4194989a6c1a"
        public static let name  = "Nordic Device Temperature"
        public static let tag   = "Nordic"
        
        public struct Data : RawDeserializable, CharacteristicConfigurable, StringDeserializable {

            fileprivate let temperatureRaw: Int16
            public let temperature: Double

            fileprivate static func valueFromRaw(_ rawValue:Int16) -> Double {
                return Double(rawValue)/4.0
            }

            // CharacteristicConfigurable
            public static let uuid                                      = "2f0a0004-69aa-f316-3e78-4194989a6c1a"
            public static let name                                      = "Device Temperature Data"
            public static let properties: CBCharacteristicProperties    = [.read, .notify]
            public static let permissions: CBAttributePermissions       = [.readable, .writeable]
            public static let initialValue: Foundation.Data?                     = SerDe.serialize(Int16(100))

            // RawDeserializable
            public var rawValue: Int16 {
                return self.temperatureRaw
            }
            
            public init?(rawValue: Int16) {
                self.temperatureRaw = rawValue
                self.temperature = Data.valueFromRaw(self.temperatureRaw)
            }
            
            // StringDeserializable
            public static let stringValues = [String]()
            
            public init?(stringValue: [String: String]) {
                let temperatureRawInit = int16ValueFromStringValue("temperatureRaw", values: stringValue)
                if temperatureRawInit != nil {
                    self.temperatureRaw = temperatureRawInit!
                    self.temperature = Data.valueFromRaw(self.temperatureRaw)
                } else {
                    return nil
                }
            }
            public var stringValue: [String: String] {
                return ["temperatureRaw":"\(temperatureRaw)", "temperature":"\(temperature)"]
            }
        }
    }

    // MARK: - Nordic BLE Address Service -
    public struct BLEAddressService: ServiceConfigurable {
        
        // ServiceConfigurable
        public static let uuid = "2f0a0005-69aa-f316-3e78-4194989a6c1a"
        public static let name = "Nordic BLE Address"
        public static let tag   = "Nordic"

        public struct Address: RawArrayDeserializable, CharacteristicConfigurable, StringDeserializable {
            
            public let addr1: UInt8
            public let addr2: UInt8
            public let addr3: UInt8
            public let addr4: UInt8
            public let addr5: UInt8
            public let addr6: UInt8

            // CharacteristicConfigurable
            public static let uuid                                      = "2f0a0006-69aa-f316-3e78-4194989a6c1a"
            public static let name                                      = "BLE Addresss"
            public static let properties: CBCharacteristicProperties    = [.read, .notify]
            public static let permissions: CBAttributePermissions       = [.readable, .writeable]
            public static let initialValue: Data?                     = SerDe.serialize(Int16(100))

            // RawArrayDeserializable
            public static let size = 6

            public var rawValue: [UInt8] {
                return [self.addr1, self.addr2, self.addr3, self.addr4, self.addr5, self.addr5]
            }

            public init?(rawValue: [UInt8]) {
                if rawValue.count == 6 {
                    self.addr1 = rawValue[0]
                    self.addr2 = rawValue[1]
                    self.addr3 = rawValue[2]
                    self.addr4 = rawValue[3]
                    self.addr5 = rawValue[4]
                    self.addr6 = rawValue[5]
                } else {
                    return nil
                }
            }
            
            // StringDeserializable
            public static let stringValues = [String]()
            
            public var stringValue: [String: String] {
                return ["addr1":"\(addr1)", "addr2":"\(addr2)", "addr3":"\(addr3)",
                        "addr4":"\(addr4)", "addr5":"\(addr5)", "addr6":"\(addr6)"]
            }
            
            public init?(stringValue: [String: String]) {
                if let addr1Init = uint8ValueFromStringValue("addr1", values: stringValue),
                       let addr2Init = uint8ValueFromStringValue("addr2", values: stringValue),
                       let addr3Init = uint8ValueFromStringValue("addr3", values: stringValue),
                       let addr4Init = uint8ValueFromStringValue("addr4", values: stringValue),
                       let addr5Init = uint8ValueFromStringValue("addr5", values: stringValue),
                       let addr6Init = uint8ValueFromStringValue("addr6", values: stringValue) {
                    self.addr1 = addr1Init
                    self.addr2 = addr2Init
                    self.addr3 = addr3Init
                    self.addr4 = addr4Init
                    self.addr5 = addr5Init
                    self.addr6 = addr6Init
                } else {
                    return nil
                }
            }

        }
        
        public enum AddressType: UInt8, RawDeserializable, StringDeserializable, CharacteristicConfigurable  {
            public typealias RawType = UInt8

            case unknown                    = 0
            case `public`                   = 1
            case randomStatic               = 2
            case randomPrivateResolvable    = 3
            case randomPrivateUnresolvable  = 4
            
            // CharacteristicConfigurable
            public static let uuid                                      = "2f0a0007-69aa-f316-3e78-4194989a6c1a"
            public static let name                                      = "BLE Address Type"
            public static let properties: CBCharacteristicProperties    = [.read]
            public static let permissions: CBAttributePermissions       = [.readable, .writeable]
            public static let initialValue: Data?                     = SerDe.serialize(AddressType.public)


            // StringDeserializable
            public static let stringValues = ["Unknown", "Public", "RandomStatic",
                                              "RandomPrivateResolvable", "RandomPrivateUnresolvable"]

            public var stringValue: [String: String] {
                switch self {
                case .unknown:
                    return [AddressType.name: "Unknown"]
                case .public:
                    return [AddressType.name: "Public"]
                case .randomStatic:
                    return [AddressType.name: "RandomStatic"]
                case .randomPrivateResolvable:
                    return [AddressType.name: "RandomPrivateResolvable"]
                case .randomPrivateUnresolvable:
                    return [AddressType.name: "RandomPrivateUnresolvable"]
                }
            }

            public init?(stringValue: [String: String]) {
                if let value = stringValue[AddressType.name] {
                    switch value {
                    case "Unknown":
                        self = AddressType.unknown
                    case "Public":
                        self = AddressType.public
                    case "RandomStatic":
                        self = AddressType.randomStatic
                    case "RandomPrivateResolvable":
                        self = AddressType.randomPrivateResolvable
                    case "RandomPrivateUnresolvable":
                        self = AddressType.randomPrivateUnresolvable
                    default:
                        return nil
                   
                    }
                } else {
                    return nil
                }
            }
        }
    }
}

// MARK: - Profile Definition -
public class NordicProfiles {
    
    public static func create(profileManager: ProfileManager) {
        
        // Nordic Device Temperature Service
        let temperatureService = ConfiguredServiceProfile<Nordic.DeviceTemperatureService>()
        let temperatureDataCharcteristic = RawCharacteristicProfile<Nordic.DeviceTemperatureService.Data>()

        temperatureService.addCharacteristic(temperatureDataCharcteristic)
        profileManager.addService(temperatureService)

        // Nordic BLE Address Service
        let bleAddressService = ConfiguredServiceProfile<Nordic.BLEAddressService>()
        let bleAddressCharacteristic = RawArrayCharacteristicProfile<Nordic.BLEAddressService.Address>()
        let bleAddressTypeCharacteristic = RawCharacteristicProfile<Nordic.BLEAddressService.AddressType>()
        
        bleAddressService.addCharacteristic(bleAddressCharacteristic)
        bleAddressService.addCharacteristic(bleAddressTypeCharacteristic)
        profileManager.addService(bleAddressService)
    }
}
