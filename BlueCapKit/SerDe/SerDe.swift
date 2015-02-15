//
//  SerDe.swift
//  BlueCap
//
//  Created by Troy Stribling on 7/8/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation
import CoreBluetooth

func toHostByteOrder<T>(value:T) -> T {
    return value;
}

func fromHostByteOrder<T>(value:T) -> T {
    return value;
}

func byteArrayValue<T>(value:T) -> [UInt8] {
    let values = [value]
    let data = NSData(bytes:values, length:sizeof(T))
    var byteArray = [UInt8](count:sizeof(T), repeatedValue:0)
    data.getBytes(&byteArray, length:sizeof(T))
    return byteArray
}

func reverseBytes<T>(value:T) -> T {
    var result = value
    var swappedBytes = NSData(bytes:byteArrayValue(value).reverse(), length:sizeof(T))
    swappedBytes.getBytes(&result, length:sizeof(T))
    return result
}

public protocol Deserializable {
    static var size : Int {get}
    static func deserialize(data:NSData) -> Self?
    static func deserialize(data:NSData, start:Int) -> Self?
    static func deserialize(data:NSData) -> [Self]
    init?(stringValue:String)
}

public protocol Serializable {
    static func fromString(value:String, encoding:NSStringEncoding) -> NSData?
    static func serialize<T>(value:T) -> NSData
    static func serialize<T>(values:[T]) -> NSData
    static func serialize<T1, T2>(value1:T1, value2:T2) -> NSData
    static func serialize<T1, T2>(value1:[T1], value2:[T2]) -> NSData
}

public protocol CharacteristicConfigurable {
    static var name          : String {get}
    static var uuid          : String {get}
    static var permissions   : CBAttributePermissions {get}
    static var properties    : CBCharacteristicProperties {get}
    static var initialValue  : NSData? {get}
}

public protocol ServiceConfigurable {
    static var name  : String {get}
    static var uuid  : String {get}
    static var tag   : String {get}
}

public protocol StringDeserializable {
    static var stringValues : [String] {get}
    var stringValue         : [String:String] {get}
    init?(stringValue:[String:String])
}

public protocol RawDeserializable {
    typealias RawType
    static var uuid         : String {get}
    var rawValue            : RawType {get}
    init?(rawValue:RawType)
}

public protocol RawArrayDeserializable {
    typealias RawType
    static var uuid     : String {get}
    var rawValue        : [RawType] {get}
    init?(rawValue:[RawType])
}

public protocol RawPairDeserializable {
    typealias RawType1
    typealias RawType2
    static var uuid     : String {get}
    var rawValue1       : RawType1 {get}
    var rawValue2       : RawType2 {get}
    init?(rawValue1:RawType1, rawValue2:RawType2)
}

public protocol RawArrayPairDeserializable {
    typealias RawType1
    typealias RawType2
    static var uuid      : String {get}
    static var size1     : Int {get}
    static var size2     : Int {get}
    var rawValue1       : [RawType1] {get}
    var rawValue2       : [RawType2] {get}
    init?(rawValue1:[RawType1], rawValue2:[RawType2])
}

public struct Serde {
    
    public static func serialize(value:String, encoding:NSStringEncoding = NSUTF8StringEncoding) -> NSData? {
        return NSData.fromString(value, encoding:encoding)
    }

    public static func deserialize(data:NSData, encoding:NSStringEncoding = NSUTF8StringEncoding) -> String? {
        return (NSString(data:data, encoding:encoding) as? String)
    }

    public static func deserialize<T:Deserializable>(data:NSData) -> T? {
        return T.deserialize(data)
    }

    public static func serialize<T:Deserializable>(value:T) -> NSData {
        return NSData.serialize(value)
    }

    public static func serialize<T:Deserializable>(values:[T]) -> NSData {
        return NSData.serialize(values)
    }

    public static func deserialize<T:RawDeserializable where T.RawType:Deserializable>(data:NSData) -> T? {
        return T.RawType.deserialize(data).flatmap{T(rawValue:$0)}
    }

    public static func serialize<T:RawDeserializable>(value:T) -> NSData {
        return NSData.serialize(value.rawValue)
    }

    public static func deserialize<T:RawArrayDeserializable where T.RawType:Deserializable>(data:NSData) -> T? {
        return T(rawValue:T.RawType.deserialize(data))
    }

    public static func serialize<T:RawArrayDeserializable>(value:T) -> NSData {
        return NSData.serialize(value.rawValue)
    }

    public static func deserialize<T:RawPairDeserializable where T.RawType1:Deserializable,  T.RawType2:Deserializable>(data:NSData) -> T? {
        let rawData1 = data.subdataWithRange(NSMakeRange(0, T.RawType1.size))
        let rawData2 = data.subdataWithRange(NSMakeRange(T.RawType1.size, T.RawType2.size))
        return T.RawType1.deserialize(rawData1).flatmap {rawValue1 in
            T.RawType2.deserialize(rawData2).flatmap {rawValue2 in
                T(rawValue1:rawValue1, rawValue2:rawValue2)
            }
        }
    }

    public static func serialize<T:RawPairDeserializable>(value:T) -> NSData {
        return NSData.serialize(value.rawValue1, value2:value.rawValue2)
    }

    public static func deserialize<T:RawArrayPairDeserializable where T.RawType1:Deserializable,  T.RawType2:Deserializable>(data:NSData) -> T? {
        let rawData1 = data.subdataWithRange(NSMakeRange(0, T.size1))
        let rawData2 = data.subdataWithRange(NSMakeRange(T.size1, T.size2))
        return T(rawValue1:T.RawType1.deserialize(rawData1), rawValue2:T.RawType2.deserialize(rawData2))
    }

    public static func serialize<T:RawArrayPairDeserializable>(value:T) -> NSData {
        return NSData.serialize(value.rawValue1, value2:value.rawValue2)
    }
}




