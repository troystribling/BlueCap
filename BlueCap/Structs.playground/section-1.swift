// Playground - noun: a place where people can play

import Foundation

protocol Deserialized {
    typealias SelfType
    class func deserialize(data:NSData, start:Int) -> SelfType
    class func deserialize(data:NSData) -> [SelfType]
}

protocol DeserializedStruct {
    typealias SelfType
    typealias NativeType : Deserialized
    class func fromArray(values:[NativeType]) -> SelfType?
}

extension Byte : Deserialized {
    static func deserialize(data:NSData, start:Int) -> Byte {
        var value : Byte = 0
        data.getBytes(&value, range: NSMakeRange(start, sizeof(Byte)))
        return value
    }
    static func deserialize(data:NSData) -> [Byte] {
        let count = data.length / sizeof(Byte)
        return [Int](0..<count).map{(i) in self.deserialize(data, start:i)}
    }
}

struct Values : DeserializedStruct {
    var v1 : Byte
    var v2 : Byte
    var v3 : Byte
    static func fromArray(values:[Byte]) -> Values? {
        return Values(v1:values[0], v2:values[1], v3:values[2])
    }
}

class StructDeserialized<StructType:DeserializedStruct where StructType.NativeType == StructType.NativeType.SelfType, StructType == StructType.SelfType> {
    func anyValue(data:NSData) -> Any? {
        let values = StructType.NativeType.deserialize(data)
        return StructType.fromArray(values)
    }
}

let structDeserialized = StructDeserialized<Values>()
let values : [Byte] = [0x01, 0x0a, 0x0b]
let data = NSData(bytes:values, length:3)
let structValue = structDeserialized.anyValue(data)
