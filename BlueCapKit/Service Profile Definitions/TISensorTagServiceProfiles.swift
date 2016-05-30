//
//  TISensorTagServiceProfiles.swift
//  BlueCap
//
//  Created by Troy Stribling on 7/6/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import Foundation
import CoreBluetooth

// MARK: - TISensorTag SErvices -
public struct TISensorTag {

    // MARK: - Accelerometer Service -
    public struct AccelerometerService: BCServiceConfigurable  {
        
        // ServiceConfigurable
        public static let UUID  = "F000AA10-0451-4000-B000-000000000000"
        public static let name  = "TI Accelerometer"
        public static let tag   = "TI Sensor Tag"
        
        // Accelerometer Data
        public struct Data: BCRawArrayDeserializable, BCCharacteristicConfigurable, BCStringDeserializable {
            
            private let xRaw: Int8
            private let yRaw: Int8
            private let zRaw: Int8
            
            public let x: Double
            public let y: Double
            public let z: Double

            public init?(x: Double, y: Double, z: Double) {
                self.x = x
                self.y = y
                self.z = z
                if let rawValues = Data.rawFromValues([x, y, z]) {
                    (self.xRaw, self.yRaw, self.zRaw) = rawValues
                } else {
                    return nil
                }
            }
            
            private static func valuesFromRaw(rawValues: [Int8]) -> (Double, Double, Double) {
                return (-Double(rawValues[0])/64.0, -Double(rawValues[1])/64.0, Double(rawValues[2])/64.0)
            }
            
            private static func rawFromValues(values: [Double]) -> (Int8, Int8, Int8)? {
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
            public static let UUID                                      = "F000AA11-0451-4000-B000-000000000000"
            public static let name                                      = "Accelerometer Data"
            public static let properties: CBCharacteristicProperties    = [.Read, .Notify]
            public static let permissions: CBAttributePermissions       = [.Readable, .Writeable]
            public static let initialValue: NSData?                     = BCSerDe.serialize(Data(x: 1.0, y: 0.5, z: -1.5)!)
            
            // RawArrayDeserializable
            public static let size = 3
            
            public init?(rawValue: [Int8]) {
                if rawValue.count == 3 {
                    self.xRaw = rawValue[0]
                    self.yRaw = rawValue[1]
                    self.zRaw = rawValue[2]
                    (self.x, self.y, self.z) = Data.valuesFromRaw(rawValue)
                } else {
                    return nil
                }
            }
            
            public var rawValue: [Int8] {
                return [self.xRaw, self.yRaw, self.zRaw]
            }

            // StringDeserializable
            public static let stringValues = [String]()
            
            public var stringValue: [String: String] {
                return ["x":NSString(format: "%.2f", self.x) as String,
                        "y":NSString(format: "%.2f", self.y) as String,
                        "z":NSString(format: "%.2f", self.z) as String,
                        "xRaw":"\(self.xRaw)",
                        "yRaw":"\(self.yRaw)",
                        "zRaw":"\(self.zRaw)"]
            }

            public init?(stringValue: [String: String]) {
                if  let xRawInit = int8ValueFromStringValue("xRaw", values: stringValue),
                        yRawInit = int8ValueFromStringValue("yRaw", values: stringValue),
                        zRawInit = int8ValueFromStringValue("zRaw", values: stringValue) {
                    self.xRaw = xRawInit
                    self.yRaw = yRawInit
                    self.zRaw = zRawInit
                    (self.x, self.y, self.z) = Data.valuesFromRaw([self.xRaw, self.yRaw, self.zRaw])
                } else {
                    return nil
                }
            }
            
        }
        
        // Accelerometer Enabled
        public enum Enabled: UInt8, BCRawDeserializable, BCStringDeserializable, BCCharacteristicConfigurable {

            case No     = 0
            case Yes    = 1
            
            // CharacteristicConfigurable
            public static let UUID                                      = "F000AA12-0451-4000-B000-000000000000"
            public static let name                                      = "Accelerometer Enabled"
            public static let properties: CBCharacteristicProperties    = [.Read, .Write]
            public static let permissions: CBAttributePermissions       = [.Readable, .Writeable]
            public static let initialValue: NSData?                     = BCSerDe.serialize(Enabled.No.rawValue)
            
            
            // StringDeserializable
            public static let stringValues = ["No", "Yes"]
            
            public init(boolValue: Bool) {
                if boolValue {
                    self = Enabled.Yes
                } else {
                    self = Enabled.No
                }
            }
            
