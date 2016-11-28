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
    public struct AccelerometerService: ServiceConfigurable  {
        
        // ServiceConfigurable
        public static let uuid  = "F000AA10-0451-4000-B000-000000000000"
        public static let name  = "TI Accelerometer"
        public static let tag   = "TI Sensor Tag"
        
        // Accelerometer Data
        public struct Data: RawArrayDeserializable, CharacteristicConfigurable, StringDeserializable {
            
            fileprivate let xRaw: Int8
            fileprivate let yRaw: Int8
            fileprivate let zRaw: Int8
            
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
            
            fileprivate static func valuesFromRaw(_ rawValues: [Int8]) -> (Double, Double, Double) {
                return (-Double(rawValues[0])/64.0, -Double(rawValues[1])/64.0, Double(rawValues[2])/64.0)
            }
            
            fileprivate static func rawFromValues(_ values: [Double]) -> (Int8, Int8, Int8)? {
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
            public static let uuid                                      = "F000AA11-0451-4000-B000-000000000000"
            public static let name                                      = "Accelerometer Data"
            public static let properties: CBCharacteristicProperties    = [.read, .notify]
            public static let permissions: CBAttributePermissions       = [.readable, .writeable]
            public static let initialValue: Foundation.Data?            = SerDe.serialize(Data(x: 1.0, y: 0.5, z: -1.5)!)
            
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
                        let yRawInit = int8ValueFromStringValue("yRaw", values: stringValue),
                        let zRawInit = int8ValueFromStringValue("zRaw", values: stringValue) {
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
        public enum Enabled: UInt8, RawDeserializable, StringDeserializable, CharacteristicConfigurable {
            public typealias RawType = UInt8

            case no = 0
            case yes = 1
            
            // CharacteristicConfigurable
            public static let uuid = "F000AA12-0451-4000-B000-000000000000"
            public static let name = "Accelerometer Enabled"
            public static let properties: CBCharacteristicProperties = [.read, .write]
            public static let permissions: CBAttributePermissions = [.readable, .writeable]
            public static let initialValue: Foundation.Data? = SerDe.serialize(Enabled.no.rawValue)

            // StringDeserializable
            public static let stringValues = ["No", "Yes"]
            
            public init(boolValue: Bool) {
                if boolValue {
                    self = Enabled.yes
                } else {
                    self = Enabled.no
                }
            }
            
            public init?(stringValue: [String: String]) {
                if let value = stringValue[Enabled.name] {
                    switch value {
                    case "Yes":
                        self = Enabled.yes
                    case "No":
                        self = Enabled.no
                    default:
                        return nil
                    }
                } else {
                    return nil
                }
            }
            
            public var stringValue: [String: String] {
                switch self {
                case .no:
                    return [Enabled.name:"No"]
                case .yes:
                    return [Enabled.name:"Yes"]
                }
            }
            
            public var boolValue: Bool {
                switch self {
                case .no:
                    return false
                case .yes:
                    return true
                }
            }
        }

        // Accelerometer Update Period
        public struct UpdatePeriod: RawDeserializable, CharacteristicConfigurable, StringDeserializable {
            
            public let periodRaw: UInt8
            public let period: UInt16
            
            fileprivate static func valueFromRaw(_ rawValue:UInt8) -> UInt16 {
                var period = 10 * UInt16(rawValue)
                if period < 10 {
                    period = 10
                }
                return period
            }

            // CharacteristicConfigurable
            public static let uuid                                      = "F000AA13-0451-4000-B000-000000000000"
            public static let name                                      = "Accelerometer Update Period"
            public static let permissions: CBAttributePermissions       = [.readable, .writeable]
            public static let properties: CBCharacteristicProperties    = [.read, .write]
            public static let initialValue: Foundation.Data?            = SerDe.serialize(UInt8(100))
            
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
    public struct MagnetometerService: ServiceConfigurable {
        
        // ServiceConfigurable
        public static let uuid = "F000AA30-0451-4000-B000-000000000000"
        public static let name = "TI Magnetometer"
        public static let tag  = "TI Sensor Tag"

        public struct Data: RawArrayDeserializable, CharacteristicConfigurable, StringDeserializable {

            fileprivate let xRaw: Int16
            fileprivate let yRaw: Int16
            fileprivate let zRaw: Int16
            
            public let x: Double
            public let y: Double
            public let z: Double

            public static func valuesFromRaw(_ values: [Int16]) -> (Double, Double, Double) {
                let x = -Double(values[0])*2000.0/65536.0
                let y = -Double(values[1])*2000.0/65536.0
                let z = Double(values[2])*2000.0/65536.0
                return (x, y, z)
            }

            public static func rawFromValues(_ rawValues: [Double]) -> (Int16, Int16, Int16)? {
                if let xRaw = Int16(doubleValue: (-rawValues[0]*65536.0/2000.0)),
                       let yRaw = Int16(doubleValue: (-rawValues[1]*65536.0/2000.0)),
                       let zRaw = Int16(doubleValue: (rawValues[2]*65536.0/2000.0)) {
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
            public static let uuid                                      = "f000aa31-0451-4000-b000-000000000000"
            public static let name                                      = "Magnetometer Data"
            public static let properties: CBCharacteristicProperties    = [.read, .notify]
            public static let permissions: CBAttributePermissions       = [.readable, .writeable]
            public static let initialValue: Foundation.Data?            = SerDe.serialize(Data(rawValue: [-2183, 1916, 1255])!)
            
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
                       let yRawInit = int16ValueFromStringValue("yRaw", values: stringValue),
                       let zRawInit = int16ValueFromStringValue("zRaw", values: stringValue) {
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
        public enum Enabled: UInt8, RawDeserializable, StringDeserializable, CharacteristicConfigurable {
            public typealias RawType = UInt8

            case no     = 0
            case yes    = 1
            
            // CharacteristicConfigurable
            public static let uuid                                      = "f000aa32-0451-4000-b000-000000000000"
            public static let name                                      = "Magnetometer Enabled"
            public static let properties: CBCharacteristicProperties    = [.read, .write]
            public static let permissions: CBAttributePermissions       = [.readable, .writeable]
            public static let initialValue: Foundation.Data?            = SerDe.serialize(Enabled.no.rawValue)

            // StringDeserializable
            public static let stringValues = ["No", "Yes"]
            
            public init?(stringValue: [String: String]) {
                if let value = stringValue[Enabled.name] {
                    switch value {
                    case "Yes":
                        self = Enabled.yes
                    case "No":
                        self = Enabled.no
                    default:
                        return nil
                    }
                } else {
                    return nil
                }
            }
            
            public var stringValue: [String: String] {
                switch self {
                case .no:
                    return [Enabled.name:"No"]
                case .yes:
                    return [Enabled.name:"Yes"]
                }
            }
        }

        // Magnetometer UpdatePeriod
        public struct UpdatePeriod: RawDeserializable, CharacteristicConfigurable, StringDeserializable {
            
            public let periodRaw: UInt8
            public let period: UInt16
            
            fileprivate static func valueFromRaw(_ rawValue:UInt8) -> UInt16 {
                var period = 10*UInt16(rawValue)
                if period < 10 {
                    period = 10
                }
                return period
            }
            
            // CharacteristicConfigurable
            public static let uuid                                      = "f000aa33-0451-4000-b000-000000000000"
            public static let name                                      = "Magnetometer Update Period"
            public static let permissions: CBAttributePermissions       = [.readable, .writeable]
            public static let properties: CBCharacteristicProperties    = [.read, .write]
            public static let initialValue: Foundation.Data?            = SerDe.serialize(UInt16(5000))
            
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
    public struct GyroscopeService : ServiceConfigurable {

        // ServiceConfigurable
        public static let uuid  = "F000AA50-0451-4000-B000-000000000000"
        public static let name  = "TI Gyroscope"
        public static let tag   = "TI Sensor Tag"

        // Gyroscope Data
        public struct Data: RawArrayDeserializable, CharacteristicConfigurable, StringDeserializable {

            fileprivate let xRaw: Int16
            fileprivate let yRaw: Int16
            fileprivate let zRaw: Int16
            
            public let x: Double
            public let y: Double
            public let z: Double
            
            static func valuesFromRaw(_ values: [Int16]) -> (Double, Double, Double) {
                let x = -Double(values[0])*Double(500.0)/65536.0
                let y = -Double(values[1])*Double(500.0)/65536.0
                let z = Double(values[2])*Double(500.0)/65536.0
                return (x, y, z)
            }

            public static func rawFromValues(_ rawValues: [Double]) -> (Int16, Int16, Int16)? {
                if let xRaw = Int16(doubleValue:(-rawValues[0]*65536.0/500.0)), let yRaw = Int16(doubleValue:(-rawValues[1]*65536.0/500.0)), let zRaw = Int16(doubleValue:(rawValues[2]*65536.0/500.0)) {
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
            public static let uuid                                      = "f000aa51-0451-4000-b000-000000000000"
            public static let name                                      = "Gyroscope Data"
            public static let properties: CBCharacteristicProperties    = [.read, .notify]
            public static let permissions: CBAttributePermissions       = [.readable, .writeable]
            public static let initialValue: Foundation.Data?            = SerDe.serialize(Data(rawValue: [-24, -219, -23])!)

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
                       let yRawInit = int16ValueFromStringValue("yRaw", values: stringValue),
                       let zRawInit = int16ValueFromStringValue("zRaw", values: stringValue) {
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
        public enum Enabled : UInt8, RawDeserializable, StringDeserializable, CharacteristicConfigurable {
            public typealias RawType = UInt8

            case no         = 0
            case xAxis      = 1
            case yAxis      = 2
            case xyAxis     = 3
            case zAxis      = 4
            case xzAxis     = 5
            case yzAxis     = 6
            case xyzAxis    = 7
            
            // CharacteristicConfigurable
            public static let uuid                                      = "f000aa52-0451-4000-b000-000000000000"
            public static let name                                      = "Gyroscope Enabled"
            public static let properties: CBCharacteristicProperties    = [.read, .write]
            public static let permissions: CBAttributePermissions       = [.readable, .writeable]
            public static let initialValue: Foundation.Data?            = SerDe.serialize(Enabled.no.rawValue)

            // StringDeserializable
            public init?(stringValue: [String: String]) {
                if let value = stringValue[Enabled.name] {
                    switch value {
                    case "No":
                        self = Enabled.no
                    case "XAxis":
                        self =  Enabled.xAxis
                    case "YAxis":
                        self =  Enabled.yAxis
                    case "XYAxis":
                        self =  Enabled.xyAxis
                    case "ZAxis":
                        self =  Enabled.zAxis
                    case "XZAxis":
                        self =  Enabled.xzAxis
                    case "YZAxis":
                        self =  Enabled.yzAxis
                    case "XYZAxis":
                        self =  Enabled.xyzAxis
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
                case .no:
                    return [Enabled.name: "No"]
                case .xAxis:
                    return [Enabled.name: "XAxis"]
                case .yAxis:
                    return [Enabled.name: "YAxis"]
                case .xyAxis:
                    return [Enabled.name: "XYAxis"]
                case .zAxis:
                    return [Enabled.name: "ZAxis"]
                case .xzAxis:
                    return [Enabled.name: "XZAxis"]
                case .yzAxis:
                    return [Enabled.name: "YZAxis"]
                case .xyzAxis:
                    return [Enabled.name: "XYZAxis"]
                }
            }
        }
    }

    // MARK: - Temperature Service units Celsius -
    public struct TemperatureService : ServiceConfigurable {
        
        public static let uuid  = "F000AA00-0451-4000-B000-000000000000"
        public static let name  = "TI Temperature"
        public static let tag   = "TI Sensor Tag"

        public struct Data: RawArrayDeserializable, CharacteristicConfigurable, StringDeserializable {

            fileprivate let objectRaw: Int16
            fileprivate let ambientRaw: Int16
            
            public let object: Double
            public let ambient: Double

            static func valuesFromRaw(_ objectRaw: Int16, ambientRaw: Int16) -> (Double, Double) {
                let ambient = Double(ambientRaw)/128.0
                let vObj2 = Double(objectRaw)*0.00000015625
                let tDie2 = ambient + 273.15
                let s0 = 6.4*pow(10.0, -14.0)
                let a1 = 1.75*pow(10.0, -3.0)
                let a2 = -1.678*pow(10.0, -5.0)
                let b0 = -2.94*pow(10.0, -5.0)
                let b1 = -5.7*pow(10.0, -7.0)
                let b2 = 4.63*pow(10.0, -9.0)
                let c2 = 13.4
                let tRef = 298.15
                let s1 = (tDie2 - tRef)
                let s2 = pow((tDie2 - tRef), 2.0)
                let s = s0*(1 + a1*s1 + a2*s2);
                let vOs = b0 + b1*(tDie2 - tRef) + b2*pow((tDie2 - tRef), 2.0);
                let fObj = (vObj2 - vOs) + c2*pow((vObj2 - vOs),2);
                let object = pow(pow(tDie2,4) + (fObj/s),0.25) - 273.15;
                return (object, ambient)
            }
            
            // CharacteristicConfigurable
            public static let uuid                                      = "f000aa01-0451-4000-b000-000000000000"
            public static let name                                      = "Temperature Data"
            public static let properties: CBCharacteristicProperties    = [.read, .notify]
            public static let permissions: CBAttributePermissions       = [.readable, .writeable]
            public static let initialValue: Foundation.Data?            = SerDe.serialize(Data(rawValue: [-172, 3388])!)

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
                if let objectRawInit = int16ValueFromStringValue("objectRaw", values:stringValue), let ambientRawInit = int16ValueFromStringValue("ambientRaw", values:stringValue) {
                    self.objectRaw = objectRawInit
                    self.ambientRaw = ambientRawInit
                    (self.object, self.ambient) = Data.valuesFromRaw(self.objectRaw, ambientRaw:self.ambientRaw)
                } else {
                    return nil
                }
            }
        }
        
        // Temperature Enabled
        public enum Enabled: UInt8, RawDeserializable, StringDeserializable, CharacteristicConfigurable {
            public typealias RawType = UInt8

            case no     = 0
            case yes    = 1
            
            // CharacteristicConfigurable
            public static let uuid                                      = "f000aa02-0451-4000-b000-000000000000"
            public static let name                                      = "Temperature Enabled"
            public static let properties: CBCharacteristicProperties    = [.read, .write]
            public static let permissions: CBAttributePermissions       = [.readable, .writeable]
            public static let initialValue: Foundation.Data?            = SerDe.serialize(Enabled.no.rawValue)

            // StringDeserializable
            public static let stringValues = ["No", "Yes"]
            
            public init?(stringValue: [String: String]) {
                if let value = stringValue[Enabled.name] {
                    switch value {
                    case "Yes":
                        self = .yes
                    case "No":
                        self = .no
                    default:
                        return nil
                    }
                } else {
                    return nil
                }
            }
            
            public var stringValue : [String : String] {
                switch self {
                case .no:
                    return [Enabled.name : "No"]
                case .yes:
                    return [Enabled.name :"Yes"]
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
    public struct BarometerService : ServiceConfigurable {
        
        // ServiceConfigurable
        public static let uuid = "F000AA40-0451-4000-B000-000000000000"
        public static let name = "TI Barometer"
        public static let tag  = "TI Sensor Tag"

        public struct Data : RawPairDeserializable, CharacteristicConfigurable, StringDeserializable {

            public let temperatureRaw: Int16
            public let pressureRaw: UInt16
            
            // CharacteristicConfigurable
            public static let uuid                                      = "f000aa41-0451-4000-b000-000000000000"
            public static let name                                      = "Baraometer Data"
            public static let properties: CBCharacteristicProperties    = [.read, .notify]
            public static let permissions: CBAttributePermissions       = [.readable, .writeable]
            public static let initialValue: Foundation.Data?            = SerDe.serialize(Data(rawValue1:-2343, rawValue2:33995)!)

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
                       let pressureRawInit = uint16ValueFromStringValue("pressureRaw", values: stringValue) {
                    self.temperatureRaw = temperatureRawInit
                    self.pressureRaw = pressureRawInit
                } else {
                    return nil
                }
            }
            
        }
    
        // Barometer Calibration
        public struct Calibration: RawArrayPairDeserializable, CharacteristicConfigurable, StringDeserializable {

            public let c1 : UInt16
            public let c2 : UInt16
            public let c3 : UInt16
            public let c4 : UInt16
            
            public let c5 : Int16
            public let c6 : Int16
            public let c7 : Int16
            public let c8 : Int16
            
            // CharacteristicConfigurable
            public static let uuid                                      = "f000aa43-0451-4000-b000-000000000000"
            public static let name                                      = "Baraometer Calibration Data"
            public static let properties: CBCharacteristicProperties    = [.read, .notify]
            public static let permissions: CBAttributePermissions       = [.readable, .writeable]
            public static let initialValue: Foundation.Data?            = SerDe.serialize(Calibration(rawValue1:[45697, 25592, 48894, 36174], rawValue2:[7001, 1990, -2369, 5542])!)

            // RawArrayPairDeserializable
            public static var size1: Int {
                return 4*MemoryLayout<UInt16>.size
            }

            public static var size2: Int {
                return 4*MemoryLayout<Int16>.size
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
                       let c2Init = uint16ValueFromStringValue("c2", values: stringValue),
                       let c3Init = uint16ValueFromStringValue("c3", values: stringValue),
                       let c4Init = uint16ValueFromStringValue("c4", values: stringValue),
                       let c5Init = int16ValueFromStringValue("c5", values: stringValue),
                       let c6Init = int16ValueFromStringValue("c6", values: stringValue),
                       let c7Init = int16ValueFromStringValue("c7", values: stringValue),
                       let c8Init = int16ValueFromStringValue("c8", values: stringValue) {
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
        public enum Enabled: UInt8, RawDeserializable, StringDeserializable, CharacteristicConfigurable {
            public typealias RawType = UInt8

            case no         = 0
            case yes        = 1
            case calibrate  = 2
            
            // CharacteristicConfigurable
            public static let uuid                                      = "f000aa42-0451-4000-b000-000000000000"
            public static let name                                      = "Baraometer Enabled"
            public static let properties: CBCharacteristicProperties    = [.read, .write]
            public static let permissions: CBAttributePermissions       = [.readable, .writeable]
            public static let initialValue: Foundation.Data?                     = SerDe.serialize(Enabled.no.rawValue)

            // StringDeserializable
            public static let stringValues =  ["No", "Yes", "Calibrate"]
            
            public init?(stringValue:[String:String]) {
                if let value = stringValue[Enabled.name] {
                    switch value {
                    case "Yes":
                        self = Enabled.yes
                    case "No":
                        self = Enabled.no
                    case "Calibrate":
                        self = Enabled.calibrate
                    default:
                        return nil
                    }
                } else {
                    return nil
                }
            }
            
            public var stringValue : [String:String] {
                switch self {
                case .no:
                    return [Enabled.name:"No"]
                case .yes:
                    return [Enabled.name:"Yes"]
                case .calibrate:
                    return [Enabled.name:"Yes"]
                }
            }
        }
    }

    // MARK: - Hygrometer Service -
    // Temperature units Celsius
    // Humidity units Relative Humdity
    public struct HygrometerService: ServiceConfigurable {
        
        // ServiceConfigurable
        public static let uuid = "F000AA20-0451-4000-B000-000000000000"
        public static let name = "TI Hygrometer"
        public static let tag  = "TI Sensor Tag"

        public struct Data: RawArrayDeserializable, CharacteristicConfigurable, StringDeserializable {

            public var temperatureRaw  : UInt16
            public var humidityRaw     : UInt16
            
            public var temperature     : Double
            public var humidity        : Double
            
            fileprivate static func valuesFromRaw(_ temperatureRaw:UInt16, humidityRaw:UInt16) -> (Double, Double) {
                return (-46.86+175.72*Double(temperatureRaw)/65536.0, -6.0+125.0*Double(humidityRaw)/65536.0)
            }

            // CharacteristicConfigurable
            public static let uuid                                      = "f000aa21-0451-4000-b000-000000000000"
            public static let name                                      = "Hygrometer Data"
            public static let properties: CBCharacteristicProperties    = [.read, .notify]
            public static let permissions: CBAttributePermissions       = [.readable, .writeable]
            public static let initialValue: Foundation.Data?                     = SerDe.serialize(Data(rawValue:[2600, 3500])!)
            
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
        public enum Enabled:UInt8, RawDeserializable, StringDeserializable, CharacteristicConfigurable {
            public typealias RawType = UInt8

            case no     = 0
            case yes    = 1
            
            // CharacteristicConfigurable
            public static let uuid                                      = "f000aa22-0451-4000-b000-000000000000"
            public static let name                                      = "Hygrometer Enabled"
            public static let properties: CBCharacteristicProperties    = [.read, .write]
            public static let permissions: CBAttributePermissions       = [.readable, .writeable]
            public static let initialValue: Foundation.Data?                     = SerDe.serialize(Enabled.no.rawValue)

            // StringDeserializable
            public static let stringValues = ["No", "Yes"]
            
            public var stringValue : [String:String] {
                switch self {
                case .no:
                    return [Enabled.name:"No"]
                case .yes:
                    return [Enabled.name:"Yes"]
                }
            }

            public init?(stringValue: [String: String]) {
                if let value = stringValue[Enabled.name] {
                    switch value {
                    case "Yes":
                        self = Enabled.yes
                    case "No":
                        self = Enabled.no
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
    public struct SensorTagTestService: ServiceConfigurable {
        
        // ServiceConfigurable
        public static let uuid  = "F000AA60-0451-4000-B000-000000000000"
        public static let name  = "TI Sensor Tag Test"
        public static let tag   = "TI Sensor Tag"
        
        public struct Data: RawDeserializable, CharacteristicConfigurable, StringDeserializable {

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
            public static let uuid                                      = "f000aa61-0451-4000-b000-000000000000"
            public static let name                                      = "Test Data"
            public static let properties: CBCharacteristicProperties    = .read
            public static let permissions: CBAttributePermissions       = [.readable, .writeable]
            public static let initialValue: Foundation.Data?                     = SerDe.serialize(0b11110000 as UInt8)

            fileprivate static func valuesFromRaw(_ rawValue:UInt8) -> [Bool] {
                return [self.testResult(rawValue, position: 0), self.testResult(rawValue, position: 1),
                        self.testResult(rawValue, position: 2), self.testResult(rawValue, position: 3),
                        self.testResult(rawValue, position: 4), self.testResult(rawValue, position: 5),
                        self.testResult(rawValue, position: 6), self.testResult(rawValue, position: 7)]
            }
            
            fileprivate static func testResult(_ rawResult: UInt8, position: UInt8) -> Bool {
                return (rawResult & (1 << position)) > 0
            }
            
            fileprivate static func testResultStringValue(_ value: Bool) -> String {
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
    
        public enum Enabled: UInt8, RawDeserializable, StringDeserializable, CharacteristicConfigurable {
            public typealias RawType = UInt8

            case no     = 0
            case yes    = 1
            
            // CharacteristicConfigurable
            public static let uuid                                      = "f000aa62-0451-4000-b000-000000000000"
            public static let name                                      = "Test Enabled"
            public static let properties: CBCharacteristicProperties    = [.read, .write]
            public static let permissions: CBAttributePermissions       = [.readable, .writeable]
            public static let initialValue: Foundation.Data?                     = SerDe.serialize(Enabled.no.rawValue)
            
            // StringDeserializable
            public static let stringValues = ["No", "Yes"]
            
            public init?(stringValue: [String:String]) {
                if let value = stringValue[Enabled.name] {
                    switch value {
                    case "Yes":
                        self = Enabled.yes
                    case "No":
                        self = Enabled.no
                    default:
                        return nil
                    }
                } else {
                    return nil
                }
            }
            
            public var stringValue: [String: String] {
                switch self {
                case .no:
                    return [Enabled.name: "No"]
                case .yes:
                    return [Enabled.name: "Yes"]
                }
            }
        }

    }

    // MARK: - Key Pressed Service -
    public struct KeyPressedService : ServiceConfigurable {

        public static let uuid = "ffe0"
        public static let name = "Sensor Tag Key Pressed"
        public static let tag  = "TI Sensor Tag"

        public enum State : UInt8, RawDeserializable, CharacteristicConfigurable, StringDeserializable {
            public typealias RawType = UInt8

            case none       = 0
            case buttonOne  = 1
            case buttonTwo  = 2
            
            // CharacteristicConfigurable
            public static let uuid                                      = "ffe1"
            public static let name                                      = "Key Pressed"
            public static let properties: CBCharacteristicProperties    = .notify
            public static let permissions: CBAttributePermissions       = [.readable, .writeable]
            public static let initialValue: Data?                     = SerDe.serialize(0x01 as UInt8)

            // StringDeserializable
            public static let stringValues = ["None", "Button One", "Button Two"]
            
            public var stringValue: [String: String] {
                switch self {
                case .none:
                    return [State.name: "None"]
                case .buttonOne:
                    return [State.name: "Button One"]
                case .buttonTwo:
                    return [State.name: "Button Two"]
                }
            }

            public init?(stringValue:[String:String]) {
                if let value = stringValue[State.name] {
                    switch value {
                    case "None":
                        self = State.none
                    case "Button One":
                        self = State.buttonOne
                    case "Button Two":
                        self = State.buttonTwo
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

    public static func create(profileManager: ProfileManager) {

        // Accelerometer Service
        let accelerometerService = ConfiguredServiceProfile<TISensorTag.AccelerometerService>()
        let accelerometerDataCharacteristic = RawArrayCharacteristicProfile<TISensorTag.AccelerometerService.Data>()
        let accelerometerEnabledCharacteristic = RawCharacteristicProfile<TISensorTag.AccelerometerService.Enabled>()
        let accelerometerUpdatePeriodCharacteristic = RawCharacteristicProfile<TISensorTag.AccelerometerService.UpdatePeriod>()
        
        accelerometerService.addCharacteristic(accelerometerDataCharacteristic)
        accelerometerService.addCharacteristic(accelerometerEnabledCharacteristic)
        accelerometerService.addCharacteristic(accelerometerUpdatePeriodCharacteristic)
        profileManager.addService(accelerometerService)

        // Magnetometer Service
        let magnetometerService = ConfiguredServiceProfile<TISensorTag.MagnetometerService>()
        let magnetometerDataCharacteristic = RawArrayCharacteristicProfile<TISensorTag.MagnetometerService.Data>()
        let magnetometerEnabledCharacteristic = RawCharacteristicProfile<TISensorTag.MagnetometerService.Enabled>()
        let magnetometerUpdatePeriodCharacteristic = RawCharacteristicProfile<TISensorTag.MagnetometerService.UpdatePeriod>()
        
        magnetometerService.addCharacteristic(magnetometerDataCharacteristic)
        magnetometerService.addCharacteristic(magnetometerEnabledCharacteristic)
        magnetometerService.addCharacteristic(magnetometerUpdatePeriodCharacteristic)
        profileManager.addService(magnetometerService)
        
        // Gyroscope Service
        let gyroscopeService = ConfiguredServiceProfile<TISensorTag.GyroscopeService>()
        let gyroscopeDataCharacteristic = RawArrayCharacteristicProfile<TISensorTag.GyroscopeService.Data>()
        let gyroscopeEnabledCharacteristic = RawCharacteristicProfile<TISensorTag.GyroscopeService.Enabled>()
        
        gyroscopeService.addCharacteristic(gyroscopeDataCharacteristic)
        gyroscopeService.addCharacteristic(gyroscopeEnabledCharacteristic)
        profileManager.addService(gyroscopeService)
        

        // Temperature Service
        let temperatureService = ConfiguredServiceProfile<TISensorTag.TemperatureService>()
        let temperatureDataCharacteristic = RawArrayCharacteristicProfile<TISensorTag.TemperatureService.Data>()
        let temperatureEnabledCharacteristic = RawCharacteristicProfile<TISensorTag.TemperatureService.Enabled>()
        
        temperatureService.addCharacteristic(temperatureDataCharacteristic)
        temperatureService.addCharacteristic(temperatureEnabledCharacteristic)
        profileManager.addService(temperatureService)
        
        // Barometer Service
        let barometerService = ConfiguredServiceProfile<TISensorTag.BarometerService>()
        let barometerDataCharacteristic = RawPairCharacteristicProfile<TISensorTag.BarometerService.Data>()
        let barometerCalibrationCharacteristic = RawArrayPairCharacteristicProfile<TISensorTag.BarometerService.Calibration>()
        let barometerEnabledCharacteristic = RawCharacteristicProfile<TISensorTag.BarometerService.Enabled>()
        
        barometerService.addCharacteristic(barometerDataCharacteristic)
        barometerService.addCharacteristic(barometerCalibrationCharacteristic)
        barometerService.addCharacteristic(barometerEnabledCharacteristic)
        profileManager.addService(barometerService)
        
        // Hygrometer Service
        let hygrometerService = ConfiguredServiceProfile<TISensorTag.HygrometerService>()
        let hygrometerDataCharacteristic = RawArrayCharacteristicProfile<TISensorTag.HygrometerService.Data>()
        let hygrometerEnabledCharacteristic = RawCharacteristicProfile<TISensorTag.HygrometerService.Enabled>()
        
        hygrometerService.addCharacteristic(hygrometerDataCharacteristic)
        hygrometerService.addCharacteristic(hygrometerEnabledCharacteristic)
        profileManager.addService(hygrometerService)
        

        // Sensor Tag Test Service
        let sensorTagTestService = ConfiguredServiceProfile<TISensorTag.SensorTagTestService>()
        let sensorTagTestData = RawCharacteristicProfile<TISensorTag.SensorTagTestService.Data>()
        let sensorTagTestEnabled = RawCharacteristicProfile<TISensorTag.SensorTagTestService.Enabled>()
        
        sensorTagTestService.addCharacteristic(sensorTagTestData)
        sensorTagTestService.addCharacteristic(sensorTagTestEnabled)
        profileManager.addService(sensorTagTestService)

        // Key Pressed Service
        let keyPressedService = ConfiguredServiceProfile<TISensorTag.KeyPressedService>()
        let keyPressedStateCharacteristic = RawCharacteristicProfile<TISensorTag.KeyPressedService.State>()
        
        keyPressedService.addCharacteristic(keyPressedStateCharacteristic)
        profileManager.addService(keyPressedService)
    }
}
