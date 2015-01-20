//
//  ByteSwap.swift
//  BlueCap
//
//  Created by Troy Stribling on 7/8/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation
import CoreBluetooth

func littleEndianToHost<T>(value:T) -> T {
    return value;
}

func hostToLittleEndian<T>(value:T) -> T {
    return value;
}

func byteArrayValue<T>(value:T) -> [Byte] {
    let values = [value]
    let data = NSData(bytes:values, length:sizeof(T))
    var byteArray = [Byte](count:sizeof(T), repeatedValue:0)
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
    typealias SelfType
    class func fromString(data:String) -> SelfType?
    class func deserializeFromLittleEndian(data:NSData) -> SelfType
    class func deserializeArrayFromLittleEndian(data:NSData) -> [SelfType]
    class func deserializeFromLittleEndian(data:NSData, start:Int) -> SelfType

}

public protocol Serializable {
    class func serialize<SerializedType>(value:SerializedType) -> NSData
    class func serializeArray<SerializedType>(values:[SerializedType]) -> NSData    
    class func serializeToLittleEndian<SerializedType>(value:SerializedType) -> NSData
    class func serializeArrayToLittleEndian<SerializedType>(values:[SerializedType]) -> NSData
    class func serializeArrayPairToLittleEndian<SerializedType1, SerializedType2>(values:([SerializedType1], [SerializedType2])) -> NSData    
}

public protocol BLEConfigurable {
    class var name          : String {get}
    class var tag           : String {get}
    class var permissions   : CBAttributePermissions {get}
    class var properties    : CBCharacteristicProperties {get}
    class var initialValue  : NSData {get}
}

public protocol RawDeserializable {
    typealias RawType   : Deserializable
    class var uuid      : String {get}
    var rawValue        : RawType {get}
    init?(rawValue:RawType)
}

public protocol StringDeserializable {
    class var stringValues  : [String] {get}
    var stringValue         : [String:String] {get}
    init?(stringValue:[String:String])
}

public protocol DeserializedStruct {
    typealias SelfType
    typealias RawType : Deserializable
    class func fromRaw(rawValue:[RawType]) -> SelfType?
    class func fromString(stringValues:[String:String]) -> SelfType?
    var stringValue : [String:String] {get}
    var rawValue : [RawType] {get}
}

public protocol DeserializedPairStruct {
    typealias SelfType
    typealias RawType1 : Deserializable
    typealias RawType2 : Deserializable
    class func fromRaw(rawValue:([RawType1], [RawType2])) -> SelfType?
    class func fromString(stringValues:[String:String]) -> SelfType?
    var stringValue : [String:String] {get}
    var rawValue : ([RawType1], [RawType2]) {get}
}