            public init?(stringValue: [String: String]) {
                if let value = stringValue[Enabled.name] {
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
            
            public var stringValue: [String: String] {
                switch self {
                case .No:
                    return [Enabled.name:"No"]
                case .Yes:
                    return [Enabled.name:"Yes"]
                }
            }
            
            public var boolValue: Bool {
                switch self {
                case .No:
                    return false
                case .Yes:
                    return true
                }
            }
        }

        // Accelerometer Update Period
        public struct UpdatePeriod: BCRawDeserializable, BCCharacteristicConfigurable, BCStringDeserializable {
            
            public let periodRaw: UInt8
            public let period: UInt16
            
            private static func valueFromRaw(rawValue:UInt8) -> UInt16 {
                var period = 10*UInt16(rawValue)
                if period < 10 {
                    period = 10
                }
                return period
            }

            // CharacteristicConfigurable
            public static let UUID                                      = "F000AA13-0451-4000-B000-000000000000"
            public static let name                                      = "Accelerometer Update Period"
            public static let permissions: CBAttributePermissions       = [.Readable, .Writeable]
            public static let properties: CBCharacteristicProperties    = [.Read, .Write]
            public static let initialValue: NSData?                     = BCSerDe.serialize(UInt8(100))
            
            // RawDeserializable
            public var rawValue: UInt8 {
                return self.periodRaw
            }
            public init?(rawValue: UInt8) {
                self.periodRaw = rawValue
                self.period = UpdatePeriod.valueFromRaw(self.periodRaw)
            }

            // StringDeserializable
            public static let stringValues = [String]()
            
            public var stringValue: [String: String] {
                return ["period":"\(self.period)", "periodRaw":"\(self.periodRaw)"]
            }

            public init?(stringValue: [String: String]) {
                if let rawValue = uint8ValueFromStringValue("periodRaw", values: stringValue) {
                    self.periodRaw = rawValue
                    self.period = UpdatePeriod.valueFromRaw(self.periodRaw)
                } else {
                    return nil
                }
            }
            
        }
    }
    
    // MARK: - Magnetometer Service: units are uT -
    public struct MagnetometerService: BCServiceConfigurable {
        
        // ServiceConfigurable
        public static let UUID = "F000AA30-0451-4000-B000-000000000000"
        public static let name = "TI Magnetometer"
        public static let tag  = "TI Sensor Tag"

        public struct Data: BCRawArrayDeserializable, BCCharacteristicConfigurable, BCStringDeserializable {

            private let xRaw: Int16
            private let yRaw: Int16
            private let zRaw: Int16
            
            public let x: Double
            public let y: Double
            public let z: Double

            public static func valuesFromRaw(values: [Int16]) -> (Double, Double, Double) {
                let x = -Double(values[0])*2000.0/65536.0
                let y = -Double(values[1])*2000.0/65536.0
                let z = Double(values[2])*2000.0/65536.0
                return (x, y, z)
            }

            public static func rawFromValues(rawValues: [Double]) -> (Int16, Int16, Int16)? {
                if let xRaw = Int16(doubleValue: (-rawValues[0]*65536.0/2000.0)),
                       yRaw = Int16(doubleValue: (-rawValues[1]*65536.0/2000.0)),
                       zRaw = Int16(doubleValue: (rawValues[2]*65536.0/2000.0)) {
                    return (xRaw, yRaw, zRaw)
                } else {
                    return nil
                }
            }
            
