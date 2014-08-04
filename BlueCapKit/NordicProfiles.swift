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

public struct Nordic {
    
    //***************************************************************************************************
    // Nordic Device Temperature Service
    //***************************************************************************************************
    struct DeviceTemperatureService {
        static let uuid = "2f0a0003-69aa-f316-3e78-4194989a6c1a"
        static let name = "Noric Device Temperature"
        struct Data {
            static let uuid = "2f0a0004-69aa-f316-3e78-4194989a6c1a"
            static let name = "Device Temperature Data"
            struct Value : DeserializedStruct {
                var temperatureRaw  : Int16
                var temperature     : Double
                static func fromRawValues(rawValues:[Int16]) -> Value? {
                    if rawValues.count == 1 {
                        return Value(temperatureRaw:rawValues[0], temperature:self.valueFromRaw(rawValues[0]))
                    } else {
                        return nil
                    }
                }
                static func fromStrings(stringValues:Dictionary<String, String>) -> Value? {
                    let temperatureRaw = BlueCap.int16ValueFromStringValue("temperatureRaw", values:stringValues)
                    if temperatureRaw {
                        return Value(temperatureRaw:temperatureRaw!, temperature:self.valueFromRaw(temperatureRaw!))
                    } else {
                        return nil
                    }
                }
                static func valueFromRaw(rawValue:Int16) -> Double {
                    return Double(rawValue)/4.0
                }
                var stringValues : Dictionary<String,String> {
                    return ["temperatureRaw":"\(temperatureRaw)", "temperature":"\(temperature)"]
                }
                func toRawValues() -> [Int16] {
                    return [temperatureRaw]
                }
            }
        }
    }

    //***************************************************************************************************
    // Nordic BLE Address Service
    //***************************************************************************************************
    struct BLEAddressService {
        static let uuid = "2f0a0005-69aa-f316-3e78-4194989a6c1a"
        static let name = "Noric BLE Address"
        struct Address {
            static let uuid = "2f0a0006-69aa-f316-3e78-4194989a6c1a"
            static let name = "BLE Addresss"
            struct Value : DeserializedStruct {
                var addr1 : UInt8
                var addr2 : UInt8
                var addr3 : UInt8
                var addr4 : UInt8
                var addr5 : UInt8
                var addr6 : UInt8
                static func fromRawValues(rawValues:[UInt8]) -> Value? {
                    if rawValues.count == 6 {
                        return Value(addr1:rawValues[0], addr2:rawValues[1], addr3:rawValues[2],
                                     addr4:rawValues[3], addr5:rawValues[4], addr6:rawValues[5])
                    } else {
                        return nil
                    }
                }
                static func fromStrings(stringValues:Dictionary<String, String>) -> Value? {
                    let addr1 = BlueCap.uint8ValueFromStringValue("addr1", values:stringValues)
                    let addr2 = BlueCap.uint8ValueFromStringValue("addr2", values:stringValues)
                    let addr3 = BlueCap.uint8ValueFromStringValue("addr3", values:stringValues)
                    let addr4 = BlueCap.uint8ValueFromStringValue("addr4", values:stringValues)
                    let addr5 = BlueCap.uint8ValueFromStringValue("addr5", values:stringValues)
                    let addr6 = BlueCap.uint8ValueFromStringValue("addr6", values:stringValues)
                    if addr1 && addr2 && addr3 && addr4 && addr5 && addr6 {
                        return Value(addr1:addr1!, addr2:addr2!, addr3:addr3!, addr4:addr4!, addr5:addr5!, addr6:addr6!)
                    } else {
                        return nil
                    }
                }
                var stringValues : Dictionary<String,String> {
                    return ["addr1":"\(addr1)", "addr2":"\(addr2)", "addr3":"\(addr3)",
                            "addr4":"\(addr4)", "addr5":"\(addr5)", "addr6":"\(addr6)"]
                }
                func toRawValues() -> [UInt8] {
                    return [addr1, addr2, addr3, addr4, addr5, addr5]
                }
            }
        }
        struct AddressType {
            static let uuid = "2f0a0007-69aa-f316-3e78-4194989a6c1a"
            static let name = "BLE Address Type"
            enum Value : UInt8, DeserializedEnum {
                case Unknown                    = 0
                case Public                     = 1
                case RandomStatic               = 2
                case RandomPrivateResolvable    = 3
                case RandomPrivateUnresolvable  = 4
                static func fromRaw(rawValue:UInt8) -> Value? {
                    switch rawValue {
                    case 0:
                        return Value.Unknown
                    case 1:
                        return Value.Public
                    case 2:
                        return Value.RandomStatic
                    case 3:
                        return Value.RandomPrivateResolvable
                    case 4:
                        return Value.RandomPrivateUnresolvable
                    default:
                        return nil
                    }
                }
                static func fromString(stringValue:String) -> Value? {
                    switch stringValue {
                    case "Unknown":
                        return Value.Unknown
                    case "Public":
                        return Value.Public
                    case "RandomStatic":
                        return Value.RandomStatic
                    case "RandomPrivateResolvable":
                        return Value.RandomPrivateResolvable
                    case "RandomPrivateUnresolvable":
                        return Value.RandomPrivateUnresolvable
                    default:
                        return nil
                    }
                }
                static func stringValues() -> [String] {
                    return ["Unknown", "Public", "RandomStatic", "RandomPrivateResolvable", "RandomPrivateUnresolvable"]
                }
                var stringValue : String {
                switch self {
                case .Unknown:
                    return "Unknown"
                case .Public:
                    return "Public"
                case .RandomStatic:
                    return "RandomStatic"
                case .RandomPrivateResolvable:
                    return "RandomPrivateResolvable"
                case .RandomPrivateUnresolvable:
                    return "RandomPrivateUnresolvable"
                    }
                }
                func toRaw() -> UInt8 {
                    switch self {
                    case .Unknown:
                        return 0
                    case .Public:
                        return 1
                    case .RandomStatic:
                        return 2
                    case .RandomPrivateResolvable:
                        return 3
                    case .RandomPrivateUnresolvable:
                        return 4
                    }
                }
            }
        }
    }
}

