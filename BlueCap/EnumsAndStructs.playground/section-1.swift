// Playground - noun: a place where people can play

import Foundation

protocol ProfileableEnum {
    var stringValue : String {get}
    class fromString(newValue:String) -> ProfileableEnum?
}

enum Enabled : UInt8, ProfileableEnum {
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

if let a = Enabled.fromRaw(1) {
    a.stringValue
}

if let a = Enabled.fromString("Noo") {
    a.stringValue
} else {
    println("invalid")
}


