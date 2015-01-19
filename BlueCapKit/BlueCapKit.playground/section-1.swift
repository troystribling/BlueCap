// Playground - noun: a place where people can play

// Playground - noun: a place where people can play

import UIKit
import BlueCapKit

enum Enabled : UInt8, DeserializedEnum {
    case Yes = 0
    case No = 1
    
    static func fromRaw(rawValue:UInt8) -> Enabled? {
        return Enabled(rawValue:rawValue)
    }
    
    static func fromString(stringValue:[String:String]) -> Enabled? {
        if let value = stringValue["Enabled"] {
            switch value {
            case "Yes":
                return Enabled.Yes
            case "No":
                return Enabled.No
            default:
                return nil
            }
        } else {
            return nil
        }
    }
    
    static func stringValues() -> [String] {
        return ["Yes", "No"]
    }
    
    var stringValue : [String:String] {
        switch self {
        case .Yes:
            return ["Enabled":"Yes"]
        case .No:
            return ["Enabled":"No"]
        }
    }
    
}

if let test = Enabled(rawValue:1) {
    println(test.rawValue)
}

