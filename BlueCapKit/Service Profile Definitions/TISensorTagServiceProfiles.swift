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

public struct TISensorTag {

    //***************************************************************************************************
    // Accelerometer Service
    public struct AccelerometerService : ServiceConfigurable  {
        
        // ServiceConfigurable
        public static let uuid  = "F000AA10-0451-4000-B000-000000000000"
        public static let name  = "TI Accelerometer"
        public static let tag   = "TI Sensor Tag"
        
        // Accelerometer Data
        public struct Data : RawArrayDeserializable, CharacteristicConfigurable, StringDeserializable {
            
            private let xRaw:Int8
            private let yRaw:Int8
            private let zRaw:Int8
            
            public let x:Double
            public let y:Double
            public let z:Double

            public init?(x:Double, y:Double, z:Double) {
                self.x = x
                self.y = y
                self.z = z
                if let rawValues = Data.rawFromValues([x, y, z]) {
                    (self.xRaw, self.yRaw, self.zRaw) = rawValues
                } else {
                    return nil
                }
            }
            
            private static func valuesFromRaw(rawValues:[Int8]) -> (Double, Double, Double) {
                return (-Double(rawValues[0])/64.0, -Double(rawValues[1])/64.0, Double(rawValues[2])/64.0)
            }
            
            private static func rawFromValues(values:[Double]) -> (Int8, Int8, Int8)? {
                let xRaw = Int8(doubleValue:(-64.0*values[0]))
                let yRaw = Int8(doubleValue:(-64.0*values[1]))
                let zRaw = Int8(doubleValue:(64.0*values[2]))
                if xRaw != nil && yRaw != nil && zRaw != nil {
                    return (xRaw!, yRaw!, zRaw!)
                } else {
                    return nil
                }
            }
            
            // CharacteristicConfigurable
            public static let uuid                      = "F000AA11-0451-4000-B000-000000000000"
            public static let name                      = "Accelerometer Data"
            public static let properties                = CBCharacteristicProperties.Read | CBCharacteristicProperties.Notify
            public static let permissions               = CBAttributePermissions.Readable | CBAttributePermissions.Writeable
            public static let initialValue : NSData?    = serialize(Data(x:1.0, y:0.5, z:-1.5)!)
            
            // RawArrayDeserializable
            public init?(rawValue:[Int8]) {
                if rawValue.count == 3 {
                    self.xRaw = rawValue[0]
                    self.yRaw = rawValue[1]
                    self.zRaw = rawValue[2]
                    (self.x, self.y, self.z) = Data.valuesFromRaw(rawValue)
                } else {
                    return nil
                }
            }
            
            public var rawValue : [Int8] {
                return [xRaw, yRaw, zRaw]
            }

            // StringDeserializable
            public static let stringValues = [String]()
            
            public var stringValue : Dictionary<String,String> {
                return ["x":"\(self.x)", "y":"\(self.y)", "z":"\(self.z)",
                    "xRaw":"\(self.xRaw)", "yRaw":"\(self.yRaw)", "zRaw":"\(self.zRaw)"]
            }

            public init?(stringValue:[String:String]) {
                let xRawInit = int8ValueFromStringValue("xRaw", stringValue)
                let yRawInit = int8ValueFromStringValue("yRaw", stringValue)
                let zRawInit = int8ValueFromStringValue("zRaw", stringValue)
                if xRawInit != nil && yRawInit != nil && zRawInit != nil {
                    self.xRaw = xRawInit!
                    self.yRaw = yRawInit!
                    self.zRaw = zRawInit!
                    (self.x, self.y, self.z) = Data.valuesFromRaw([self.xRaw, self.yRaw, self.zRaw])
                } else {
                    return nil
                }
            }
            
        }
        
        // Accelerometer Enabled
        public enum Enabled: UInt8, RawDeserializable, StringDeserializable, CharacteristicConfigurable {

            case No     = 0
            case Yes    = 1
            
            // CharacteristicConfigurable
            public static let uuid                     = "F000AA12-0451-4000-B000-000000000000"
            public static let name                     = "Accelerometer Enabled"
            public static let properties               = CBCharacteristicProperties.Read | CBCharacteristicProperties.Write
            public static let permissions              = CBAttributePermissions.Readable | CBAttributePermissions.Writeable
            public static let initialValue : NSData?   = serialize(Enabled.No.rawValue)
            
            
            // StringDeserializable
            public static let stringValues = ["No", "Yes"]
            
            public init?(stringValue:[String:String]) {
                if let value = stringValue["Enabled"] {
                    switch value {
                    case "Yes":
                        self = Enabled.Yes
                    case "No":
                        self = Enabled.No
                    default:
                        return nil
                    }
                } else {
                    return nil
                }
            }
            
            public var stringValue : [String:String] {
                switch self {
                case .No:
                    return ["Enabled":"No"]
                case .Yes:
                    return ["Enabled":"Yes"]
                }
            }
        }

        // Accelerometer Update Period
        public struct UpdatePeriod : RawDeserializable, CharacteristicConfigurable, StringDeserializable {
            
            public let period : UInt16
            
            // CharacteristicConfigurable
            public static let uuid                      = "F000AA13-0451-4000-B000-000000000000"
            public static let name                      = "Accelerometer Update Period"
            public static let permissions               = CBAttributePermissions.Readable | CBAttributePermissions.Writeable
            public static let properties                = CBCharacteristicProperties.Read | CBCharacteristicProperties.Write
            public static let initialValue : NSData?    = serialize(UInt16(5000))
            
            // RawDeserializable
            public var rawValue : UInt16 {
                return self.period
            }
            public init?(rawValue:UInt16) {
                self.period = rawValue
            }
            
            // StringDeserializable
            public static let stringValues = [String]()
            
            public var stringValue : [String:String] {
                return [UpdatePeriod.name:"\(self.period)"]
            }

            public init?(stringValue:[String:String]) {
                if let value = uint16ValueFromStringValue(UpdatePeriod.name, stringValue) {
                    self.period = value
                } else {
                    return nil
                }
            }
            
        }
    }
    
    //***************************************************************************************************
    // Magnetometer Service: units are uT
    public struct MagnetometerService : ServiceConfigurable {
        
        // ServiceConfigurable
        public static let uuid = "F000AA30-0451-4000-B000-000000000000"
        public static let name = "TI Magnetometer"
        public static let tag  = "TI Sensor Tag"

        public struct Data : RawArrayDeserializable, CharacteristicConfigurable, StringDeserializable {

            private let xRaw    : Int16
            private let yRaw    : Int16
            private let zRaw    : Int16
            
            public let x        : Double
            public let y        : Double
            public let z        : Double

            public static func valuesFromRaw(values:[Int16]) -> (Double, Double, Double) {
                let x = -Double(values[0])*2000.0/65536.0
                let y = -Double(values[1])*2000.0/65536.0
                let z = Double(values[2])*2000.0/65536.0
                return (x, y, z)
            }

