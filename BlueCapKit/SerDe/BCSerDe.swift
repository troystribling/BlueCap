//
//  BCSerDe.swift
//  BlueCap
//
//  Created by Troy Stribling on 7/8/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import Foundation
import CoreBluetooth

// MARK: Byte Swap
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
    let swappedBytes = NSData(bytes:byteArrayValue(value).reverse(), length:sizeof(T))
    swappedBytes.getBytes(&result, length:sizeof(T))
    return result
}

// MARK: SerDe Protocols
public protocol BCDeserializable {
    static var size : Int {get}
    static func deserialize(data:NSData) -> Self?
    static func deserialize(data:NSData, start:Int) -> Self?
    static func deserialize(data:NSData) -> [Self]
}

public protocol BCSerializable {
    static func fromString(value:String, encoding:NSStringEncoding) -> NSData?
    static func serialize<T>(value:T) -> NSData
    static func serialize<T>(values:[T]) -> NSData
    static func serialize<T1, T2>(value1:T1, value2:T2) -> NSData
    static func serialize<T1, T2>(value1:[T1], value2:[T2]) -> NSData
}

public protocol BCCharacteristicConfigurable {
    static var name          : String {get}
    static var UUID          : String {get}
    static var permissions   : CBAttributePermissions {get}
    static var properties    : CBCharacteristicProperties {get}
    static var initialValue  : NSData? {get}
}

public protocol BCServiceConfigurable {
    static var name  : String {get}
    static var UUID  : String {get}
    static var tag   : String {get}
}

public protocol BCStringDeserializable {
    static var stringValues : [String] {get}
    var stringValue         : [String:String] {get}
    init?(stringValue:[String:String])
}

public protocol BCRawDeserializable {
    associatedtype RawType
    static var UUID         : String {get}
    var rawValue            : RawType {get}
    init?(rawValue:RawType)
}

public protocol BCRawArrayDeserializable {
    associatedtype RawType
    static var UUID     : String {get}
    static var size     : Int {get}
    var rawValue        : [RawType] {get}
    init?(rawValue:[RawType])
}

public protocol BCRawPairDeserializable {
    associatedtype RawType1
    associatedtype RawType2
    static var UUID     : String {get}
    var rawValue1       : RawType1 {get}
    var rawValue2       : RawType2 {get}
    init?(rawValue1:RawType1, rawValue2:RawType2)
}

public protocol BCRawArrayPairDeserializable {
    associatedtype RawType1
    associatedtype RawType2
    static var UUID     : String {get}
    static var size1    : Int {get}
    static var size2    : Int {get}
    var rawValue1       : [RawType1] {get}
    var rawValue2       : [RawType2] {get}
    init?(rawValue1:[RawType1], rawValue2:[RawType2])
}

// MARK: BCSerDe
public struct BCSerDe {
    
    public static func serialize(value: String, encoding: NSStringEncoding = NSUTF8StringEncoding) -> NSData? {
        return NSData.fromString(value, encoding: encoding)
    }

    public static func deserialize(data: NSData, encoding: NSStringEncoding = NSUTF8StringEncoding) -> String? {
        return (NSString(data: data, encoding: encoding) as? String)
    }

    public static func deserialize<T: BCDeserializable>(data: NSData) -> T? {
        return T.deserialize(data)
    }

    public static func serialize<T: BCDeserializable>(value: T) -> NSData {
        return NSData.serialize(value)
    }

    public static func serialize<T: BCDeserializable>(values: [T]) -> NSData {
        return NSData.serializeArray(values)
    }

    public static func deserialize<T: BCRawDeserializable where T.RawType: BCDeserializable>(data:NSData) -> T? {
        return T.RawType.deserialize(data).flatmap{ T(rawValue:$0) }
    }

    public static func serialize<T: BCRawDeserializable>(value:T) -> NSData {
        return NSData.serialize(value.rawValue)
    }

    public static func deserialize<T: BCRawArrayDeserializable where T.RawType: BCDeserializable>(data:NSData) -> T? {
        if data.length >= T.size {
            return T(rawValue:T.RawType.deserialize(data))
        } else {
            return nil
        }
    }

    public static func serialize<T: BCRawArrayDeserializable>(value: T) -> NSData {
        return NSData.serializeArray(value.rawValue)
    }

    public static func deserialize<T: BCRawPairDeserializable where T.RawType1: BCDeserializable,  T.RawType2: BCDeserializable>(data:NSData) -> T? {
        if data.length >= (T.RawType1.size + T.RawType2.size) {
            let rawData1 = data.subdataWithRange(NSMakeRange(0, T.RawType1.size))
            let rawData2 = data.subdataWithRange(NSMakeRange(T.RawType1.size, T.RawType2.size))
            return T.RawType1.deserialize(rawData1).flatmap {rawValue1 in
                T.RawType2.deserialize(rawData2).flatmap {rawValue2 in
                    T(rawValue1: rawValue1, rawValue2: rawValue2)
                }
            }
        } else {
            return nil
        }
    }

    public static func serialize<T: BCRawPairDeserializable>(value: T) -> NSData {
        return NSData.serialize(value.rawValue1, value2: value.rawValue2)
    }

    public static func deserialize<T: BCRawArrayPairDeserializable where T.RawType1: BCDeserializable,  T.RawType2: BCDeserializable>(data: NSData) -> T? {
        if data.length >= (T.size1 + T.size2) {
            let rawData1 = data.subdataWithRange(NSMakeRange(0, T.size1))
            let rawData2 = data.subdataWithRange(NSMakeRange(T.size1, T.size2))
            return T(rawValue1:T.RawType1.deserialize(rawData1), rawValue2: T.RawType2.deserialize(rawData2))
        } else {
            return nil
        }
    }

    public static func serialize<T: BCRawArrayPairDeserializable>(value:T) -> NSData {
        return NSData.serializeArrays(value.rawValue1, values2: value.rawValue2)
    }
}




