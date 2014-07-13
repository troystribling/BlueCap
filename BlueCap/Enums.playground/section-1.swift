// Playground - noun: a place where people can play

import Foundation

protocol Deserialized {
    class func deserialize(data:NSData) -> Deserialized
}

protocol DeserializedEnum {
    typealias ValueType
    class func fromNative(value:ValueType) -> DeserializedEnum?
}

extension Byte : Deserialized {
    static func deserialize(data:NSData) -> Deserialized {
        var value : Byte = 0
        data.getBytes(&value, length:sizeof(Byte))
        return value
    }
}

enum Enabled : Byte, DeserializedEnum {
    case No  = 0
    case Yes = 1
    static func fromNative(value:Byte) -> DeserializedEnum? {
        switch(value) {
        case 0:
            return Enabled.No
        case 1:
            return Enabled.Yes
        default:
            return nil
        }
    }
}

class EnumDeserialized<EnumType:DeserializedEnum where EnumType.ValueType:Deserialized> {
    func anyValue(data:NSData) -> Any? {
        if let value = EnumType.ValueType.deserialize(data) as? EnumType.ValueType {
            return EnumType.fromNative(value) as? EnumType
        } else {
            return nil
        }
    }
}

let enumDeserialized = EnumDeserialized<Enabled>()
let data = NSData(bytes:[0x01], length:1)
(enumDeserialized.anyValue(data) as Enabled) == Enabled.Yes