            public static func rawFromValues(rawValues:[Double]) -> (Int16, Int16, Int16)? {
                let xRaw = Int16(doubleValue:(-rawValues[0]*65536.0/2000.0))
                let yRaw = Int16(doubleValue:(-rawValues[1]*65536.0/2000.0))
                let zRaw = Int16(doubleValue:(rawValues[2]*65536.0/2000.0))
                if xRaw != nil && yRaw != nil && zRaw != nil {
                    return (xRaw!, yRaw!, zRaw!)
                } else {
                    return nil
                }
            }
            
            public init?(x:Double, y:Double, z:Double) {
                self.x = x
                self.y = y
                self.z = z
                if let values = Data.rawFromValues([x, y, z]) {
                    (self.xRaw, self.yRaw, self.zRaw) = values
                } else {
                    return nil
                }
            }
            
            // CharacteristicConfigurable
            public static let uuid                      = "f000aa31-0451-4000-b000-000000000000"
            public static let name                      = "Magnetometer Data"
            public static let properties                = CBCharacteristicProperties.Read | CBCharacteristicProperties.Notify
            public static let permissions               = CBAttributePermissions.Readable | CBAttributePermissions.Writeable
            public static let initialValue : NSData?    = serialize(Data(rawValue:[-2183, 1916, 1255])!)
            
            // RawArrayDeserializable
            public var rawValue : [Int16] {
                return [xRaw, yRaw, zRaw]
            }
            
            public init?(rawValue:[Int16]) {
                if rawValue.count == 3 {
                    self.xRaw = rawValue[0]
                    self.yRaw = rawValue[1]
                    self.zRaw = rawValue[2]
                    (self.x, self.y, self.z) = Data.valuesFromRaw(rawValue)
                } else {
                    return nil
                }
            }
            
            // StringDeserializable
            public static let stringValues = [String]()
            
            public var stringValue  : [String:String] {
                return ["x":"\(x)", "y":"\(y)", "z":"\(z)",
                        "xRaw":"\(xRaw)", "yRaw":"\(yRaw)", "zRaw":"\(zRaw)"]
            }
            
            public init?(stringValue:[String:String]) {
                let xRawInit = int16ValueFromStringValue("xRaw", stringValue)
                let yRawInit = int16ValueFromStringValue("yRaw", stringValue)
                let zRawInit = int16ValueFromStringValue("zRaw", stringValue)
                if xRawInit != nil && yRawInit != nil && zRawInit != nil {
                    self.xRaw = xRawInit!
                    self.yRaw = yRawInit!
                    self.zRaw = zRawInit!
                    (self.x, self.y, self.z) = Data.valuesFromRaw([self.xRaw, self.yRaw, self.zRaw])
                } else {
                    return nil
                }
            }

        }
        
        // Magnetometer Enabled
        public enum Enabled: UInt8, RawDeserializable, StringDeserializable, CharacteristicConfigurable {
            
            case No     = 0
            case Yes    = 1
            
            // CharacteristicConfigurable
            public static let uuid                     = "f000aa32-0451-4000-b000-000000000000"
            public static let name                     = "Magnetometer Enabled"
            public static let properties               = CBCharacteristicProperties.Read | CBCharacteristicProperties.Write
            public static let permissions              = CBAttributePermissions.Readable | CBAttributePermissions.Writeable
            public static let initialValue : NSData?   = serialize(Enabled.No.rawValue)
            
            // StringDeserializable
            public static let stringValues = ["No", "Yes"]
            
            public init?(stringValue:[String:String]) {
                if let value = stringValue["Enabled"] {
                    switch value {
                    case "Yes":
                        self = Enabled.Yes
                    case "No":
                        self = Enabled.No
                    default:
                        return nil
                    }
                } else {
                    return nil
                }
            }
            
            public var stringValue : [String:String] {
                switch self {
                case .No:
                    return ["Enabled":"No"]
                case .Yes:
                    return ["Enabled":"Yes"]
                }
            }
        }

        // Magnetometer UpdatePeriod
        public struct UpdatePeriod : RawDeserializable, CharacteristicConfigurable, StringDeserializable {
            
            public let period : UInt16
            
            // CharacteristicConfigurable
            public static let uuid                      = "f000aa33-0451-4000-b000-000000000000"
            public static let name                      = "Magnetometer Update Period"
            public static let permissions               = CBAttributePermissions.Readable | CBAttributePermissions.Writeable
            public static let properties                = CBCharacteristicProperties.Read | CBCharacteristicProperties.Write
            public static let initialValue : NSData?    = serialize(UInt16(5000))
            
            // RawDeserializable
            public var rawValue : UInt16 {
                return self.period
            }
            public init?(rawValue:UInt16) {
                self.period = rawValue
            }
            
            // StringDeserializable
            public static let stringValues = [String]()
            
            public var stringValue : [String:String] {
                return [UpdatePeriod.name:"\(self.period)"]
            }
            
            public init?(stringValue:[String:String]) {
                if let value = uint16ValueFromStringValue(UpdatePeriod.name, stringValue) {
                    self.period = value
                } else {
                    return nil
                }
            }
            
        }
    }

    //***************************************************************************************************
    // Gyroscope Service: units are degrees
    public struct GyroscopeService : ServiceConfigurable {

        // ServiceConfigurable
        public static let uuid  = "F000AA50-0451-4000-B000-000000000000"
        public static let name  = "TI Gyroscope"
        public static let tag   = "TI Sensor Tag"

        // Gyroscope Data
        public struct Data : RawArrayDeserializable, CharacteristicConfigurable, StringDeserializable {

            private let xRaw    : Int16
            private let yRaw    : Int16
            private let zRaw    : Int16
            
            public let x : Double
            public let y : Double
            public let z : Double
            
            static func valuesFromRaw(values:[Int16]) -> (Double, Double, Double) {
                let x = -Double(values[0])*Double(500.0)/65536.0
                let y = -Double(values[1])*Double(500.0)/65536.0
                let z = Double(values[2])*Double(500.0)/65536.0
                return (x, y, z)
            }

            public static func rawFromValues(rawValues:[Double]) -> (Int16, Int16, Int16)? {
                let xRaw = Int16(doubleValue:(-rawValues[0]*65536.0/500.0))
                let yRaw = Int16(doubleValue:(-rawValues[1]*65536.0/500.0))
                let zRaw = Int16(doubleValue:(rawValues[2]*65536.0/500.0))
                if xRaw != nil && yRaw != nil && zRaw != nil {
                    return (xRaw!, yRaw!, zRaw!)
                } else {
                    return nil
                }
            }

