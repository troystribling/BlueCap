// Playground - noun: a place where people can play

import UIKit

protocol Thing {
    typealias argType
    func doit(val:argType) -> argType
}

class IntThing : Thing {
    typealias argType = Int
    func doit(val: Int) -> Int {
        return val + 1
    }
}

func doThing<A:Thing>(thing:A, val:Int) -> Int {
    return thing.doit(val)
}

protocol CharateristicProtocol {
    typealias T
    func value(data:NSData) -> T
    func stringValue(object:T) -> Dictionary<String, String>
}

class CharacteristicProfile {
}

var profiles = Dictionary<String, CharateristicProtocol>()

class Characteristic {
    
    var data : NSData!
    
    init() {
        var initVal : UInt8 = 0xff
        self.data = NSData(bytes:&initVal, length:1)
    }
    
//    func value<V>(data:NSData) -> V {
//        var profile = profiles["uuid"]
//        return profile!.value(self.data)
//    }
}

class UInt8CharateristicProfile : CharacteristicProfile, CharateristicProtocol {
    
    func value(data:NSData) -> UInt8 {
        var value : UInt8 = 0
        data.getBytes(&value, length:1)
        return value
    }
    
    func stringValue(object: UInt8) -> Dictionary<String, String> {
        return ["value":"\(object)"]
    }
}

