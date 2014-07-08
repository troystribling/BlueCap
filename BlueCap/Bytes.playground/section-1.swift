// Playground - noun: a place where people can play

import Foundation

var bytes : Byte[] = [0xFF, 0x10, 0xaf]
var data = NSData(bytes:bytes, length: 3)
data.length
var dataBytes = Array<Byte>(count:3, repeatedValue:0x0)
data.getBytes(&dataBytes, length:3)
dataBytes.reduce(""){(out:String, byte:Byte) in
     return out + NSString(format:"%02lx", byte)
}

var allBytes : Byte[] = []
let clongBytes = strtol("0a", nil, 16)
let byte = Array<Byte>(count:1, repeatedValue:0)
allBytes += Byte(clongBytes)
let allData = NSData(bytes:allBytes, length:allBytes.count)
println(allData)

protocol DeserializeData {
    typealias DeserializedType
    class func deserialize(data:NSData) -> DeserializedType
    class func deserialize(data:NSData, start:Int) -> DeserializedType
}

extension Byte : DeserializeData {
    static func deserialize(data:NSData) -> Byte {
        var value : Byte = 0
        data.getBytes(&value, length:sizeof(Byte))
        return value
    }
    static func deserialize(data:NSData, start:Int) -> Byte {
        var value : Byte = 0
        data.getBytes(&value, range: NSMakeRange(start, sizeof(Byte)))
        return value
    }
}

protocol SerializeType {
    class func serialize<SerializedType>(value:SerializedType) -> NSData
    class func serialize<SerializedType>(values:SerializedType[]) -> NSData
}

extension NSData : SerializeType {
    class func serialize<SerializedType>(value:SerializedType) -> NSData {
        return NSData(bytes:[value], length:sizeof(SerializedType))
    }
    class func serialize<SerializedType>(values:SerializedType[]) -> NSData {
        return NSData(bytes:values, length:values.count*sizeof(SerializedType))
    }
    func hexStringValue() -> String {
        var dataBytes = Array<Byte>(count:self.length, repeatedValue:0x0)
        self.getBytes(&dataBytes, length:self.length)
        var hexString = dataBytes.reduce(""){(out:String, dataByte:Byte) in
            out +  NSString(format:"%02lx", dataByte)
        }
        return hexString
    }
}

let testByte : Byte = 0x11
var a = NSData.serialize(testByte)
Byte.deserialize(a)
