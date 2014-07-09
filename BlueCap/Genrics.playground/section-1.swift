// Playground - noun: a place where people can play

import UIKit

// A swift protocol with associated type used as type parameter in generic function
protocol Thing {
    typealias argType
    func doit(val:argType) -> argType
}

class IntThing : Thing {
    func doit(val: Int) -> Int {
        return val + 1
    }
}

func doThing<A:Thing>(thing:A, val:A.argType) -> A.argType {
    return thing.doit(val)
}

doThing(IntThing(), 2)

// Protocols in arrays
protocol IntStuff {
    func doit(val:Int) -> Int
}

class Stuff : IntStuff {
    func doit(val:Int) -> Int {
        return val + 2
    }
}

var allStuff = Dictionary<String, IntStuff>()
allStuff["A"] = Stuff()
println(allStuff["A"]?.doit(2))

var allThings = Dictionary<String, Thing>()
allThings["Z"] = IntThing()
// allThings["Z"]?.doit(2) ERROR

// Characteristic profile model
protocol CharateristicProtocol {
    typealias ValueType
    func value(data:NSData) -> ValueType
}

class CharacteristicProfile {
}

class AnyCharacteristicProfile : CharacteristicProfile, CharateristicProtocol {
    
    func value(data:NSData) -> NSData {
        return data
    }
    
}

class UInt8CharateristicProfile : CharacteristicProfile, CharateristicProtocol {
    
    func value(data:NSData) -> UInt8 {
        var value : UInt8 = 0
        data.getBytes(&value, length:1)
        return value
    }
    
}

class StringCharateristicProfile : CharacteristicProfile, CharateristicProtocol {
    
    func value(data:NSData) -> String {
        return NSString(data:data, encoding:NSUTF8StringEncoding)
    }
    
}

var profiles = Dictionary<String, CharateristicProtocol>()
profiles["ABC"] = UInt8CharateristicProfile()
profiles["DEF"] = StringCharateristicProfile()

class Characteristic {
    
    var data : NSData!
    
    init() {
        var initVal : UInt8 = 0xff
        self.data = NSData(bytes:&initVal, length:1)
    }
    
    func value<ProfileType:CharateristicProtocol>(profile:ProfileType) -> ProfileType.ValueType {
        return profile.value(self.data)
    }
    
}

let characteristic = Characteristic()
let profile = profiles["ABC"] as UInt8CharateristicProfile
characteristic.value(profile)

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

class Profile<ProfileType:DeserializeData> {
    func deserialize(data:NSData) -> ProfileType.DeserializedType {
        return ProfileType.deserialize(data)
    }
}

let testByte : Byte = 0x11
var a = NSData.serialize(testByte)
Byte.deserialize(a)

var b = Profile<Byte>()
b.deserialize(a)

