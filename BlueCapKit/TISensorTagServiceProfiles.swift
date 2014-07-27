//
//  TISensorTagServiceProfiles.swift
//  BlueCap
//
//  Created by Troy Stribling on 7/6/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation
import CoreBluetooth
import BlueCapKit

struct TISensorTag {

    //***************************************************************************************************
    // Accelerometer Service
    //***************************************************************************************************
    struct AccelerometerService {
        static let uuid = "F000AA10-0451-4000-B000-000000000000"
        static let name = "TI Accelerometer"
        // Accelerometer Data
        struct Data {
            static let uuid = "F000AA11-0451-4000-B000-000000000000"
            static let name = "Accelerometer Data"
            struct Value : DeserializedStruct {
                var xRaw:Int8
                var yRaw:Int8
                var zRaw:Int8
                var x:Float
                var y:Float
                var z:Float
                static func fromRawValues(rawValues:[Int8]) -> Value? {
                    let values = self.valuesFromRaw(rawValues)
                    return Value(xRaw:rawValues[0], yRaw:rawValues[1], zRaw:rawValues[2], x:values[0], y:values[1], z:values[2])
                }
                static func fromStrings(stringValues:Dictionary<String, String>) -> Value? {
                    let xRaw = self.valueFromString("xRaw", values:stringValues)
                    let yRaw = self.valueFromString("yRaw", values:stringValues)
                    let zRaw = self.valueFromString("zRaw", values:stringValues)
                    if xRaw && yRaw && zRaw {
                        let values = self.valuesFromRaw([xRaw!, yRaw!, zRaw!])
                        return Value(xRaw:xRaw!, yRaw:yRaw!, zRaw:zRaw!, x:values[0], y:values[1], z:values[2])
                    } else {
                        return nil
                    }
                }
                static func valuesFromRaw(values:[Int8]) -> [Float] {
                    return [-Float(values[0])/64.0, -Float(values[1])/64.0, Float(values[2])/64.0]
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
        }
        // Accelerometer Update Period
        struct UpdatePeriod {
            static let uuid = "F000AA13-0451-4000-B000-000000000000"
            static let name = "Accelerometer Update Period"
        }
    }
    
    //***************************************************************************************************
    // Magnetometer Service: units are uT
    //***************************************************************************************************
    struct MagnetometerService {
        static let uuid = "F000AA30-0451-4000-B000-000000000000"
        static let name = "TI Magnetometer"
        struct Data {
            static let uuid = "f000aa31-0451-4000-b000-000000000000"
            static let name = "Magnetometer Data"
            struct Value : DeserializedStruct {
                var xRaw    : Int16
                var yRaw    : Int16
                var zRaw    : Int16
                var x       : Double
                var y       : Double
                var z       : Double
                static func fromRawValues(rawValues:[Int16]) -> Value? {
                    let values = self.valuesFromRaw(rawValues)
                    return Value(xRaw:rawValues[0], yRaw:rawValues[1], zRaw:rawValues[2], x:values[0], y:values[1], z:values[2])
                }
                static func fromStrings(stringValues:Dictionary<String, String>) -> Value? {
                    let xRaw = self.valueFromString("xRaw", values:stringValues)
                    let yRaw = self.valueFromString("yRaw", values:stringValues)
                    let zRaw = self.valueFromString("zRaw", values:stringValues)
                    if xRaw && yRaw && zRaw {
                        let values = self.valuesFromRaw([xRaw!, yRaw!, zRaw!])
                        return Value(xRaw:xRaw!, yRaw:yRaw!, zRaw:zRaw!, x:values[0], y:values[1], z:values[2])
                    } else {
                        return nil
                    }
                }
                static func valuesFromRaw(values:[Int16]) -> [Double] {
                    return [-Double(values[0])*2000.0/65536.0, -Double(values[1])*2000.0/65536.0, Double(values[2])*2000.0/65536.0]
                }
                static func valueFromString(name:String, values:Dictionary<String,String>) -> Int16? {
                    if let value = values[name]?.toInt() {
                        if value < -32768 {
                            return Int16(-32768)
                        } else if value > 32767 {
                            return Int16(32767)
                        } else {
                            return Int16(value)
                        }
                    } else {
                        return nil
                    }
                }
                var stringValues : Dictionary<String,String> {
                    return ["x":"\(x)", "y":"\(y)", "z":"\(z)", "xRaw":"\(xRaw)", "yRaw":"\(yRaw)", "zRaw":"\(zRaw)"]
                }
                func toRawValues() -> [Int16] {
                    return [xRaw, yRaw, zRaw]
                }
            }
        }
        struct Enabled {
            static let uuid = "f000aa32-0451-4000-b000-000000000000"
            static let name = "Magnetometer Enabled"
        }
        struct UpdatePeriod {
            static let uuid = "f000aa33-0451-4000-b000-000000000000"
            static let name = "Magnetometer Update Period"
        }
    }

