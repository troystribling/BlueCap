// Playground - noun: a place where people can play

// Playground - noun: a place where people can play

import UIKit
import BlueCapKit

enum Enabled : UInt8, RawDeserializable {
    case Yes = 0
    case No = 1
    static let uuid = "abc"
}

if let test = Enabled(rawValue:1) {
    println(test.rawValue)
}

