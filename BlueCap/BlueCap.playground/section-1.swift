// Playground - noun: a place where people can play

import UIKit
import BlueCapKit

// Deserializable Protocol
let deserializableData = Serde.serialize(UInt8(31))
if let deserializable : UInt8 = Serde.deserialize(deserializableData) {
    println("\(deserializable)")
}

// RawDeserializable Protocol
public enum Enabled : UInt8, RawDeserializable {
    case No  = 0
    case Yes = 1
    public static let uuid = "F000AA12-0451-4000-B000-000000000000"
}

let rawDeserializableData = Serde.serialize(Enabled.Yes)
if let rawDeserializable : Enabled = Serde.deserialize(rawDeserializableData) {
    println("\(rawDeserializable.rawValue)")
}

public struct Value : RawDeserializable {
    
    public let rawValue    : UInt8
    public static let uuid = "F000AA13-0451-4000-B000-000000000000"

    public init?(rawValue:UInt8) {
        self.rawValue = rawValue
    }
}

if let sructRawDeserializableInitialValue = Value(rawValue:10) {
    let structRawDeserializableData = Serde.serialize(sructRawDeserializableInitialValue)
    if let sructRawDeserializableValue : Value = Serde.deserialize(structRawDeserializableData) {
        println("\(sructRawDeserializableValue.rawValue)")
    }
}