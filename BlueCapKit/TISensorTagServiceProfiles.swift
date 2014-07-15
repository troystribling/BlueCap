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

    // Accelerometer Service
    struct AccelerometerService {
        static let uuid = "F000AA10-0451-4000-B000-000000000000"
        static let name = "TI Accelerometer Service"
        // Accelerometer Data
        struct Data {
            static let uuid = "F000AA11-0451-4000-B000-000000000000"
            static let name = "Accelerometer Data"
            struct Values  : DeserializedStruct {
                var x:Int8
                var y:Int8
                var z:Int8
                static func fromNativeArray(values:[Int8]) -> Values? {
                    return Values(x:values[0], y:values[1], z:values[2])
                }
                static func fromStrings(values:Dictionary<String, String>) -> Values? {
                    let x = self.valueFromString("x", values:values)
                    let y = self.valueFromString("y", values:values)
                    let z = self.valueFromString("z", values:values)
                    if x && y && z {
                        return Values(x:x!, y:y!, z:z!)
                    } else {
                        return nil
                    }
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
                    return ["x":"\(x)", "y":"\(y)", "z":"\(z)"]
                }
                func arrayValue() -> [Int8] {
                    return [x, y, z]
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
                static func fromNative(value:UInt8) -> Value? {
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
                func toNative() -> UInt8 {
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
            serviceProfile.addCharacteristic(StructCharacteristicProfile<TISensorTag.AccelerometerService.Data.Values>(
                uuid:TISensorTag.AccelerometerService.Data.uuid, name:TISensorTag.AccelerometerService.Data.name){(cheracteristiceProfile:StructCharacteristicProfile<TISensorTag.AccelerometerService.Data.Values>) in
                })
            // Accelerometer Enabled
            serviceProfile.addCharacteristic(EnumCharacteristicProfile<TISensorTag.AccelerometerService.Enabled.Value>(
                uuid:TISensorTag.AccelerometerService.Enabled.uuid, name:TISensorTag.AccelerometerService.Enabled.name){(CharacteristicProfile:EnumCharacteristicProfile<TISensorTag.AccelerometerService.Enabled.Value>) in
                })
            // Accelerometer Update Period
            serviceProfile.addCharacteristic(DeserializedCharacteristicProfile<UInt8>(
                uuid:TISensorTag.AccelerometerService.UpdatePeriod.uuid, name:TISensorTag.AccelerometerService.UpdatePeriod.name){(characteristicProfile:DeserializedCharacteristicProfile<UInt8>) in
                })
        })
        
    }
}
