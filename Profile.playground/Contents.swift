//: Playground - noun: a place where people can play

import UIKit
import BlueCapKit
import CoreBluetooth

// RawCharacteristicProfile
enum Enabled : UInt8, RawDeserializable, StringDeserializable, CharacteristicConfigurable {
    case No     = 0
    case Yes    = 1
    
    // CharacteristicConfigurable
    static let uuid = "F000AA12-0451-4000-B000-000000000000"
    static let name = "Accelerometer Enabled"
    static let properties = CBCharacteristicProperties.Read | CBCharacteristicProperties.Write
    static let permissions = CBAttributePermissions.Readable | CBAttributePermissions.Writeable
    static let initialValue : NSData? = Serde.serialize(Enabled.No.rawValue)
    
    // StringDeserializable
    static let stringValues = ["No", "Yes"]
    
    init?(stringValue:[String:String]) {
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
    
    var stringValue : [String:String] {
        switch self {
        case .No:
            return [Enabled.name:"No"]
        case .Yes:
            return [Enabled.name:"Yes"]
        }
    }
}

if let value = Enabled(stringValue:[Enabled.name:"Yes"]) {
    println(value.stringValue)
}

// RawArrayCharacteristicProfile
struct ArrayData : RawArrayDeserializable, CharacteristicConfigurable, StringDeserializable {
    
    // CharacteristicConfigurable
    static let uuid = "F000AA11-0451-4000-B000-000000000000"
    static let name = "Accelerometer Data"
    static let properties = CBCharacteristicProperties.Read | CBCharacteristicProperties.Notify
    static let permissions = CBAttributePermissions.Readable | CBAttributePermissions.Writeable
    static let initialValue : NSData? = Serde.serialize(ArrayData(rawValue:[1,2])!)
    
    // RawArrayDeserializable
    let rawValue : [Int8]
    static let size = 2
    
    init?(rawValue:[Int8]) {
        if rawValue.count == 2 {
            self.rawValue = rawValue
        } else {
            return nil
        }
    }
    
    // StringDeserializable
    static let stringValues = [String]()
    
    var stringValue : Dictionary<String,String> {
        return ["value1":"\(self.rawValue[0])",
            "value2":"\(self.rawValue[1])"]
    }
    
    init?(stringValue:[String:String]) {
        if  let stringValue1 = stringValue["value1"],
            stringValue2 = stringValue["value2"],
            value1 = Int8(stringValue:stringValue1),
            value2 = Int8(stringValue:stringValue2) {
                self.rawValue = [value1, value2]
        } else {
            return nil
        }
    }
}

if let value = ArrayData(stringValue:["value1":"1", "value2":"100"]) {
    println(value.stringValue)
}

// RawPairCharacteristicProfile
struct PairData : RawPairDeserializable, CharacteristicConfigurable, StringDeserializable {
    
    // CharacteristicConfigurable
    static let uuid = "F000AA30-0451-4000-B000-000000000000"
    static let name = "Magnetometer Data"
    static let properties = CBCharacteristicProperties.Read | CBCharacteristicProperties.Notify
    static let permissions = CBAttributePermissions.Readable | CBAttributePermissions.Writeable
    static let initialValue : NSData? = Serde.serialize(PairData(rawValue1:10, rawValue2:-10)!)
    
    // RawArrayDeserializable
    let rawValue1 : UInt8
    let rawValue2 : Int8
    
    init?(rawValue1:UInt8, rawValue2:Int8) {
        self.rawValue1 = rawValue1
        self.rawValue2 = rawValue2
    }
    
    // StringDeserializable
    static let stringValues = [String]()
    
    var stringValue : Dictionary<String,String> {
        return ["value1":"\(self.rawValue1)",
            "value2":"\(self.rawValue2)"]}
    
    init?(stringValue:[String:String]) {
        if  let stringValue1 = stringValue["value1"],
            stringValue2 = stringValue["value2"],
            value1 = UInt8(stringValue:stringValue1),
            value2 = Int8(stringValue:stringValue2) {
                self.rawValue1 = value1
                self.rawValue2 = value2
        } else {
            return nil
        }
    }
}

if let value = PairData(stringValue:["value1":"1", "value2":"-2"]) {
    println(value.stringValue)
}


// RawArrayPairCharacteristicProfile
struct ArrayPairData : RawArrayPairDeserializable, CharacteristicConfigurable, StringDeserializable {
    
