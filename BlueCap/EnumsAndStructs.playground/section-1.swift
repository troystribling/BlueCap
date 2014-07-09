// Playground - noun: a place where people can play

import Foundation

protocol ProfileableEnumStatic {
    typealias EnumType
    class func fromRaw(newValue:UInt8) -> EnumType?
    class func fromString(newValue:String) -> EnumType?
}

protocol ProfileableEnumInstance {
    var stringValue : String {get}
    func toRaw() -> Byte
    
}

enum Enabled : Byte, ProfileableEnumStatic, ProfileableEnumInstance {
    case No     = 0
    case Yes    = 1
    var stringValue : String {
        get {
            switch self {
            case .No:
                return "No"
            case .Yes:
                return "Yes"
            }
        }
    }
    static func fromString(newValue:String) -> Enabled? {
        switch newValue {
        case "No":
            return Enabled.No
        case "Yes":
            return Enabled.Yes
        default:
            return nil
        }
    }

}

class Profile<EnumType:ProfileableEnumStatic where EnumType.EnumType:ProfileableEnumInstance> {

    func fromString(value:String) -> EnumType.EnumType? {
        return EnumType.fromString(value)
    }
    
    func fromByte(value:Byte) -> EnumType.EnumType? {
        return EnumType.fromRaw(value)
    }

}

if let a = Enabled.fromRaw(1) {
    a.stringValue
    a.toRaw()
}

if let a = Enabled.fromString("No") {
    a.stringValue
} else {
    println("invalid")
}

var testing = Profile<Enabled>()
testing.fromString("Yes") == Enabled.Yes