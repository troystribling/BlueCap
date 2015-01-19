// Playground - noun: a place where people can play

// Playground - noun: a place where people can play

import UIKit
import BlueCapKit

enum Enabled : UInt8, DeserializedEnum {
    case Yes = 0
    case No = 1
    
    static func fromString(stringValue:String) -> Enabled? {
        switch stringValue {
        case "Yes":
            return Enabled.Yes
        case "No":
            return Enabled.No
        default:
            return nil
        }
    }
    
    static func stringValues() -> [String] {
        return ["Yes", "No"]
    }
    
    var stringValue : String {
        switch self {
        case .Yes:
            return "Yes"
        case .No:
            return "No"
        }
    }

}

if let test = Enabled(rawValue:1) {
    println(test.rawValue)
}