            public init?(x:Double, y:Double, z:Double) {
                self.x = x
                self.y = y
                self.z = z
                if let values = Data.rawFromValues([x, y, z]) {
                    (self.xRaw, self.yRaw, self.zRaw) = values
                } else {
                    return nil
                }
            }
            
            // CharacteristicConfigurable
            public static let uuid                      = "f000aa51-0451-4000-b000-000000000000"
            public static let name                      = "Gyroscope Data"
            public static let properties                = CBCharacteristicProperties.Read | CBCharacteristicProperties.Notify
            public static let permissions               = CBAttributePermissions.Readable | CBAttributePermissions.Writeable
            public static let initialValue : NSData?    = serialize(Data(rawValue:[-24, -219, -23])!)

            // RawArrayDeserializable
            public static let stringValues = [String]()

            public var rawValue : [Int16] {
                return [self.xRaw, self.yRaw, self.zRaw]
            }

            public init?(rawValue:[Int16]) {
                if rawValue.count == 3 {
                    self.xRaw = rawValue[0]
                    self.yRaw = rawValue[1]
                    self.zRaw = rawValue[2]
                    (self.x, self.y, self.z) = Data.valuesFromRaw(rawValue)
                } else {
                    return nil
                }
            }
            
            // StringDeserializable
            public var stringValue : Dictionary<String,String> {
                return ["x":"\(x)", "y":"\(y)", "z":"\(z)",
                        "xRaw":"\(xRaw)", "yRaw":"\(yRaw)", "zRaw":"\(zRaw)"]
            }
            
            public init?(stringValue:[String:String]) {
                let xRawInit = int16ValueFromStringValue("xRaw", stringValue)
                let yRawInit = int16ValueFromStringValue("yRaw", stringValue)
                let zRawInit = int16ValueFromStringValue("zRaw", stringValue)
                if xRawInit != nil && yRawInit != nil && zRawInit != nil {
                    self.xRaw = xRawInit!
                    self.yRaw = yRawInit!
                    self.zRaw = zRawInit!
                    (self.x, self.y, self.z) = Data.valuesFromRaw([self.xRaw, self.yRaw, self.zRaw])
                } else {
                    return nil
                }
            }

        }
        
        // Gyroscope Enabled
        public enum Enabled : UInt8, RawDeserializable, StringDeserializable, CharacteristicConfigurable {
            
            case No         = 0
            case XAxis      = 1
            case YAxis      = 2
            case XYAxis     = 3
            case ZAxis      = 4
            case XZAxis     = 5
            case YZAxis     = 6
            case XYZAxis    = 7
            
            // CharacteristicConfigurable
            public static let uuid                     = "f000aa52-0451-4000-b000-000000000000"
            public static let name                     = "Gyroscope Enabled"
            public static let properties               = CBCharacteristicProperties.Read | CBCharacteristicProperties.Write
            public static let permissions              = CBAttributePermissions.Readable | CBAttributePermissions.Writeable
            public static let initialValue : NSData?   = serialize(Enabled.No.rawValue)

            // StringDeserializable
            public init?(stringValue:[String:String]) {
                if let value = stringValue["Enabled"] {
                    switch value {
                    case "No":
                        self = Enabled.No
                    case "XAxis":
                        self =  Enabled.XAxis
                    case "YAxis":
                        self =  Enabled.YAxis
                    case "XYAxis":
                        self =  Enabled.XYAxis
                    case "ZAxis":
                        self =  Enabled.ZAxis
                    case "XZAxis":
                        self =  Enabled.XZAxis
                    case "YZAxis":
                        self =  Enabled.YZAxis
                    case "XYZAxis":
                        self =  Enabled.XYZAxis
                    default:
                        return nil
                    }
                } else {
                    return nil
                }
            }
            
            public static var stringValues = ["No", "XAxis", "YAxis", "XYAxis",
                                              "ZAxis", "XZAxis", "YZAxis", "XYZAxis"]
            
            public var stringValue : [String:String] {
                switch self {
                case .No:
                    return ["Enabled" : "No"]
                case .XAxis:
                    return ["Enabled" : "XAxis"]
                case .YAxis:
                    return ["Enabled" : "YAxis"]
                case .XYAxis:
                    return ["Enabled" : "XYAxis"]
                case .ZAxis:
                    return ["Enabled" : "ZAxis"]
                case .XZAxis:
                    return ["Enabled" : "XZAxis"]
                case .YZAxis:
                    return ["Enabled" : "YZAxis"]
                case .XYZAxis:
                    return ["Enabled" : "XYZAxis"]
                }
            }
        }
    }

    //***************************************************************************************************
    // Temperature Service units Celsius
    public struct TemperatureService : ServiceConfigurable {
        
        public static let uuid  = "F000AA00-0451-4000-B000-000000000000"
        public static let name  = "TI Temperature"
        public static let tag   = "TI Sensor Tag"

        public struct Data : RawArrayDeserializable, CharacteristicConfigurable, StringDeserializable {

            private let objectRaw   : Int16
            private let ambientRaw  : Int16
            
            public let object       : Double
            public let ambient      : Double

            static func valuesFromRaw(objectRaw:Int16, ambientRaw:Int16) -> (Double, Double) {
                let ambient = Double(ambientRaw)/128.0;
                let vObj2 = Double(objectRaw)*0.00000015625;
                let tDie2 = ambient + 273.15;
                let s0 = 6.4*pow(10,-14);
                let a1 = 1.75*pow(10,-3);
                let a2 = -1.678*pow(10,-5);
                let b0 = -2.94*pow(10,-5);
                let b1 = -5.7*pow(10,-7);
                let b2 = 4.63*pow(10,-9);
                let c2 = 13.4;
                let tRef = 298.15;
                let s = s0*(1+a1*(tDie2 - tRef)+a2*pow((tDie2 - tRef),2));
                let vOs = b0 + b1*(tDie2 - tRef) + b2*pow((tDie2 - tRef),2);
                let fObj = (vObj2 - vOs) + c2*pow((vObj2 - vOs),2);
                let object = pow(pow(tDie2,4) + (fObj/s),0.25) - 273.15;
                return (object, ambient)
            }
            
            // CharacteristicConfigurable
            public static let uuid                      = "f000aa01-0451-4000-b000-000000000000"
            public static let name                      = "Temperature Data"
            public static let properties                = CBCharacteristicProperties.Read | CBCharacteristicProperties.Notify
            public static let permissions               = CBAttributePermissions.Readable | CBAttributePermissions.Writeable
            public static let initialValue : NSData?    = serialize(Data(rawValue:[31, 3260])!)

            // RawArrayDeserializable
            public var rawValue : [Int16] {
                return [self.objectRaw, self.ambientRaw]
            }