    //***************************************************************************************************
    // Gyroscope Service
    //***************************************************************************************************
    struct GyroscopeService {
        static let uuid = "F000AA50-0451-4000-B000-000000000000"
        static let name = "TI Gyroscope"
        struct Data {
            static let uuid = "f000aa51-0451-4000-b000-000000000000"
            static let name = "Gyroscope Data"
        }
        struct Enabled {
            static let uuid = "f000aa52-0451-4000-b000-000000000000"
            static let name = "Gyroscope Enabled"
        }
    }

    //***************************************************************************************************
    // Temperature Service
    //***************************************************************************************************
    struct TemperatureService {
        static let uuid = "F000AA00-0451-4000-B000-000000000000"
        static let name = "TI Temperature"
        struct Data {
            static let uuid = "f000aa01-0451-4000-b000-000000000000"
            static let name = "Temperature Data"
        }
        struct Enabled {
            static let uuid = "f000aa02-0451-4000-b000-000000000000"
            static let name = "Temperature Enabled"
        }
    }

    //***************************************************************************************************
    // Barometer Service
    //***************************************************************************************************
    struct BarometerService {
        static let uuid = "F000AA40-0451-4000-B000-000000000000"
        static let name = "TI Barometer"
        struct Data {
            static let uuid = "f000aa41-0451-4000-b000-000000000000"
            static let name = "Baraometer Data"
        }
        struct Calibration {
            static let uuid = "f000aa42-0451-4000-b000-000000000000"
            static let name = "Baraometer Calibration Data"
        }
        struct Enabled {
            static let uuid = "f000aa43-0451-4000-b000-000000000000"
            static let name = "Baraometer Enabled"
        }
    }

    //***************************************************************************************************
    // Hygrometer Service
    //***************************************************************************************************
    struct HygrometerService {
        static let uuid = "F000AA20-0451-4000-B000-000000000000"
        static let name = "TI Hygrometer"
        struct Data {
            static let uuid = "f000aa21-0451-4000-b000-000000000000"
            static let name = "Hygrometer Data"
        }
        struct Enabled {
            static let uuid = "f000aa22-0451-4000-b000-000000000000"
            static let name = "Hygrometer Enabled"
        }
    }

    //***************************************************************************************************
    // Sensor Tag Test Service
    //***************************************************************************************************
    struct SensorTagTestService {
        static let uuid = "F000AA60-0451-4000-B000-000000000000"
        static let name = "TI Sensor Tag Test"
        struct Data {
            static let uuid = "f000aa61-0451-4000-b000-000000000000"
            static let name = "Test Data"
        }
        struct Enabled {
            static let uuid = "f000aa62-0451-4000-b000-000000000000"
            static let name = "Test Enabled"
        }
    }