            public init?(x: Double, y: Double, z: Double) {
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
            public static let UUID                                      = "f000aa31-0451-4000-b000-000000000000"
            public static let name                                      = "Magnetometer Data"
            public static let properties: CBCharacteristicProperties    = [.Read, .Notify]
            public static let permissions: CBAttributePermissions       = [.Readable, .Writeable]
            public static let initialValue: NSData?                     = BCSerDe.serialize(Data(rawValue: [-2183, 1916, 1255])!)
            
            // RawArrayDeserializable
            public static let size = 6

            public var rawValue: [Int16] {
                return [xRaw, yRaw, zRaw]
            }
            
            public init?(rawValue: [Int16]) {
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
            
            public var stringValue: [String: String] {
                return ["x":"\(x)", "y":"\(y)", "z":"\(z)",
                        "xRaw":"\(xRaw)", "yRaw":"\(yRaw)", "zRaw":"\(zRaw)"]
            }
            
            public init?(stringValue: [String: String]) {
                if let xRawInit = int16ValueFromStringValue("xRaw", values: stringValue),
                       yRawInit = int16ValueFromStringValue("yRaw", values: stringValue),
                       zRawInit = int16ValueFromStringValue("zRaw", values: stringValue) {
                    self.xRaw = xRawInit
                    self.yRaw = yRawInit
                    self.zRaw = zRawInit
                    (self.x, self.y, self.z) = Data.valuesFromRaw([self.xRaw, self.yRaw, self.zRaw])
                } else {
                    return nil
                }
            }

        }
        
        // Magnetometer Enabled
        public enum Enabled: UInt8, BCRawDeserializable, BCStringDeserializable, BCCharacteristicConfigurable {
            
            case No     = 0
            case Yes    = 1
            
            // CharacteristicConfigurable
            public static let UUID                                      = "f000aa32-0451-4000-b000-000000000000"
            public static let name                                      = "Magnetometer Enabled"
            public static let properties: CBCharacteristicProperties    = [.Read, .Write]
            public static let permissions: CBAttributePermissions       = [.Readable, .Writeable]
            public static let initialValue: NSData?                     = BCSerDe.serialize(Enabled.No.rawValue)
            
            // StringDeserializable
            public static let stringValues = ["No", "Yes"]
            
            public init?(stringValue: [String: String]) {
                if let value = stringValue[Enabled.name] {
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
            
            public var stringValue: [String: String] {
                switch self {
                case .No:
                    return [Enabled.name:"No"]
                case .Yes:
                    return [Enabled.name:"Yes"]
                }
            }
        }

        // Magnetometer UpdatePeriod
        public struct UpdatePeriod: BCRawDeserializable, BCCharacteristicConfigurable, BCStringDeserializable {
            
            public let periodRaw: UInt8
            public let period: UInt16
            
            private static func valueFromRaw(rawValue:UInt8) -> UInt16 {
                var period = 10*UInt16(rawValue)
                if period < 10 {
                    period = 10
                }
                return period
            }
            
            // CharacteristicConfigurable
            public static let UUID                                      = "f000aa33-0451-4000-b000-000000000000"
            public static let name                                      = "Magnetometer Update Period"
            public static let permissions: CBAttributePermissions       = [.Readable, .Writeable]
            public static let properties: CBCharacteristicProperties    = [.Read, .Write]
            public static let initialValue: NSData?                     = BCSerDe.serialize(UInt16(5000))
            
            // RawDeserializable
            public var rawValue: UInt8 {
                return self.periodRaw
            }
            public init?(rawValue: UInt8) {
                self.periodRaw = rawValue
                self.period = UpdatePeriod.valueFromRaw(self.periodRaw)
            }
            
            // StringDeserializable
            public static let stringValues = [String]()
            
            public var stringValue: [String:String] {
                return ["period":"\(self.period)", "periodRaw":"\(self.periodRaw)"]
            }
            
            public init?(stringValue: [String:String]) {
                if let rawValue = uint8ValueFromStringValue("periodRaw", values:stringValue) {
                    self.periodRaw = rawValue
                    self.period = UpdatePeriod.valueFromRaw(self.periodRaw)
                } else {
                    return nil
                }
            }
            
        }
    }

    // MARK: - Gyroscope Service: units are degrees -
    public struct GyroscopeService : BCServiceConfigurable {

        // ServiceConfigurable
        public static let UUID  = "F000AA50-0451-4000-B000-000000000000"
        public static let name  = "TI Gyroscope"
        public static let tag   = "TI Sensor Tag"

        // Gyroscope Data
        public struct Data: BCRawArrayDeserializable, BCCharacteristicConfigurable, BCStringDeserializable {

            private let xRaw: Int16
            private let yRaw: Int16
            private let zRaw: Int16
            
            public let x: Double
            public let y: Double
            public let z: Double
            
            static func valuesFromRaw(values: [Int16]) -> (Double, Double, Double) {
                let x = -Double(values[0])*Double(500.0)/65536.0
                let y = -Double(values[1])*Double(500.0)/65536.0
                let z = Double(values[2])*Double(500.0)/65536.0
                return (x, y, z)
            }

            public static func rawFromValues(rawValues: [Double]) -> (Int16, Int16, Int16)? {
                if let xRaw = Int16(doubleValue:(-rawValues[0]*65536.0/500.0)), yRaw = Int16(doubleValue:(-rawValues[1]*65536.0/500.0)), zRaw = Int16(doubleValue:(rawValues[2]*65536.0/500.0)) {
                    return (xRaw, yRaw, zRaw)
                } else {
                    return nil
                }
            }

            public init?(x: Double, y: Double, z: Double) {
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
            public static let UUID                                      = "f000aa51-0451-4000-b000-000000000000"
            public static let name                                      = "Gyroscope Data"
            public static let properties: CBCharacteristicProperties    = [.Read, .Notify]
            public static let permissions: CBAttributePermissions       = [.Readable, .Writeable]
            public static let initialValue: NSData?                     = BCSerDe.serialize(Data(rawValue: [-24, -219, -23])!)

            // RawArrayDeserializable
            public static let size = 6

            public static let stringValues = [String]()

            public var rawValue: [Int16] {
                return [self.xRaw, self.yRaw, self.zRaw]
            }

            public init?(rawValue: [Int16]) {
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
            public var stringValue: [String: String] {
                return ["x":"\(x)", "y":"\(y)", "z":"\(z)",
                        "xRaw":"\(xRaw)", "yRaw":"\(yRaw)", "zRaw":"\(zRaw)"]
            }
            
            public init?(stringValue: [String:String]) {
                if let xRawInit = int16ValueFromStringValue("xRaw", values: stringValue),
                       yRawInit = int16ValueFromStringValue("yRaw", values: stringValue),
                       zRawInit = int16ValueFromStringValue("zRaw", values: stringValue) {
                    self.xRaw = xRawInit
                    self.yRaw = yRawInit
                    self.zRaw = zRawInit
                    (self.x, self.y, self.z) = Data.valuesFromRaw([self.xRaw, self.yRaw, self.zRaw])
                } else {
                    return nil
                }
            }

        }
        
        // Gyroscope Enabled
        public enum Enabled : UInt8, BCRawDeserializable, BCStringDeserializable, BCCharacteristicConfigurable {
            
            case No         = 0
            case XAxis      = 1
            case YAxis      = 2
            case XYAxis     = 3
            case ZAxis      = 4
            case XZAxis     = 5
            case YZAxis     = 6
            case XYZAxis    = 7
            
            // CharacteristicConfigurable
            public static let UUID                                      = "f000aa52-0451-4000-b000-000000000000"
            public static let name                                      = "Gyroscope Enabled"
            public static let properties: CBCharacteristicProperties    = [.Read, .Write]
            public static let permissions: CBAttributePermissions       = [.Readable, .Writeable]
            public static let initialValue: NSData?                     = BCSerDe.serialize(Enabled.No.rawValue)

            // StringDeserializable
            public init?(stringValue: [String: String]) {
                if let value = stringValue[Enabled.name] {
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
            
            public var stringValue: [String: String] {
                switch self {
                case .No:
                    return [Enabled.name: "No"]
                case .XAxis:
                    return [Enabled.name: "XAxis"]
                case .YAxis:
                    return [Enabled.name: "YAxis"]
                case .XYAxis:
                    return [Enabled.name: "XYAxis"]
                case .ZAxis:
                    return [Enabled.name: "ZAxis"]
                case .XZAxis:
                    return [Enabled.name: "XZAxis"]
                case .YZAxis:
                    return [Enabled.name: "YZAxis"]
                case .XYZAxis:
                    return [Enabled.name: "XYZAxis"]
                }
            }
        }
    }

    // MARK: - Temperature Service units Celsius -
    public struct TemperatureService : BCServiceConfigurable {
        
        public static let UUID  = "F000AA00-0451-4000-B000-000000000000"
        public static let name  = "TI Temperature"
        public static let tag   = "TI Sensor Tag"

        public struct Data: BCRawArrayDeserializable, BCCharacteristicConfigurable, BCStringDeserializable {

            private let objectRaw: Int16
            private let ambientRaw: Int16
            
            public let object: Double
            public let ambient: Double

            static func valuesFromRaw(objectRaw: Int16, ambientRaw: Int16) -> (Double, Double) {
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
            public static let UUID                                      = "f000aa01-0451-4000-b000-000000000000"
            public static let name                                      = "Temperature Data"
            public static let properties: CBCharacteristicProperties    = [.Read, .Notify]
            public static let permissions: CBAttributePermissions       = [.Readable, .Writeable]
            public static let initialValue: NSData?                     = BCSerDe.serialize(Data(rawValue: [-172, 3388])!)

            // RawArrayDeserializable
            public static let size = 4

            public var rawValue: [Int16] {
                return [self.objectRaw, self.ambientRaw]
            }

            public init?(rawValue: [Int16]) {
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
                if let objectRawInit = int16ValueFromStringValue("objectRaw", values:stringValue), ambientRawInit = int16ValueFromStringValue("ambientRaw", values:stringValue) {
                    self.objectRaw = objectRawInit
                    self.ambientRaw = ambientRawInit
                    (self.object, self.ambient) = Data.valuesFromRaw(self.objectRaw, ambientRaw:self.ambientRaw)
                } else {
                    return nil
                }
            }
        }
        
        // Temperature Enabled
        public enum Enabled: UInt8, BCRawDeserializable, BCStringDeserializable, BCCharacteristicConfigurable {
            
            case No     = 0
            case Yes    = 1
            
            // CharacteristicConfigurable
            public static let UUID                                      = "f000aa02-0451-4000-b000-000000000000"
            public static let name                                      = "Temperature Enabled"
            public static let properties: CBCharacteristicProperties    = [.Read, .Write]
            public static let permissions: CBAttributePermissions       = [.Readable, .Writeable]
            public static let initialValue: NSData?                     = BCSerDe.serialize(Enabled.No.rawValue)
            
            // StringDeserializable
            public static let stringValues = ["No", "Yes"]
            
            public init?(stringValue: [String: String]) {
                if let value = stringValue[Enabled.name] {
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
                    return [Enabled.name:"No"]
                case .Yes:
                    return [Enabled.name:"Yes"]
                }
            }
        }

    }

    // MARK: - Barometer Service -
    //
    // Calibrated Pressure and Temperature are computed as follows
    // C1...C8 = Calibration Coefficients, TR = Raw temperature, PR = Raw Pressure,
    // T = Calibrated Temperature in Celcius, P = Calibrated Pressure in Pascals
    //
    // S = C3 + C4*TR/2^17 + C5*TR^2/2^34
    // O = C6*2^14 + C7*TR/8 + C8TR^2/2^19
    // P = (S*PR + O)/2^14
    // T = C2/2^10 + C1*TR/2^24
    public struct BarometerService : BCServiceConfigurable {
        
        // ServiceConfigurable
        public static let UUID = "F000AA40-0451-4000-B000-000000000000"
        public static let name = "TI Barometer"
        public static let tag  = "TI Sensor Tag"

        public struct Data : BCRawPairDeserializable, BCCharacteristicConfigurable, BCStringDeserializable {

            public let temperatureRaw: Int16
            public let pressureRaw: UInt16
            
            // CharacteristicConfigurable
            public static let UUID                                      = "f000aa41-0451-4000-b000-000000000000"
            public static let name                                      = "Baraometer Data"
            public static let properties: CBCharacteristicProperties    = [.Read, .Notify]
            public static let permissions: CBAttributePermissions       = [.Readable, .Writeable]
            public static let initialValue: NSData?                     = BCSerDe.serialize(Data(rawValue1:-2343, rawValue2:33995)!)

            // RawPairDeserializable
            public var rawValue1 : Int16 {
                return self.temperatureRaw
            }

            public var rawValue2 : UInt16 {
                return self.pressureRaw
            }

            public init?(rawValue1:Int16, rawValue2:UInt16) {
                self.temperatureRaw = rawValue1
                self.pressureRaw = rawValue2
            }

            // StringDeserializable
            public static let stringValues = [String]()
            
            public var stringValue : Dictionary<String,String> {
                return ["temperatureRaw":"\(temperatureRaw)", "pressureRaw":"\(pressureRaw)"]
            }

            public init?(stringValue:[String:String]) {
                if let temperatureRawInit = int16ValueFromStringValue("temperatureRaw", values: stringValue),
                       pressureRawInit = uint16ValueFromStringValue("pressureRaw", values: stringValue) {
                    self.temperatureRaw = temperatureRawInit
                    self.pressureRaw = pressureRawInit
                } else {
                    return nil
                }
            }
            
        }
    
        // Barometer Calibration
        public struct Calibration: BCRawArrayPairDeserializable, BCCharacteristicConfigurable, BCStringDeserializable {

            public let c1 : UInt16
            public let c2 : UInt16
            public let c3 : UInt16
            public let c4 : UInt16
            
            public let c5 : Int16
            public let c6 : Int16
            public let c7 : Int16
            public let c8 : Int16
            
            // CharacteristicConfigurable
            public static let UUID                                      = "f000aa43-0451-4000-b000-000000000000"
            public static let name                                      = "Baraometer Calibration Data"
            public static let properties: CBCharacteristicProperties    = [.Read, .Notify]
            public static let permissions: CBAttributePermissions       = [.Readable, .Writeable]
            public static let initialValue: NSData?                     = BCSerDe.serialize(Calibration(rawValue1:[45697, 25592, 48894, 36174], rawValue2:[7001, 1990, -2369, 5542])!)

            // RawArrayPairDeserializable
            public static var size1: Int {
                return 4*sizeof(UInt16)
            }

            public static var size2: Int {
                return 4*sizeof(Int16)
            }

            public var rawValue1: [UInt16] {
                return [self.c1, self.c2, self.c3, self.c4]
            }

            public var rawValue2: [Int16] {
                return [self.c5, self.c6, self.c7, self.c8]
            }

            public init?(rawValue1: [UInt16], rawValue2: [Int16]) {
                if rawValue1.count == 4 && rawValue2.count == 4 {
                    self.c1 = rawValue1[0]
                    self.c2 = rawValue1[1]
                    self.c3 = rawValue1[2]
                    self.c4 = rawValue1[3]
                    self.c5 = rawValue2[0]
                    self.c6 = rawValue2[1]
                    self.c7 = rawValue2[2]
                    self.c8 = rawValue2[3]
                } else {
                    return nil
                }
            }
            
            // StringDeserializable
            public static let stringValues = [String]()

            public var stringValue: [String: String] {
                return ["c1":"\(c1)", "c2":"\(c2)", "c3":"\(c3)",
                        "c4":"\(c4)", "c5":"\(c5)", "c6":"\(c6)",
                        "c7":"\(c7)", "c8":"\(c8)"]
            }

            public init?(stringValue: [String: String]) {
                if let c1Init = uint16ValueFromStringValue("c1", values: stringValue),
                       c2Init = uint16ValueFromStringValue("c2", values: stringValue),
                       c3Init = uint16ValueFromStringValue("c3", values: stringValue),
                       c4Init = uint16ValueFromStringValue("c4", values: stringValue),
                       c5Init = int16ValueFromStringValue("c5", values: stringValue),
                       c6Init = int16ValueFromStringValue("c6", values: stringValue),
                       c7Init = int16ValueFromStringValue("c7", values: stringValue),
                       c8Init = int16ValueFromStringValue("c8", values: stringValue) {
                    self.c1 = c1Init
                    self.c2 = c2Init
                    self.c3 = c3Init
                    self.c4 = c4Init
                    self.c5 = c5Init
                    self.c6 = c6Init
                    self.c7 = c7Init
                    self.c8 = c8Init
                } else {
                    return nil
                }
            }
        }
    
        // Barometer Enabled
        public enum Enabled: UInt8, BCRawDeserializable, BCStringDeserializable, BCCharacteristicConfigurable {
            
            case No         = 0
            case Yes        = 1
            case Calibrate  = 2
            
            // CharacteristicConfigurable
            public static let UUID                                      = "f000aa42-0451-4000-b000-000000000000"
            public static let name                                      = "Baraometer Enabled"
            public static let properties: CBCharacteristicProperties    = [.Read, .Write]
            public static let permissions: CBAttributePermissions       = [.Readable, .Writeable]
            public static let initialValue: NSData?                     = BCSerDe.serialize(Enabled.No.rawValue)
            
            // StringDeserializable
            public static let stringValues =  ["No", "Yes", "Calibrate"]
            
            public init?(stringValue:[String:String]) {
                if let value = stringValue[Enabled.name] {
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
                    return [Enabled.name:"No"]
                case .Yes:
                    return [Enabled.name:"Yes"]
                case .Calibrate:
                    return [Enabled.name:"Yes"]
                }
            }
        }
    }

    // MARK: - Hygrometer Service -
    // Temperature units Celsius
    // Humidity units Relative Humdity
    public struct HygrometerService: BCServiceConfigurable {
        
        // ServiceConfigurable
        public static let UUID = "F000AA20-0451-4000-B000-000000000000"
        public static let name = "TI Hygrometer"
        public static let tag  = "TI Sensor Tag"

        public struct Data: BCRawArrayDeserializable, BCCharacteristicConfigurable, BCStringDeserializable {

            public var temperatureRaw  : UInt16
            public var humidityRaw     : UInt16
            
            public var temperature     : Double
            public var humidity        : Double
            
            private static func valuesFromRaw(temperatureRaw:UInt16, humidityRaw:UInt16) -> (Double, Double) {
                return (-46.86+175.72*Double(temperatureRaw)/65536.0, -6.0+125.0*Double(humidityRaw)/65536.0)
            }

            // CharacteristicConfigurable
            public static let UUID                                      = "f000aa21-0451-4000-b000-000000000000"
            public static let name                                      = "Hygrometer Data"
            public static let properties: CBCharacteristicProperties    = [.Read, .Notify]
            public static let permissions: CBAttributePermissions       = [.Readable, .Writeable]
            public static let initialValue: NSData?                     = BCSerDe.serialize(Data(rawValue:[2600, 3500])!)
            
            // RawArrayDeserializable
            public static let size = 4

            public var rawValue: [UInt16] {
                return [self.temperatureRaw, self.humidityRaw]
            }
            
            public init?(rawValue: [UInt16]) {
                if rawValue.count == 2 {
                    self.temperatureRaw = rawValue[0]
                    self.humidityRaw = rawValue[1]
                    (self.temperature, self.humidity) = Data.valuesFromRaw(self.temperatureRaw, humidityRaw: self.humidityRaw)
                } else {
                    return nil
                }
            }
            
            // StringDeserializable
            public static let stringValues = [String]()
            
            public var stringValue: [String: String] {
                return ["temperature":"\(temperature)", "humidity":"\(humidity)",
                        "temperatureRaw":"\(temperatureRaw)", "humidityRaw":"\(humidityRaw)"]
            }
            
            public init?(stringValue:[String:String]) {
                let temperatureRawInit = uint16ValueFromStringValue("temperatureRaw", values:stringValue)
                let humidityRawInit = uint16ValueFromStringValue("humidityRaw", values:stringValue)
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
        public enum Enabled:UInt8, BCRawDeserializable, BCStringDeserializable, BCCharacteristicConfigurable {
            
            case No     = 0
            case Yes    = 1
            
            // CharacteristicConfigurable
            public static let UUID                                      = "f000aa22-0451-4000-b000-000000000000"
            public static let name                                      = "Hygrometer Enabled"
            public static let properties: CBCharacteristicProperties    = [.Read, .Write]
            public static let permissions: CBAttributePermissions       = [.Readable, .Writeable]
            public static let initialValue: NSData?                     = BCSerDe.serialize(Enabled.No.rawValue)
            
            
            // StringDeserializable
            public static let stringValues = ["No", "Yes"]
            
            public var stringValue : [String:String] {
                switch self {
                case .No:
                    return [Enabled.name:"No"]
                case .Yes:
                    return [Enabled.name:"Yes"]
                }
            }

            public init?(stringValue: [String: String]) {
                if let value = stringValue[Enabled.name] {
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
            
        }

    }

    // MARK: - Sensor Tag Test Service -
    public struct SensorTagTestService: BCServiceConfigurable {
        
        // ServiceConfigurable
        public static let UUID  = "F000AA60-0451-4000-B000-000000000000"
        public static let name  = "TI Sensor Tag Test"
        public static let tag   = "TI Sensor Tag"
        
        public struct Data: BCRawDeserializable, BCCharacteristicConfigurable, BCStringDeserializable {

            var resultRaw: UInt8

            var test1: Bool
            var test2: Bool
            var test3: Bool
            var test4: Bool
            var test5: Bool
            var test6: Bool
            var test7: Bool
            var test8: Bool
        
            // CharacteristicConfigurable
            public static let UUID                                      = "f000aa61-0451-4000-b000-000000000000"
            public static let name                                      = "Test Data"
            public static let properties: CBCharacteristicProperties    = .Read
            public static let permissions: CBAttributePermissions       = [.Readable, .Writeable]
            public static let initialValue: NSData?                     = BCSerDe.serialize(0b11110000 as UInt8)

            private static func valuesFromRaw(rawValue:UInt8) -> [Bool] {
                return [self.testResult(rawValue, position: 0), self.testResult(rawValue, position: 1),
                        self.testResult(rawValue, position: 2), self.testResult(rawValue, position: 3),
                        self.testResult(rawValue, position: 4), self.testResult(rawValue, position: 5),
                        self.testResult(rawValue, position: 6), self.testResult(rawValue, position: 7)]
            }
            
            private static func testResult(rawResult: UInt8, position: UInt8) -> Bool {
                return (rawResult & (1 << position)) > 0
            }
            
            private static func testResultStringValue(value: Bool) -> String {
                return value ? "PASSED" : "FAILED"
            }


            // RawDeserializable
            public var rawValue: UInt8 {
                return self.resultRaw
            }
            
            public init?(rawValue: UInt8) {
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

            public var stringValue: [String: String] {
                return ["resultRaw": "\(resultRaw)", "test1": "\(Data.testResultStringValue(test1))",
                        "test2": "\(Data.testResultStringValue(test2))", "test3": "\(Data.testResultStringValue(test3))",
                        "test4": "\(Data.testResultStringValue(test4))", "test5": "\(Data.testResultStringValue(test5))",
                        "test6": "\(Data.testResultStringValue(test6))", "test7": "\(Data.testResultStringValue(test7))",
                        "test8": "\(Data.testResultStringValue(test8))"]
            }
                
            public init?(stringValue: [String: String]) {
                if let rawValue = uint8ValueFromStringValue("resultRaw", values: stringValue) {
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
    
        public enum Enabled: UInt8, BCRawDeserializable, BCStringDeserializable, BCCharacteristicConfigurable {
            
            case No     = 0
            case Yes    = 1
            
            // CharacteristicConfigurable
            public static let UUID                                      = "f000aa62-0451-4000-b000-000000000000"
            public static let name                                      = "Test Enabled"
            public static let properties: CBCharacteristicProperties    = [.Read, .Write]
            public static let permissions: CBAttributePermissions       = [.Readable, .Writeable]
            public static let initialValue: NSData?                     = BCSerDe.serialize(Enabled.No.rawValue)
            
            
            // StringDeserializable
            public static let stringValues = ["No", "Yes"]
            
            public init?(stringValue: [String:String]) {
                if let value = stringValue[Enabled.name] {
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
            
            public var stringValue: [String: String] {
                switch self {
                case .No:
                    return [Enabled.name: "No"]
                case .Yes:
                    return [Enabled.name: "Yes"]
                }
            }
        }

    }

    // MARK: - Key Pressed Service -
    public struct KeyPressedService : BCServiceConfigurable {

        public static let UUID = "ffe0"
        public static let name = "Sensor Tag Key Pressed"
        public static let tag  = "TI Sensor Tag"

        public enum State : UInt8, BCRawDeserializable, BCCharacteristicConfigurable, BCStringDeserializable {
            
            case None       = 0
            case ButtonOne  = 1
            case ButtonTwo  = 2
            
            // CharacteristicConfigurable
            public static let UUID                                      = "ffe1"
            public static let name                                      = "Key Pressed"
            public static let properties: CBCharacteristicProperties    = .Notify
            public static let permissions: CBAttributePermissions       = [.Readable, .Writeable]
            public static let initialValue: NSData?                     = BCSerDe.serialize(0x01 as UInt8)
            
            // StringDeserializable
            public static let stringValues = ["None", "Button One", "Button Two"]
            
            public var stringValue: [String: String] {
                switch self {
                case .None:
                    return [State.name: "None"]
                case .ButtonOne:
                    return [State.name: "Button One"]
                case .ButtonTwo:
                    return [State.name: "Button Two"]
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

// MARK: - TISensorTagServiceProfiles -
public class TISensorTagServiceProfiles {

    public class func create() {

        let profileManager = BCProfileManager.sharedInstance

        // Accelerometer Service
        let accelerometerService = BCConfiguredServiceProfile<TISensorTag.AccelerometerService>()
        let accelerometerDataCharacteristic = BCRawArrayCharacteristicProfile<TISensorTag.AccelerometerService.Data>()
        let accelerometerEnabledCharacteristic = BCRawCharacteristicProfile<TISensorTag.AccelerometerService.Enabled>()
        let accelerometerUpdatePeriodCharacteristic = BCRawCharacteristicProfile<TISensorTag.AccelerometerService.UpdatePeriod>()
        
        accelerometerEnabledCharacteristic.afterDiscovered(2).onSuccess {characteristic in
            characteristic.write(TISensorTag.AccelerometerService.Enabled.Yes)
            return
        }
        
        accelerometerService.addCharacteristic(accelerometerDataCharacteristic)
        accelerometerService.addCharacteristic(accelerometerEnabledCharacteristic)
        accelerometerService.addCharacteristic(accelerometerUpdatePeriodCharacteristic)
        profileManager.addService(accelerometerService)

        // Magnetometer Service
        let magnetometerService = BCConfiguredServiceProfile<TISensorTag.MagnetometerService>()
        let magnetometerDataCharacteristic = BCRawArrayCharacteristicProfile<TISensorTag.MagnetometerService.Data>()
        let magnetometerEnabledCharacteristic = BCRawCharacteristicProfile<TISensorTag.MagnetometerService.Enabled>()
        let magnetometerUpdatePeriodCharacteristic = BCRawCharacteristicProfile<TISensorTag.MagnetometerService.UpdatePeriod>()
        
        magnetometerEnabledCharacteristic.afterDiscovered(2).onSuccess {characteristic in
            characteristic.write(TISensorTag.MagnetometerService.Enabled.Yes)
            return
        }
        
        magnetometerService.addCharacteristic(magnetometerDataCharacteristic)
        magnetometerService.addCharacteristic(magnetometerEnabledCharacteristic)
        magnetometerService.addCharacteristic(magnetometerUpdatePeriodCharacteristic)
        profileManager.addService(magnetometerService)
        
        // Gyroscope Service
        let gyroscopeService = BCConfiguredServiceProfile<TISensorTag.GyroscopeService>()
        let gyroscopeDataCharacteristic = BCRawArrayCharacteristicProfile<TISensorTag.GyroscopeService.Data>()
        let gyroscopeEnabledCharacteristic = BCRawCharacteristicProfile<TISensorTag.GyroscopeService.Enabled>()
        
        gyroscopeEnabledCharacteristic.afterDiscovered(2).onSuccess {characteristic in
            characteristic.write(TISensorTag.GyroscopeService.Enabled.XYZAxis)
            return
        }
        
        gyroscopeService.addCharacteristic(gyroscopeDataCharacteristic)
        gyroscopeService.addCharacteristic(gyroscopeEnabledCharacteristic)
        profileManager.addService(gyroscopeService)
        

        // Temperature Service
        let temperatureService = BCConfiguredServiceProfile<TISensorTag.TemperatureService>()
        let temperatureDataCharacteristic = BCRawArrayCharacteristicProfile<TISensorTag.TemperatureService.Data>()
        let temperatureEnabledCharacteristic = BCRawCharacteristicProfile<TISensorTag.TemperatureService.Enabled>()
        
        temperatureEnabledCharacteristic.afterDiscovered(2).onSuccess {characteristic in
            characteristic.write(TISensorTag.TemperatureService.Enabled.Yes)
            return
        }
        
        temperatureService.addCharacteristic(temperatureDataCharacteristic)
        temperatureService.addCharacteristic(temperatureEnabledCharacteristic)
        profileManager.addService(temperatureService)
        
        // Barometer Service
        let barometerService = BCConfiguredServiceProfile<TISensorTag.BarometerService>()
        let barometerDataCharacteristic = BCRawPairCharacteristicProfile<TISensorTag.BarometerService.Data>()
        let barometerCalibrationCharacteristic = BCRawArrayPairCharacteristicProfile<TISensorTag.BarometerService.Calibration>()
        let barometerEnabledCharacteristic = BCRawCharacteristicProfile<TISensorTag.BarometerService.Enabled>()
        
        let barometerDiscoveredFuture = barometerEnabledCharacteristic.afterDiscovered(2)
            
        let barometerEnabledFuture = barometerDiscoveredFuture.flatmap {characteristic -> Future<BCCharacteristic> in
            return characteristic.write(TISensorTag.BarometerService.Enabled.Yes)
        }
        
        barometerEnabledFuture.onSuccess {characteristic in
            characteristic.write(TISensorTag.BarometerService.Enabled.Calibrate)
            return
        }
        
        barometerService.addCharacteristic(barometerDataCharacteristic)
        barometerService.addCharacteristic(barometerCalibrationCharacteristic)
        barometerService.addCharacteristic(barometerEnabledCharacteristic)
        profileManager.addService(barometerService)
        
        // Hygrometer Service
        let hygrometerService = BCConfiguredServiceProfile<TISensorTag.HygrometerService>()
        let hygrometerDataCharacteristic = BCRawArrayCharacteristicProfile<TISensorTag.HygrometerService.Data>()
        let hygrometerEnabledCharacteristic = BCRawCharacteristicProfile<TISensorTag.HygrometerService.Enabled>()
        
        hygrometerEnabledCharacteristic.afterDiscovered(2).onSuccess {characteristic in
            characteristic.write(TISensorTag.HygrometerService.Enabled.Yes)
            return
        }
        
        hygrometerService.addCharacteristic(hygrometerDataCharacteristic)
        hygrometerService.addCharacteristic(hygrometerEnabledCharacteristic)
        profileManager.addService(hygrometerService)
        

        // Sensor Tag Test Service
        let sensorTagTestService = BCConfiguredServiceProfile<TISensorTag.SensorTagTestService>()
        let sensorTagTestData = BCRawCharacteristicProfile<TISensorTag.SensorTagTestService.Data>()
        let sensorTagTestEnabled = BCRawCharacteristicProfile<TISensorTag.SensorTagTestService.Enabled>()
        
        sensorTagTestService.addCharacteristic(sensorTagTestData)
        sensorTagTestService.addCharacteristic(sensorTagTestEnabled)
        profileManager.addService(sensorTagTestService)

        // Key Pressed Service
        let keyPressedService = BCConfiguredServiceProfile<TISensorTag.KeyPressedService>()
        let keyPressedStateCharacteristic = BCRawCharacteristicProfile<TISensorTag.KeyPressedService.State>()
        
        keyPressedService.addCharacteristic(keyPressedStateCharacteristic)
        profileManager.addService(keyPressedService)
    }
}