public class NordicProfiles {
    
    public class func create() {
        
        let profileManager = ProfileManager.sharedInstance()
        
        //***************************************************************************************************
        // Nordic Device Temperature Service
        //***************************************************************************************************
        profileManager.addService(ServiceProfile(uuid:Nordic.DeviceTemperatureService.uuid, name:Nordic.DeviceTemperatureService.name){(serviceProfile) in
            // Device Temperature Data
            serviceProfile.addCharacteristic(StructCharacteristicProfile<Nordic.DeviceTemperatureService.Data.Value>(uuid:Nordic.DeviceTemperatureService.Data.uuid, name:Nordic.DeviceTemperatureService.Data.name)
                {(characteristicProfile) in
                    characteristicProfile.endianness = .Big
                    characteristicProfile.initialValue = NSData.serializeArrayToBigEndian(Nordic.DeviceTemperatureService.Data.Value.fromRawValues([100])!.toRawValues())
                    characteristicProfile.properties = CBCharacteristicProperties.Read | CBCharacteristicProperties.Write
                })
        })

        //***************************************************************************************************
        // Nordic BLE Address Service
        //***************************************************************************************************
        profileManager.addService(ServiceProfile(uuid:Nordic.BLEAddressService.uuid, name:Nordic.BLEAddressService.name){(serviceProfile) in
            // BLE Address Address
            serviceProfile.addCharacteristic(StructCharacteristicProfile<Nordic.BLEAddressService.Address.Value>(uuid:Nordic.BLEAddressService.Address.uuid, name:Nordic.BLEAddressService.Address.name)
                {(characteristicProfile) in
                    characteristicProfile.initialValue = NSData.serializeArray(Nordic.BLEAddressService.Address.Value.fromRawValues([10, 11, 12, 13, 14, 15])!.toRawValues())
                    characteristicProfile.properties = CBCharacteristicProperties.Read
                })
            // BLE Address Type
            serviceProfile.addCharacteristic(EnumCharacteristicProfile<Nordic.BLEAddressService.AddressType.Value>(uuid:Nordic.BLEAddressService.AddressType.uuid, name:Nordic.BLEAddressService.AddressType.name)
                {(characteristicProfile) in
                    characteristicProfile.initialValue = NSData.serialize(Nordic.BLEAddressService.AddressType.Value.Public.toRaw())
                    characteristicProfile.properties = CBCharacteristicProperties.Read
                })
        })

    }
}