            public init?(rawValue:[Int16]) {
                if rawValue.count == 2 {
                    self.objectRaw = rawValue[0]
                    self.ambientRaw = rawValue[1]
                    (self.object, self.ambient) = Data.valuesFromRaw(self.objectRaw, ambientRaw:self.ambientRaw)
                } else {
                    return nil
                }
            }
            
            // StringDeserializable
            public static let stringValues = [String]()

            public var stringValue : Dictionary<String,String> {
                return [ "object":"\(object)", "ambient":"\(ambient)",
                         "objectRaw":"\(objectRaw)", "ambientRaw":"\(ambientRaw)"]
            }
            
            public init?(stringValue:[String:String]) {
                let objectRawInit   = int16ValueFromStringValue("objectRaw", stringValue)
                let ambientRawInit  = int16ValueFromStringValue("ambientRaw", stringValue)
                if objectRawInit != nil && ambientRawInit != nil {
                    self.objectRaw = objectRawInit!
                    self.ambientRaw = ambientRawInit!
                    (self.object, self.ambient) = Data.valuesFromRaw(self.objectRaw, ambientRaw:self.ambientRaw)
                } else {
                    return nil
                }
            }
        }
        
        // Temperature Enabled
        public enum Enabled: UInt8, RawDeserializable, StringDeserializable, CharacteristicConfigurable {
            
            case No     = 0
            case Yes    = 1
            
            // CharacteristicConfigurable
            public static let uuid                     = "f000aa02-0451-4000-b000-000000000000"
            public static let name                     = "Temperature Enabled"
            public static let properties               = CBCharacteristicProperties.Read | CBCharacteristicProperties.Write
            public static let permissions              = CBAttributePermissions.Readable | CBAttributePermissions.Writeable
            public static let initialValue : NSData?   = serialize(Enabled.No.rawValue)
            
            // StringDeserializable
            public static let stringValues = ["No", "Yes"]
            
            public init?(stringValue:[String:String]) {
                if let value = stringValue["Enabled"] {
                    switch value {
                    case "Yes":
                        self = Enabled.Yes
                    case "No":
                        self = Enabled.No
                    default:
                        return nil
                    }
                } else {
                    return nil
                }
            }
            
            public var stringValue : [String:String] {
                switch self {
                case .No:
                    return ["Enabled":"No"]
                case .Yes:
                    return ["Enabled":"Yes"]
                }
            }
        }

    }

    //***************************************************************************************************
    // Barometer Service
    //
    // Calibrated Pressure and Temperature are computed as follows
    // C1...C8 = Calibration Coefficients, TR = Raw temperature, PR = Raw Pressure,
    // T = Calibrated Temperature in Celcius, P = Calibrated Pressure in Pascals
    //
    // S = C3 + C4*TR/2^17 + C5*TR^2/2^34
    // O = C6*2^14 + C7*TR/8 + C8TR^2/2^19
    // P = (S*PR + O)/2^14
    // T = C2/2^10 + C1*TR/2^24
    public struct BarometerService : ServiceConfigurable {
        
        // ServiceConfigurable
        public static let uuid = "F000AA40-0451-4000-B000-000000000000"
        public static let name = "TI Barometer"
        public static let tag  = "TI Sensor Tag"

        public struct Data : RawPairDeserializable, CharacteristicConfigurable, StringDeserializable {

            public let temperatureRaw  : Int16
            public let pressureRaw     : UInt16
            
            // CharacteristicConfigurable
            public static let uuid                      = "f000aa41-0451-4000-b000-000000000000"
            public static let name                      = "Baraometer Data"
            public static let properties                = CBCharacteristicProperties.Read | CBCharacteristicProperties.Notify
            public static let permissions               = CBAttributePermissions.Readable | CBAttributePermissions.Writeable
            public static let initialValue : NSData?    = serialize(Data(rawValue:(-2343, 33995))!)

            // RawPairDeserializable
            public static let stringValues = [String]()
            
            public var rawValue : (Int16, UInt16) {
                return (self.temperatureRaw, self.pressureRaw)
            }
            
            public init?(rawValue:(Int16, UInt16)) {
                (self.temperatureRaw, self.pressureRaw) = rawValue
            }

            // StringDeserializable
            public var stringValue : Dictionary<String,String> {
                return ["temperatureRaw":"\(temperatureRaw)", "pressureRaw":"\(pressureRaw)"]
            }

            public init?(stringValue:[String:String]) {
                let temperatureRawInit = int16ValueFromStringValue("temperatureRaw", stringValue)
                let pressureRawInit = uint16ValueFromStringValue("pressureRaw", stringValue)
                if temperatureRawInit != nil && pressureRawInit != nil {
                    self.temperatureRaw = temperatureRawInit!
                    self.pressureRaw = pressureRawInit!
                } else {
                    return nil
                }
            }
            
        }
    
        // Barometer Calibration
        public struct Calibration : RawArrayPairDeserializable, CharacteristicConfigurable, StringDeserializable {

            public let c1 : UInt16
            public let c2 : UInt16
            public let c3 : UInt16
            public let c4 : UInt16
            
            public let c5 : Int16
            public let c6 : Int16
            public let c7 : Int16
            public let c8 : Int16
            
            // CharacteristicConfigurable
            public static let uuid                      = "f000aa43-0451-4000-b000-000000000000"
            public static let name                      = "Baraometer Calibration Data"
            public static let properties                = CBCharacteristicProperties.Read | CBCharacteristicProperties.Notify
            public static let permissions               = CBAttributePermissions.Readable | CBAttributePermissions.Writeable
            public static let initialValue : NSData?    = serialize(Calibration(rawValue:([45697, 25592, 48894, 36174], [7001, 1990, -2369, 5542]))!)

            // RawArrayPairDeserializable
            public static var size : (Int, Int) {
                return (4*sizeof(UInt16), 4*sizeof(Int16))
            }
            
            public var rawValue : ([UInt16], [Int16]) {
                return ([self.c1, self.c2, self.c3, self.c4],
                        [self.c5, self.c6, self.c7, self.c8])
            }

            public init?(rawValue:([UInt16], [Int16])) {
                let (unsignedValues, signedValues) = rawValue
                if unsignedValues.count == 4 && signedValues.count == 4 {
                    self.c1 = unsignedValues[0]
                    self.c2 = unsignedValues[1]
                    self.c3 = unsignedValues[2]
                    self.c4 = unsignedValues[3]
                    self.c5 = signedValues[0]
                    self.c6 = signedValues[1]
                    self.c7 = signedValues[2]
                    self.c8 = signedValues[3]
                } else {
                    return nil
                }
            }
            
            // StringDeserializable
            public static let stringValues = [String]()

            public var stringValue : [String:String] {
                return ["c1":"\(c1)", "c2":"\(c2)", "c3":"\(c3)",
                        "c4":"\(c4)", "c5":"\(c5)", "c6":"\(c6)",
                        "c7":"\(c7)", "c8":"\(c8)"]
            }

