//
//  TISensorTagServiceProfiles.swift
//  BlueCap
//
//  Created by Troy Stribling on 7/6/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation
import BlueCapKit

struct TISensorTag {

    //***************************************************************************************************
    // Accelerometer Service
    //***************************************************************************************************
    struct AccelerometerService {
        static let uuid = "F000AA10-0451-4000-B000-000000000000"
        static let name = "TI Accelerometer Service"
        // Accelerometer Data
        struct Data {
            static let uuid = "F000AA11-0451-4000-B000-000000000000"
            static let name = "Accelerometer Data"
            struct Values  : DeserializedStruct {
                var xRaw:Int8
                var yRaw:Int8
                var zRaw:Int8
                var x:Float
                var y:Float
                var z:Float
                static func fromRawValues(rawValues:[Int8]) -> Values? {
                    let values = self.valuesFromRaw(rawValues)
                    return Values(xRaw:rawValues[0], yRaw:rawValues[1], zRaw:rawValues[2], x:values[0], y:values[1], z:values[2])
                }
                static func fromStrings(stringValues:Dictionary<String, String>) -> Values? {
                    let xRaw = self.valueFromString("xRaw", values:stringValues)
                    let yRaw = self.valueFromString("yRaw", values:stringValues)
                    let zRaw = self.valueFromString("zRaw", values:stringValues)
                    if xRaw && yRaw && zRaw {
                        let values = self.valuesFromRaw([xRaw!, yRaw!, zRaw!])
                        return Values(xRaw:xRaw!, yRaw:yRaw!, zRaw:zRaw!, x:values[0], y:values[1], z:values[2])
                    } else {
                        return nil
                    }
                }
                static func valuesFromRaw(values:[Int8]) -> [Float] {
                    return [-Float(values[0])/64.0, -Float(values[1])/64.0, Float(values[2]) / 64.0]

                }
                static func valueFromString(name:String, values:Dictionary<String,String>) -> Int8? {
                    if let value = values[name]?.toInt() {
                        if value < -128 {
                            return Int8(-128)
                        } else if value > 127 {
                            return Int8(127)
                        } else {
                            return Int8(value)
                        }
                    } else {
                        return nil
                    }
                }
                var stringValues : Dictionary<String,String> {
                    return ["x":"\(x)", "y":"\(y)", "z":"\(z)", "xRaw":"\(xRaw)", "yRaw":"\(yRaw)", "zRaw":"\(zRaw)"]
                }
                func toRawValues() -> [Int8] {
                    return [xRaw, yRaw, zRaw]
                }

            }
        }
        // Accelerometer Enabled
        struct Enabled {
            static let uuid = "F000AA12-0451-4000-B000-000000000000"
            static let name = "Accelerometer Enabled"
            enum Value: UInt8, DeserializedEnum {
                case No     = 0
                case Yes    = 1
                static func fromRaw(value:UInt8) -> Value? {
                    switch value {
                    case 0:
                        return Value.No
                    case 1:
                        return Value.Yes
                    default:
                        return nil
                    }
                }
                static func fromString(value:String) -> Value? {
                    switch value {
                    case "No":
                        return Value.No
                    case "Yes":
                        return Value.Yes
                    default:
                        return nil
                    }
                }
                static func stringValues() -> [String] {
                    return ["No", "Yes"]
                }
                var stringValue : String {
                    switch self {
                    case .No:
                        return "No"
                    case .Yes:
                        return "Yes"
                    }
                }
                func toRaw() -> UInt8 {
                    switch self {
                    case .No:
                        return 0
                    case .Yes:
                        return 1
                    }
                }
            }
        }
        // Accelerometer Update Period
        struct UpdatePeriod {
            static let uuid = "F000AA13-0451-4000-B000-000000000000"
            static let name = "Accelerometer Update Period"
        }
    }
}

class TISensorTagServiceProfiles {
    
    class func create() {

        let profileManage = ProfileManager.sharedInstance()
        
        // Accelerometer Service
        profileManage.addService(ServiceProfile(uuid:TISensorTag.AccelerometerService.uuid, name:TISensorTag.AccelerometerService.name){(serviceProfile:ServiceProfile) in
            // Accelerometer Data
            serviceProfile.addCharacteristic(StructCharacteristicProfile<TISensorTag.AccelerometerService.Data.Values>(uuid:TISensorTag.AccelerometerService.Data.uuid, name:TISensorTag.AccelerometerService.Data.name))
            // Accelerometer Enabled
            serviceProfile.addCharacteristic(EnumCharacteristicProfile<TISensorTag.AccelerometerService.Enabled.Value>(
                uuid:TISensorTag.AccelerometerService.Enabled.uuid, name:TISensorTag.AccelerometerService.Enabled.name){(characteristicProfile:EnumCharacteristicProfile<TISensorTag.AccelerometerService.Enabled.Value>) in
                    characteristicProfile.afterDiscovered(){(characteristic:Characteristic) in
                        characteristic.write(TISensorTag.AccelerometerService.Enabled.Value.Yes, afterWriteSuccessCallback:{})
                    }
                })
            // Accelerometer Update Period
            serviceProfile.addCharacteristic(DeserializedCharacteristicProfile<UInt8>(uuid:TISensorTag.AccelerometerService.UpdatePeriod.uuid, name:TISensorTag.AccelerometerService.UpdatePeriod.name))
        })
        
    }
}