    //***************************************************************************************************
    // Key Pressed Service
    //***************************************************************************************************
    struct KeyPressedService {
        static let uuid = "ffe0"
        static let name = "Sensor Tag Key Pressed"
        struct State {
            static let uuid = "ffe1"
            static let name = "Key Pressed State"
        }
    }
    
    //***************************************************************************************************
    // Common
    //***************************************************************************************************
    struct UInt8Period : DeserializedStruct {
        var periodRaw   : UInt8
        var period      : Int
        static func fromRawValues(values:[UInt8]) -> UInt8Period? {
            var period = 10*Int(values[0])
            if period < 10 {
                period = 10
            }
            return UInt8Period(periodRaw:values[0], period:period)
        }
        static func fromStrings(values:Dictionary<String, String>) -> UInt8Period? {
            if let period = values["period"]?.toInt() {
                let rawPeriod = self.periodRawFromPeriod(period)
                return UInt8Period(periodRaw:rawPeriod, period:10*period)
            } else {
                return nil
            }
        }
        static func periodRawFromPeriod(period:Int) -> UInt8 {
            let scaledPeriod = period/10
            if scaledPeriod > 255 {
                return 255
            } else if scaledPeriod < 10 {
                return 10
            } else {
                return UInt8(scaledPeriod)
            }
        }
        var stringValues : Dictionary<String,String> {
        return ["periodRaw":"\(periodRaw)", "period":"\(period)"]
        }
        func toRawValues() -> [UInt8] {
            return [periodRaw]
        }
    }
    
