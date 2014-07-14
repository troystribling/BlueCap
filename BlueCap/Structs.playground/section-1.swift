// Playground - noun: a place where people can play

import Foundation

protocol Deserialized {
    class func deserialize(data:NSData, start:Int) -> Deserialized
    class func deserialize(data:NSData) -> [Deserialized]
}

protocol DeserializedStruct {
    typealias ValueType
    class func fromArray(values:[ValueType]) -> DeserializedStruct?
}

extension Byte : Deserialized {
    static func deserialize(data:NSData, start:Int) -> Deserialized {
        var value : Byte = 0
        data.getBytes(&value, range: NSMakeRange(start, sizeof(Byte)))
        return value
    }
    static func deserialize(data:NSData) -> [Deserialized] {
        let count = data.length / sizeof(Byte)
        return Int[](0..<count).map{(i) in self.deserialize(data, start:i)}
    }
}

struct Values : DeserializedStruct {
    var v1 : Byte
    var v2 : Byte
    var v3 : Byte
    static func fromArray(values:[Byte]) -> DeserializedStruct? {
        println(values)
        return Values(v1:values[0], v2:values[1], v3:values[3])
    }
}

class StructDeserialized<StructType:DeserializedStruct where StructType.ValueType:Deserialized> {
    func anyValue(data:NSData) -> Any? {
        let valuesDes = StructType.ValueType.deserialize(data)
        return StructType.fromArray(valuesDes) as? StructType
}

let structDeserialized = StructDeserialized<Values>()
let data = NSData(bytes:[0x01, 0x0a, 0x0b], length:3)
let structValue = structDeserialized.anyValue(data)

