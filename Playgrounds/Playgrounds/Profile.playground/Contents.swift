//: Playground - noun: a place where people can play

import UIKit
import BlueCapKit
import CoreBluetooth

// RawCharacteristicProfile
enum Enabled : UInt8, RawDeserializable, StringDeserializable, CharacteristicConfigurable {
    public typealias RawType = UInt8
    
    case no     = 0
    case yes    = 1
    
    // CharacteristicConfigurable
    static let uuid = "F000AA12-0451-4000-B000-000000000000"
    static let name = "Accelerometer Enabled"
    static let properties: CBCharacteristicProperties = [.read, .write]
    static let permissions: CBAttributePermissions = [.readable, .writeable]
    static let initialValue: Data? = SerDe.serialize(Enabled.no.rawValue)
    
    // StringDeserializable
    static let stringValues = ["no", "yes"]
    
    init?(stringValue:[String : String]) {
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
    
    var stringValue : [String:String] {
        switch self {
        case .no:
            return [Enabled.name: "no"]
        case .yes:
            return [Enabled.name: "yes"]
        }
    }
}

if let value = Enabled(stringValue:[Enabled.name:"Yes"]) {
    print(value.stringValue)
}

// RawArrayCharacteristicProfile
struct ArrayData : RawArrayDeserializable, CharacteristicConfigurable, StringDeserializable {
    
    // CharacteristicConfigurable
    static let uuid = "F000AA11-0451-4000-B000-000000000000"
    static let name = "Accelerometer Data"
    static let properties: CBCharacteristicProperties = [.read, .write]
    static let permissions: CBAttributePermissions = [.readable, .writeable]
    static let initialValue: Data? = SerDe.serialize(ArrayData(rawValue: [1,2])!)
    
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
    
    var stringValue : [String : String] {
        return ["value1" : "\(self.rawValue[0])",
            "value2" : "\(self.rawValue[1])"]
    }
    
    init?(stringValue:[String:String]) {
        if  let stringValue1 = stringValue["value1"],
            let stringValue2 = stringValue["value2"],
            let value1 = Int8(stringValue1),
            let value2 = Int8(stringValue2) {
                self.rawValue = [value1, value2]
        } else {
            return nil
        }
    }
}

if let value = ArrayData(rawValue: [1, 100]) {
    print(value.rawValue)
}

if let value = ArrayData(stringValue:["value1":"1", "value2":"100"]) {
    print(value.stringValue)
}

// RawPairCharacteristicProfile
struct PairData : RawPairDeserializable, CharacteristicConfigurable, StringDeserializable {
    
    // CharacteristicConfigurable
    static let uuid = "F000AA30-0451-4000-B000-000000000000"
    static let name = "Magnetometer Data"
    static let properties: CBCharacteristicProperties = [.read, .notify]
    static let permissions: CBAttributePermissions = [.readable, .writeable]
    static let initialValue: Data? = SerDe.serialize(PairData(rawValue1: 10, rawValue2: -10)!)
    
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
        if let stringValue1 = stringValue["value1"],
           let stringValue2 = stringValue["value2"],
           let value1 = UInt8(stringValue1),
           let value2 = Int8(stringValue2) {
                self.rawValue1 = value1
                self.rawValue2 = value2
        } else {
            return nil
        }
    }
}

if let value = PairData(stringValue:["value1":"1", "value2":"-2"]) {
    print(value.stringValue)
}


// RawArrayPairCharacteristicProfile
struct ArrayPairData : RawArrayPairDeserializable, CharacteristicConfigurable, StringDeserializable {
    
    // CharacteristicConfigurable
    static let uuid = "F000AA11-0451-4000-B000-000000000000"
    static let name = "Accelerometer Data"
    static let properties: CBCharacteristicProperties = [.read, .notify]
    static let permissions: CBAttributePermissions = [.readable, .writeable]
    static let initialValue: Data? = SerDe.serialize(ArrayPairData(rawValue1: [1,2], rawValue2: [-1, -2])!)
    
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
            let stringValue12 = stringValue["value12"],
            let value11 = UInt8(stringValue11),
            let value12 = UInt8(stringValue12),
            let stringValue21 = stringValue["value21"],
            let stringValue22 = stringValue["value22"],
            let value21 = Int8(stringValue21),
            let value22 = Int8(stringValue22) {
                self.rawValue1 = [value11, value12]
                self.rawValue2 = [value21, value22]
        } else {
            return nil
        }
    }
}

if let value = ArrayPairData(stringValue:["value11" : "1", "value12" : "2", "value21" : "-1", "value22" : "-2"]) {
    print(value.stringValue)
}

// StringCharacteristicProfile
struct SerialNumber : CharacteristicConfigurable {
    // CharacteristicConfigurable
    static let uuid = "2a25"
    static let name = "Device Serial Number"
    static let permissions: CBAttributePermissions = [.readable, .writeable]
    static let properties: CBCharacteristicProperties = [.read]
    static let initialValue = SerDe.serialize("AAA11")
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
        public static let properties: CBCharacteristicProperties = [.read, .write]
        public static let permissions: CBAttributePermissions = [.readable, .writeable]
        public static let initialValue: Data? = SerDe.serialize(Int16(22))
        
        public static let stringValues = [String]()
        
        public init?(stringValue:[String:String]) {
            if let svalue = stringValue[Number.name], let value = Int16(svalue) {
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
        let profileManager = ProfileManager()
        let service = ConfiguredServiceProfile<NumberService>()
        let characteristic = RawCharacteristicProfile<Number>()
        service.addCharacteristic(characteristic)
        profileManager.addService(service)
    }
    
}