    enum Enabled: UInt8, DeserializedEnum {
        case No     = 0
        case Yes    = 1
        static func fromRaw(value:UInt8) -> Enabled? {
            switch value {
            case 0:
                return Enabled.No
            case 1:
                return Enabled.Yes
            default:
                return nil
            }
        }
        static func fromString(value:String) -> Enabled? {
            switch value {
            case "No":
                return Enabled.No
            case "Yes":
                return Enabled.Yes
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

class TISensorTagServiceProfiles {
    
    class func create() {

        let profileManage = ProfileManager.sharedInstance()
        
        //***************************************************************************************************
        // Accelerometer Service
        //***************************************************************************************************
        profileManage.addService(ServiceProfile(uuid:TISensorTag.AccelerometerService.uuid, name:TISensorTag.AccelerometerService.name){(serviceProfile:ServiceProfile) in
            // Accelerometer Data
            serviceProfile.addCharacteristic(StructCharacteristicProfile<TISensorTag.AccelerometerService.Data.Value>(uuid:TISensorTag.AccelerometerService.Data.uuid, name:TISensorTag.AccelerometerService.Data.name)
                {(characteristicProfile:StructCharacteristicProfile<TISensorTag.AccelerometerService.Data.Value>) in
                    characteristicProfile.initialValue = NSData.serialize(TISensorTag.AccelerometerService.Data.Value.fromRawValues([-2, 6, 69]))
                    characteristicProfile.properties = CBCharacteristicProperties.Read | CBCharacteristicProperties.Notify
            })
            // Accelerometer Enabled
            serviceProfile.addCharacteristic(EnumCharacteristicProfile<TISensorTag.Enabled>(uuid:TISensorTag.AccelerometerService.Enabled.uuid, name:TISensorTag.AccelerometerService.Enabled.name)
                {(characteristicProfile:EnumCharacteristicProfile<TISensorTag.Enabled>) in
                    characteristicProfile.initialValue = NSData.serialize(TISensorTag.Enabled.No)
                    characteristicProfile.properties = CBCharacteristicProperties.Read | CBCharacteristicProperties.Write
                    characteristicProfile.afterDiscovered(){(characteristic:Characteristic) in
                        characteristic.write(TISensorTag.Enabled.Yes, afterWriteSuccessCallback:{})
                    }
                })
            // Accelerometer Update Period
            serviceProfile.addCharacteristic(StructCharacteristicProfile<TISensorTag.UInt8Period>(uuid:TISensorTag.AccelerometerService.UpdatePeriod.uuid, name:TISensorTag.AccelerometerService.UpdatePeriod.name)
                {(characteristicProfile:StructCharacteristicProfile<TISensorTag.UInt8Period>) in
                    characteristicProfile.initialValue = NSData.serialize(0x64 as UInt8)
                    characteristicProfile.properties = CBCharacteristicProperties.Read | CBCharacteristicProperties.Write | CBCharacteristicProperties.Notify
                })
        })
        
        //***************************************************************************************************
        // Magnetometer Service
        //***************************************************************************************************
        profileManage.addService(ServiceProfile(uuid:TISensorTag.MagnetometerService.uuid, name:TISensorTag.MagnetometerService.name){(serviceProfile:ServiceProfile) in
            // Magentometer Data
            // Magnetometer Enabled
            serviceProfile.addCharacteristic(EnumCharacteristicProfile<TISensorTag.Enabled>(uuid:TISensorTag.MagnetometerService.Enabled.uuid, name: TISensorTag.MagnetometerService.name){(characteristicProfile:EnumCharacteristicProfile<TISensorTag.Enabled>) in
                    characteristicProfile.initialValue = NSData.serialize(TISensorTag.Enabled.No)
                    characteristicProfile.properties = CBCharacteristicProperties.Read | CBCharacteristicProperties.Write
                    characteristicProfile.afterDiscovered(){(characteristic:Characteristic) in
                        characteristic.write(TISensorTag.Enabled.Yes, afterWriteSuccessCallback:{})
                    }
                })
            // Magnetometer Update Period
            serviceProfile.addCharacteristic(StructCharacteristicProfile<TISensorTag.UInt8Period>(uuid:TISensorTag.MagnetometerService.UpdatePeriod.uuid, name:TISensorTag.MagnetometerService.UpdatePeriod.name)
                {(characteristicProfile:StructCharacteristicProfile<TISensorTag.UInt8Period>) in
                    characteristicProfile.initialValue = NSData.serialize(0x64 as UInt8)
                    characteristicProfile.properties = CBCharacteristicProperties.Read | CBCharacteristicProperties.Write | CBCharacteristicProperties.Notify
                })
        })

        //***************************************************************************************************
        // Gyroscope Service
        //***************************************************************************************************
        profileManage.addService(ServiceProfile(uuid:TISensorTag.GyroscopeService.uuid, name:TISensorTag.GyroscopeService.name){(serviceProfile:ServiceProfile) in
        })

        //***************************************************************************************************
        // Temperature Service
        //***************************************************************************************************
        profileManage.addService(ServiceProfile(uuid:TISensorTag.TemperatureService.uuid, name:TISensorTag.TemperatureService.name){(serviceProfile:ServiceProfile) in
        })

        //***************************************************************************************************
        // Barometer Service
        //***************************************************************************************************
        profileManage.addService(ServiceProfile(uuid:TISensorTag.BarometerService.uuid, name:TISensorTag.BarometerService.name){(serviceProfile:ServiceProfile) in
        })

        //***************************************************************************************************
        // Hygrometer Service
        //***************************************************************************************************
        profileManage.addService(ServiceProfile(uuid:TISensorTag.HygrometerService.uuid, name:TISensorTag.HygrometerService.name){(serviceProfile:ServiceProfile) in
        })

        //***************************************************************************************************
        // Sensor Tag Test Service
        //***************************************************************************************************
        profileManage.addService(ServiceProfile(uuid:TISensorTag.SensorTagTestService.uuid, name:TISensorTag.SensorTagTestService.name){(serviceProfile:ServiceProfile) in
        })

        //***************************************************************************************************
        // Key Pressed Service
        //***************************************************************************************************
        profileManage.addService(ServiceProfile(uuid:TISensorTag.KeyPressedService.uuid, name:TISensorTag.KeyPressedService.name){(serviceProfile:ServiceProfile) in
        })

    }
}