            public init?(stringValue:[String:String]) {
                let c1Init = uint16ValueFromStringValue("c1", stringValue)
                let c2Init = uint16ValueFromStringValue("c2", stringValue)
                let c3Init = uint16ValueFromStringValue("c3", stringValue)
                let c4Init = uint16ValueFromStringValue("c4", stringValue)
                let c5Init = int16ValueFromStringValue("c5", stringValue)
                let c6Init = int16ValueFromStringValue("c6", stringValue)
                let c7Init = int16ValueFromStringValue("c7", stringValue)
                let c8Init = int16ValueFromStringValue("c8", stringValue)
                if c1Init != nil && c2Init != nil && c3Init != nil && c4Init != nil && c5Init != nil && c6Init != nil && c7Init != nil && c8Init != nil {
                    self.c1 = c1Init!
                    self.c2 = c2Init!
                    self.c3 = c3Init!
                    self.c4 = c4Init!
                    self.c5 = c5Init!
                    self.c6 = c6Init!
                    self.c7 = c7Init!
                    self.c8 = c8Init!
                } else {
                    return nil
                }
            }
        }
    
        // Barometer Enabled
        public enum Enabled: UInt8, RawDeserializable, StringDeserializable, CharacteristicConfigurable {
            
            case No         = 0
            case Yes        = 1
            case Calibrate  = 2
            
            // CharacteristicConfigurable
            public static let uuid                     = "f000aa42-0451-4000-b000-000000000000"
            public static let name                     = "Baraometer Enabled"
            public static let properties               = CBCharacteristicProperties.Read | CBCharacteristicProperties.Write
            public static let permissions              = CBAttributePermissions.Readable | CBAttributePermissions.Writeable
            public static let initialValue : NSData?   = serialize(Enabled.No.rawValue)
            
            // StringDeserializable
            public static let stringValues =  ["No", "Yes", "Calibrate"]
            
            public init?(stringValue:[String:String]) {
                if let value = stringValue["Enabled"] {
                    switch value {
                    case "Yes":
                        self = Enabled.Yes
                    case "No":
                        self = Enabled.No
                    case "Calibrate":
                        self = Enabled.Calibrate
                    default:
                        return nil
                    }
                } else {
                    return nil
                }
            }
            
            public var stringValue : [String:String] {
                switch self {
                case .No:
                    return ["Enabled":"No"]
                case .Yes:
                    return ["Enabled":"Yes"]
                case .Calibrate:
                    return ["Enabled":"Yes"]
                }
            }
        }
    }

    //***************************************************************************************************
    // Hygrometer Service
    // Temperature units Celsius
    // Humidity units Relative Humdity
    public struct HygrometerService  : ServiceConfigurable {
        
        // ServiceConfigurable
        public static let uuid = "F000AA20-0451-4000-B000-000000000000"
        public static let name = "TI Hygrometer"
        public static let tag  = "TI Sensor Tag"

        public struct Data : RawArrayDeserializable, CharacteristicConfigurable, StringDeserializable {

            public var temperatureRaw  : UInt16
            public var humidityRaw     : UInt16
            
            public var temperature     : Double
            public var humidity        : Double
            
            private static func valuesFromRaw(temperatureRaw:UInt16, humidityRaw:UInt16) -> (Double, Double) {
                return (-46.86+175.72*Double(temperatureRaw)/65536.0, -6.0+125.0*Double(humidityRaw)/65536.0)
            }

            // CharacteristicConfigurable
            public static let uuid                      = "f000aa21-0451-4000-b000-000000000000"
            public static let name                      = "Hygrometer Data"
            public static let properties                = CBCharacteristicProperties.Read | CBCharacteristicProperties.Notify
            public static let permissions               = CBAttributePermissions.Readable | CBAttributePermissions.Writeable
            public static let initialValue : NSData?    = serialize(Data(rawValue:[2600, 3500])!)
            
            // RawArrayDeserializable
            public var rawValue : [UInt16] {
                return [self.temperatureRaw, self.humidityRaw]
            }
            
            public init?(rawValue:[UInt16]) {
                if rawValue.count == 2 {
                    self.temperatureRaw = rawValue[0]
                    self.humidityRaw = rawValue[1]
                    (self.temperature, self.humidity) = Data.valuesFromRaw(self.temperatureRaw, humidityRaw:self.humidityRaw)
                } else {
                    return nil
                }
            }
            
            // StringDeserializable
            public static let stringValues = [String]()
            
            public var stringValue : [String:String] {
                return ["temperature":"\(temperature)", "humidity":"\(humidity)",
                        "temperatureRaw":"\(temperatureRaw)", "humidityRaw":"\(humidityRaw)"]
            }
            
            public init?(stringValue:[String:String]) {
                let temperatureRawInit = uint16ValueFromStringValue("temperatureRaw", stringValue)
                let humidityRawInit = uint16ValueFromStringValue("humidityRaw", stringValue)
                if temperatureRawInit != nil && humidityRawInit != nil {
                    self.temperatureRaw = temperatureRawInit!
                    self.humidityRaw = humidityRawInit!
                    (self.temperature, self.humidity) = Data.valuesFromRaw(self.temperatureRaw, humidityRaw:self.humidityRaw)
                } else {
                    return nil
                }
            }
        }
        
        // Hygrometer Enabled
        public enum Enabled: UInt8, RawDeserializable, StringDeserializable, CharacteristicConfigurable {
            
            case No     = 0
            case Yes    = 1
            
            // CharacteristicConfigurable
            public static let uuid                      = "f000aa22-0451-4000-b000-000000000000"
            public static let name                      = "Hygrometer Enabled"
            public static let properties                = CBCharacteristicProperties.Read | CBCharacteristicProperties.Write
            public static let permissions               = CBAttributePermissions.Readable | CBAttributePermissions.Writeable
            public static let initialValue : NSData?    = serialize(Enabled.No.rawValue)
            
            
            // StringDeserializable
            public static let stringValues = ["No", "Yes"]
            
            public init?(stringValue:[String:String]) {
                if let value = stringValue["Enabled"] {
                    switch value {
                    case "Yes":
                        self = Enabled.Yes
                    case "No":
                        self = Enabled.No
                    default:
                        return nil
                    }
                } else {
                    return nil
                }
            }
            
            public var stringValue : [String:String] {
                switch self {
                case .No:
                    return ["Enabled":"No"]
                case .Yes:
                    return ["Enabled":"Yes"]
                }
            }
        }

    }

    //***************************************************************************************************
    // Sensor Tag Test Service
    public struct SensorTagTestService : ServiceConfigurable {
        
        // ServiceConfigurable
        public static let uuid  = "F000AA60-0451-4000-B000-000000000000"
        public static let name  = "TI Sensor Tag Test"
        public static let tag   = "TI Sensor Tag"
        
