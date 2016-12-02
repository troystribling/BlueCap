// Playground - noun: a place where people can play

import UIKit
import BlueCapKit
import CoreBluetooth

// Strings
if let stringData = SerDe.serialize("Test") {
    if let value = SerDe.deserialize(stringData) {
        print(value)
    }
}

// Deserializable Protocol
let data1 = SerDe.serialize(UInt8(31))
if let value: UInt8 = SerDe.deserialize(data1) {
    print("\(value)")
}

let data = SerDe.serialize(UInt8(31))
if let value : UInt8 = SerDe.deserialize(data) {
    print("\(value)")
}

// RawDeserializable Protocol
enum Enabled : UInt8, RawDeserializable {
    case No  = 0
    case Yes = 1
    static let uuid = "F000AA12-0451-4000-B000-000000000000"
}

let data2 = SerDe.serialize(Enabled.Yes)
if let value : Enabled = SerDe.deserialize(data2) {
    print("\(value.rawValue)")
}

struct RawValue : RawDeserializable {
    
    let rawValue: UInt8
    static let uuid = "F000AA13-0451-4000-B000-000000000000"

    init?(rawValue: UInt8) {
        self.rawValue = rawValue
    }
}

if let initValue = RawValue(rawValue:10) {
    let data = SerDe.serialize(initValue)
    if let value : RawValue = SerDe.deserialize(data) {
        print("\(value.rawValue)")
    }
}

// RawArrayDeserializable
struct RawArrayValue : RawArrayDeserializable {
    
    let rawValue: [UInt8]
    static let uuid: String = "F000AA13-0451-4000-B000-000000000000"
    
    static let size = 2
    
    init?(rawValue:[UInt8]) {
        if rawValue.count == 2 {
            self.rawValue = rawValue
        } else {
            return nil
        }
    }
}

if let initValue = RawArrayValue(rawValue:[4,10]) {
    let data = SerDe.serialize(initValue)
    if let value : RawArrayValue = SerDe.deserialize(data) {
        print("\(value.rawValue)")
    }
}

// RawPairDeserializable
struct RawPairValue : RawPairDeserializable {
    
    let rawValue1: UInt8
    let rawValue2: Int8
    static let uuid: String = "F000AA13-0451-4000-B000-000000000000"
    
    
    init?(rawValue1:UInt8, rawValue2:Int8) {
        self.rawValue1 = rawValue1
        self.rawValue2 = rawValue2
    }
}

if let initValue = RawPairValue(rawValue1: 10, rawValue2: -10) {
    let data = SerDe.serialize(initValue)
    if let value : RawPairValue = SerDe.deserialize(data) {
        print("\(value.rawValue1)")
        print("\(value.rawValue2)")
    }
}

// RawArrayPairDeserializable
struct RawArrayPairValue : RawArrayPairDeserializable {
    
    let rawValue1: [UInt8]
    let rawValue2: [Int8]
    static let uuid = "F000AA13-0451-4000-B000-000000000000"
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
}

if let initValue = RawArrayPairValue(rawValue1:[10, 100], rawValue2:[-10, -100]) {
    let data = SerDe.serialize(initValue)
    if let value : RawArrayPairValue = SerDe.deserialize(data) {
        print("\(value.rawValue1)")
        print("\(value.rawValue2)")
    }
}
