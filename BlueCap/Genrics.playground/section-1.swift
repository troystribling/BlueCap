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