        public struct Data : RawDeserializable, CharacteristicConfigurable, StringDeserializable {

            var resultRaw : UInt8

            var test1 : Bool
            var test2 : Bool
            var test3 : Bool
            var test4 : Bool
            var test5 : Bool
            var test6 : Bool
            var test7 : Bool
            var test8 : Bool
        
            // CharacteristicConfigurable
            public static let uuid                      = "f000aa61-0451-4000-b000-000000000000"
            public static let name                      = "Test Data"
            public static let properties                = CBCharacteristicProperties.Read
            public static let permissions               = CBAttributePermissions.Readable | CBAttributePermissions.Writeable
            public static let initialValue : NSData?    = serialize(0b11110000 as UInt8)

            private static func valuesFromRaw(rawValue:UInt8) -> [Bool] {
                return [self.testResult(rawValue, position:0), self.testResult(rawValue, position:1),
                    self.testResult(rawValue, position:2), self.testResult(rawValue, position:3),
                    self.testResult(rawValue, position:4), self.testResult(rawValue, position:5),
                    self.testResult(rawValue, position:6), self.testResult(rawValue, position:7)]
            }
            
            private static func testResult(rawResult:UInt8, position:UInt8) -> Bool {
                return (rawResult & (1 << position)) > 0
            }
            
            private static func testResultStringValue(value:Bool) -> String {
                return value ? "PASSED" : "FAILED"
            }


            // RawDeserializable
            public var rawValue : UInt8 {
                return self.resultRaw
            }
            
            public init?(rawValue:UInt8) {
                self.resultRaw = rawValue
                let values = Data.valuesFromRaw(rawValue)
                self.test1 = values[0]
                self.test2 = values[1]
                self.test3 = values[2]
                self.test4 = values[3]
                self.test5 = values[4]
                self.test6 = values[5]
                self.test7 = values[6]
                self.test8 = values[7]
            }
            
            // StringDeserializable
            public static let stringValues = [String]()

            public var stringValue : [String:String] {
                return ["resultRaw":"\(resultRaw)", "test1":"\(Data.testResultStringValue(test1))",
                        "test2":"\(Data.testResultStringValue(test2))", "test3":"\(Data.testResultStringValue(test3))",
                        "test4":"\(Data.testResultStringValue(test4))", "test5":"\(Data.testResultStringValue(test5))",
                        "test6":"\(Data.testResultStringValue(test6))", "test7":"\(Data.testResultStringValue(test7))",
                        "test8":"\(Data.testResultStringValue(test8))"]
            }
                
            public init?(stringValue:[String:String]) {
                if let rawValue = uint8ValueFromStringValue("resultRaw", stringValue) {
                    let values = Data.valuesFromRaw(rawValue)
                    self.resultRaw = rawValue
                    self.test1 = values[0]
                    self.test2 = values[1]
                    self.test3 = values[2]
                    self.test4 = values[3]
                    self.test5 = values[4]
                    self.test6 = values[5]
                    self.test7 = values[6]
                    self.test8 = values[7]
                } else {
                    return nil
                }
            }

        }
    
        public enum Enabled: UInt8, RawDeserializable, StringDeserializable, CharacteristicConfigurable {
            
            case No     = 0
            case Yes    = 1
            
            // CharacteristicConfigurable
            public static let uuid                      = "f000aa62-0451-4000-b000-000000000000"
            public static let name                      = "Test Enabled"
            public static let properties                = CBCharacteristicProperties.Read | CBCharacteristicProperties.Write
            public static let permissions               = CBAttributePermissions.Readable | CBAttributePermissions.Writeable
            public static let initialValue : NSData?    = serialize(Enabled.No.rawValue)
            
            
            // StringDeserializable
            public static let stringValues = ["No", "Yes"]
            
            public init?(stringValue:[String:String]) {
                if let value = stringValue["Enabled"] {
                    switch value {
                    case "Yes":
                        self = Enabled.Yes
                    case "No":
                        self = Enabled.No
                    default:
                        return nil
                    }
                } else {
                    return nil
                }
            }
            
            public var stringValue : [String:String] {
                switch self {
                case .No:
                    return ["Enabled":"No"]
                case .Yes:
                    return ["Enabled":"Yes"]
                }
            }
        }

    }

    //***************************************************************************************************
    // Key Pressed Service
    public struct KeyPressedService : ServiceConfigurable {

        public static let uuid = "ffe0"
        public static let name = "Sensor Tag Key Pressed"
        public static let tag  = "TI Sensor Tag"

        public enum State : UInt8, RawDeserializable, CharacteristicConfigurable, StringDeserializable {
            
            case None       = 0
            case ButtonOne  = 1
            case ButtonTwo  = 2
            
            // CharacteristicConfigurable
            public static let uuid                      = "ffe1"
            public static let name                      = "Key Pressed"
            public static let properties                = CBCharacteristicProperties.Notify
            public static let permissions               = CBAttributePermissions.Readable | CBAttributePermissions.Writeable
            public static let initialValue : NSData?    = serialize(0x01 as UInt8)
            
            // StringDeserializable
            public static let stringValues = ["None", "Button One", "Button Two"]
            
            public var stringValue : [String:String] {
                switch self {
                case .None:
                    return [State.name:"None"]
                case .ButtonOne:
                    return [State.name:"Button One"]
                case .ButtonTwo:
                    return [State.name:"Button Two"]
                }
            }