    // CharacteristicConfigurable
    static let uuid = "F000AA11-0451-4000-B000-000000000000"
    static let name = "Accelerometer Data"
    static let properties = CBCharacteristicProperties.Read | CBCharacteristicProperties.Notify
    static let permissions = CBAttributePermissions.Readable | CBAttributePermissions.Writeable
    static let initialValue : NSData? = Serde.serialize(ArrayPairData(rawValue1:[1,2], rawValue2:[-1, -2])!)
    
    // RawArrayDeserializable
    let rawValue1 : [UInt8]
    let rawValue2 : [Int8]
    static let size1 = 2
    static let size2 = 2
    
    init?(rawValue1:[UInt8], rawValue2:[Int8]) {
        if rawValue1.count == 2 && rawValue2.count == 2 {
            self.rawValue1 = rawValue1
            self.rawValue2 = rawValue2
        } else {
            return nil
        }
    }
    
    // StringDeserializable
    static let stringValues = [String]()
    
    var stringValue : Dictionary<String,String> {
        return ["value11":"\(self.rawValue1[0])",
            "value12":"\(self.rawValue1[1])",
            "value21":"\(self.rawValue2[0])",
            "value22":"\(self.rawValue2[1])"]}
    
    init?(stringValue:[String:String]) {
        if  let stringValue11 = stringValue["value11"],
            stringValue12 = stringValue["value12"],
            value11 = UInt8(stringValue:stringValue11),
            value12 = UInt8(stringValue:stringValue12),
            stringValue21 = stringValue["value21"],
            stringValue22 = stringValue["value22"],
            value21 = Int8(stringValue:stringValue21),
            value22 = Int8(stringValue:stringValue22) {
                self.rawValue1 = [value11, value12]
                self.rawValue2 = [value21, value22]
        } else {
            return nil
        }
    }
}

if let value = ArrayPairData(stringValue:["value11":"1", "value12":"2", "value21":"-1", "value22":"-2"]) {
    println(value.stringValue)
}

// StringCharacteristicProfile
struct SerialNumber : CharacteristicConfigurable {
    // CharacteristicConfigurable
    static let uuid = "2a25"
    static let name = "Device Serial Number"
    static let permissions  = CBAttributePermissions.Readable | CBAttributePermissions.Writeable
    static let properties   = CBCharacteristicProperties.Read
    static let initialValue = Serde.serialize("AAA11")
}

let stringProfile = StringCharacteristicProfile<SerialNumber>()

// MyServices
public struct MyServices {
    
    // Service
    public struct NumberService : ServiceConfigurable  {
        public static let uuid  = "F000AA10-0451-4000-B000-000000000000"
        public static let name  = "NumberService"
        public static let tag   = "My Services"
    }
    
    // Characteristic
    public struct Number : RawDeserializable, StringDeserializable, CharacteristicConfigurable {
        
        public let rawValue : Int16
        
        public init?(rawValue:Int16) {
            self.rawValue = rawValue
        }
        
        public static let uuid = "F000AA12-0451-4000-B000-000000000000"
        public static let name = "Number"
        public static let properties = CBCharacteristicProperties.Read | CBCharacteristicProperties.Write
        public static let permissions = CBAttributePermissions.Readable | CBAttributePermissions.Writeable
        public static let initialValue : NSData? = Serde.serialize(Int16(22))
        
        public static let stringValues = [String]()
        
        public init?(stringValue:[String:String]) {
            if let svalue = stringValue[Number.name], value = Int16(stringValue:svalue) {
                self.rawValue = value
            } else {
                return nil
            }
        }
        
        public var stringValue : [String:String] {
            return [Number.name:"\(self.rawValue)"]
        }
    }
    
    // add to ProfileManager
    public static func create() {
        let profileManager = ProfileManager.sharedInstance
        let service = ConfiguredServiceProfile<NumberService>()
        let characteristic = RawCharacteristicProfile<Number>()
        service.addCharacteristic(characteristic)
        profileManager.addService(service)
    }
    
}