            public init?(stringValue:[String:String]) {
                if let value = stringValue[State.name] {
                    switch value {
                    case "None":
                        self = State.None
                    case "Button One":
                        self = State.ButtonOne
                    case "Button Two":
                        self = State.ButtonTwo
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

//public class TISensorTagServiceProfiles {
//    
//    public class func create() {
//
//        let profileManager = ProfileManager.sharedInstance
//        
//        //***************************************************************************************************
//        // Accelerometer Service
//        //***************************************************************************************************
//        profileManager.addService(ServiceProfile(uuid:TISensorTag.AccelerometerService.uuid, name:TISensorTag.AccelerometerService.name){(serviceProfile) in
//            serviceProfile.tag = "TI Sensor Tag"
//            // Accelerometer Data
//            serviceProfile.addCharacteristic(StructCharacteristicProfile<TISensorTag.AccelerometerService.Data.Value>(uuid:TISensorTag.AccelerometerService.Data.uuid, name:TISensorTag.AccelerometerService.Data.name)
//                {(characteristicProfile) in
//                    characteristicProfile.initialValue = NSData.serializeArray(TISensorTag.AccelerometerService.Data.Value.fromRawValues([-2, 6, 69])!.toRawValues())
//                    characteristicProfile.properties = CBCharacteristicProperties.Read | CBCharacteristicProperties.Notify
//            })
//            // Accelerometer Enabled
//            serviceProfile.addCharacteristic(EnumCharacteristicProfile<TISensorTag.Enabled>(uuid:TISensorTag.AccelerometerService.Enabled.uuid, name:TISensorTag.AccelerometerService.Enabled.name)
//                {(characteristicProfile) in
//                    characteristicProfile.initialValue = NSData.serialize(TISensorTag.Enabled.No.toRaw())
//                    characteristicProfile.properties = CBCharacteristicProperties.Read | CBCharacteristicProperties.Write
//                    characteristicProfile.afterDiscovered(2).onSuccess {(characteristic) in
//                        characteristic.write(TISensorTag.Enabled.Yes)
//                        return
//                    }
//                })
//            // Accelerometer Update Period
//            serviceProfile.addCharacteristic(StructCharacteristicProfile<TISensorTag.UInt8Period>(uuid:TISensorTag.AccelerometerService.UpdatePeriod.uuid, name:TISensorTag.AccelerometerService.UpdatePeriod.name)
//                {(characteristicProfile) in
//                    characteristicProfile.initialValue = NSData.serialize(UInt8(0x64))
//                    characteristicProfile.properties = CBCharacteristicProperties.Read | CBCharacteristicProperties.Write
//                })
//        })
//        
//        //***************************************************************************************************
//        // Magnetometer Service
//        //***************************************************************************************************
//        profileManager.addService(ServiceProfile(uuid:TISensorTag.MagnetometerService.uuid, name:TISensorTag.MagnetometerService.name){(serviceProfile) in
//            serviceProfile.tag = "TI Sensor Tag"
//            // Magentometer Data
//            serviceProfile.addCharacteristic(StructCharacteristicProfile<TISensorTag.MagnetometerService.Data.Value>(uuid:TISensorTag.MagnetometerService.Data.uuid, name:TISensorTag.MagnetometerService.Data.name)
//                {(characteristicProfile) in
//                    characteristicProfile.endianness = .Little
//                    characteristicProfile.initialValue = NSData.serializeArrayToLittleEndian(TISensorTag.MagnetometerService.Data.Value.fromRawValues([-2183, 1916, 1255])!.toRawValues())
//                    characteristicProfile.properties = CBCharacteristicProperties.Read | CBCharacteristicProperties.Notify
//                })
//            // Magnetometer Enabled
//            serviceProfile.addCharacteristic(EnumCharacteristicProfile<TISensorTag.Enabled>(uuid:TISensorTag.MagnetometerService.Enabled.uuid, name: TISensorTag.MagnetometerService.Enabled.name)
//                {(characteristicProfile) in
//                    characteristicProfile.initialValue = NSData.serialize(TISensorTag.Enabled.No.toRaw())
//                    characteristicProfile.properties = CBCharacteristicProperties.Read | CBCharacteristicProperties.Write
//                    characteristicProfile.afterDiscovered(1).onSuccess {(characteristic) in
//                        characteristic.write(TISensorTag.Enabled.Yes)
//                        return
//                    }
//                })
//            // Magnetometer Update Period
//            serviceProfile.addCharacteristic(StructCharacteristicProfile<TISensorTag.UInt8Period>(uuid:TISensorTag.MagnetometerService.UpdatePeriod.uuid, name:TISensorTag.MagnetometerService.UpdatePeriod.name)
//                {(characteristicProfile) in
//                    characteristicProfile.initialValue = NSData.serialize(UInt8(0x64))
//                    characteristicProfile.properties = CBCharacteristicProperties.Read | CBCharacteristicProperties.Write
//                })
//        })
//
//        //***************************************************************************************************
//        // Gyroscope Service
//        //***************************************************************************************************
//        profileManager.addService(ServiceProfile(uuid:TISensorTag.GyroscopeService.uuid, name:TISensorTag.GyroscopeService.name) {(serviceProfile) in
//            serviceProfile.tag = "TI Sensor Tag"
//            // Gyroscope Data
//            serviceProfile.addCharacteristic(StructCharacteristicProfile<TISensorTag.GyroscopeService.Data.Value>(uuid:TISensorTag.GyroscopeService.Data.uuid, name:TISensorTag.GyroscopeService.Data.name)
//                {(characteristicProfile) in
//                    characteristicProfile.endianness = .Little
//                    characteristicProfile.initialValue = NSData.serializeArrayToLittleEndian(TISensorTag.GyroscopeService.Data.Value.fromRawValues([-24, -219, -23])!.toRawValues())
//                    characteristicProfile.properties = CBCharacteristicProperties.Read | CBCharacteristicProperties.Notify
//                })
//            // Gyroscope Enables
//            serviceProfile.addCharacteristic(EnumCharacteristicProfile<TISensorTag.GyroscopeService.Enabled.Value>(uuid:TISensorTag.GyroscopeService.Enabled.uuid, name:TISensorTag.GyroscopeService.Enabled.name)
//                {(characteristicProfile) in
//                    characteristicProfile.initialValue = NSData.serialize(TISensorTag.GyroscopeService.Enabled.Value.No.toRaw())
//                    characteristicProfile.properties = CBCharacteristicProperties.Read | CBCharacteristicProperties.Write
//                    characteristicProfile.afterDiscovered(1).onSuccess {(characteristic) in
//                        characteristic.write(TISensorTag.GyroscopeService.Enabled.Value.XYZAxis)
//                        return
//                    }
//                })
//        })
//
//        //***************************************************************************************************
//        // Temperature Service
//        //***************************************************************************************************
//        profileManager.addService(ServiceProfile(uuid:TISensorTag.TemperatureService.uuid, name:TISensorTag.TemperatureService.name) {(serviceProfile) in
//            serviceProfile.tag = "TI Sensor Tag"
//            // Temperature Data
//            serviceProfile.addCharacteristic(StructCharacteristicProfile<TISensorTag.TemperatureService.Data.Value>(uuid:TISensorTag.TemperatureService.Data.uuid, name:TISensorTag.TemperatureService.Data.name)
//                {(characteristicProfile) in
//                    characteristicProfile.endianness = .Little
//                    characteristicProfile.initialValue = NSData.serializeArrayToLittleEndian(TISensorTag.GyroscopeService.Data.Value.fromRawValues([-24, -219, -23])!.toRawValues())
//                    characteristicProfile.properties = CBCharacteristicProperties.Read | CBCharacteristicProperties.Notify
//                })
//            // Temperature Enabled
//            serviceProfile.addCharacteristic(EnumCharacteristicProfile<TISensorTag.Enabled>(uuid:TISensorTag.TemperatureService.Enabled.uuid, name:TISensorTag.TemperatureService.Enabled.name)
//                {(characteristicProfile) in
//                    characteristicProfile.initialValue = NSData.serialize(TISensorTag.Enabled.No.toRaw())
//                    characteristicProfile.properties = CBCharacteristicProperties.Read | CBCharacteristicProperties.Write
//                    characteristicProfile.afterDiscovered(1).onSuccess {(characteristic) in
//                        characteristic.write(TISensorTag.Enabled.Yes)
//                        return
//                    }
//                })
//        })
//
//        //***************************************************************************************************
//        // Barometer Service
//        //***************************************************************************************************
//        profileManager.addService(ServiceProfile(uuid:TISensorTag.BarometerService.uuid, name:TISensorTag.BarometerService.name) {(serviceProfile) in
//            serviceProfile.tag = "TI Sensor Tag"
//            // Barometer Data
//            serviceProfile.addCharacteristic(PairStructCharacteristicProfile<TISensorTag.BarometerService.Data.Value>(uuid:TISensorTag.BarometerService.Data.uuid, name:TISensorTag.BarometerService.Data.name)
//                {(characteristicProfile) in
//                    characteristicProfile.endianness = .Little
//                    characteristicProfile.initialValue = NSData.serializeArrayPairToLittleEndian(TISensorTag.BarometerService.Data.Value.fromRawValues(([-2343], [33995]))!.toRawValues())
//                    characteristicProfile.properties = CBCharacteristicProperties.Read | CBCharacteristicProperties.Notify
//                })
//            // Barometer Calibration
//            serviceProfile.addCharacteristic(PairStructCharacteristicProfile<TISensorTag.BarometerService.Calibration.Value>(uuid:TISensorTag.BarometerService.Calibration.uuid, name:TISensorTag.BarometerService.Calibration.name)
//                {(characteristicProfile) in
//                    characteristicProfile.endianness = .Little
//                    characteristicProfile.properties = CBCharacteristicProperties.Read
//                    characteristicProfile.initialValue = NSData.serializeArrayPairToLittleEndian(TISensorTag.BarometerService.Calibration.Value.fromRawValues(([45697, 25592, 48894, 36174], [7001, 1990, -2369, 5542]))!.toRawValues())
//                })
//            // Baromter Enabled
//            serviceProfile.addCharacteristic(EnumCharacteristicProfile<TISensorTag.BarometerService.Enabled.Value>(uuid:TISensorTag.BarometerService.Enabled.uuid, name:TISensorTag.BarometerService.Enabled.name)
//                {(characteristicProfile) in
//                    characteristicProfile.initialValue = NSData.serialize(TISensorTag.BarometerService.Enabled.Value.No.toRaw())
//                    characteristicProfile.properties = CBCharacteristicProperties.Read | CBCharacteristicProperties.Write
//                    characteristicProfile.afterDiscovered(1).flatmap {characteristic in
//                        characteristic.write(TISensorTag.BarometerService.Enabled.Value.Yes)
//                    }.flatmap {characteristic in
//                        characteristic.write(TISensorTag.BarometerService.Enabled.Value.Calibrate)
//                    }
//                })
//        })
//
//        //***************************************************************************************************
//        // Hygrometer Service
//        //***************************************************************************************************
//        profileManager.addService(ServiceProfile(uuid:TISensorTag.HygrometerService.uuid, name:TISensorTag.HygrometerService.name){(serviceProfile) in
//            serviceProfile.tag = "TI Sensor Tag"
//            // Hygrometer Data
//            serviceProfile.addCharacteristic(StructCharacteristicProfile<TISensorTag.HygrometerService.Data.Value>(uuid:TISensorTag.HygrometerService.Data.uuid, name:TISensorTag.HygrometerService.Data.name)
//                {(characteristicProfile) in
//                    characteristicProfile.endianness = .Little
//                    characteristicProfile.initialValue = NSData.serializeArrayToLittleEndian(TISensorTag.HygrometerService.Data.Value.fromRawValues([2600, 3500])!.toRawValues())
//                    characteristicProfile.properties = CBCharacteristicProperties.Read | CBCharacteristicProperties.Notify
//                })
//            // Hygrometer Enabled
//            serviceProfile.addCharacteristic(EnumCharacteristicProfile<TISensorTag.Enabled>(uuid:TISensorTag.HygrometerService.Enabled.uuid, name:TISensorTag.HygrometerService.Enabled.name)
//                {(characteristicProfile) in
//                    characteristicProfile.initialValue = NSData.serialize(TISensorTag.Enabled.No.toRaw())
//                    characteristicProfile.properties = CBCharacteristicProperties.Read | CBCharacteristicProperties.Write
//                    characteristicProfile.afterDiscovered(1).onSuccess {(characteristic) in
//                        characteristic.write(TISensorTag.Enabled.Yes)
//                        return
//                    }
//                })
//        })
//
//        //***************************************************************************************************
//        // Sensor Tag Test Service
//        //***************************************************************************************************
//        profileManager.addService(ServiceProfile(uuid:TISensorTag.SensorTagTestService.uuid, name:TISensorTag.SensorTagTestService.name) {(serviceProfile) in
//            serviceProfile.tag = "TI Sensor Tag"
//            // Test Data
//            serviceProfile.addCharacteristic(StructCharacteristicProfile<TISensorTag.SensorTagTestService.Data.Value>(uuid:TISensorTag.SensorTagTestService.Data.uuid, name: TISensorTag.SensorTagTestService.Data.name)
//                {(characteristicProfile) in
//                    characteristicProfile.initialValue = NSData.serialize(0b11110000 as UInt8)
//                    characteristicProfile.properties = CBCharacteristicProperties.Read
//                })
//            // Test Enabled
//            serviceProfile.addCharacteristic(EnumCharacteristicProfile<TISensorTag.Enabled>(uuid:TISensorTag.SensorTagTestService.Enabled.uuid, name:TISensorTag.SensorTagTestService.Enabled.name)
//                {(characteristicProfile) in
//                    characteristicProfile.initialValue = NSData.serialize(TISensorTag.Enabled.No.toRaw())
//                    characteristicProfile.properties = CBCharacteristicProperties.Read | CBCharacteristicProperties.Write
//                })
//        })
//
//        //***************************************************************************************************
//        // Key Pressed Service
//        //***************************************************************************************************
//        profileManager.addService(ServiceProfile(uuid:TISensorTag.KeyPressedService.uuid, name:TISensorTag.KeyPressedService.name){(serviceProfile) in
//            serviceProfile.tag = "TI Sensor Tag"
//            serviceProfile.addCharacteristic(DeserializedCharacteristicProfile<UInt8>(uuid:TISensorTag.KeyPressedService.Data.uuid, name:TISensorTag.KeyPressedService.Data.name)
//                {(characteristicProfile) in
//                    characteristicProfile.initialValue = NSData.serialize(0x01 as UInt8)
//                    characteristicProfile.properties = CBCharacteristicProperties.Notify
//                })
//        })
//
//    }
//}
