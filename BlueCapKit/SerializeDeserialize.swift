//
//  ByteSwap.swift
//  BlueCap
//
//  Created by Troy Stribling on 7/8/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation

enum Endianness {
    case Little
    case Big
}

func littleEndianToHost<T>(value:T) -> T {
    return value;
}

func hostToLittleEndian<T>(value:T) -> T {
    return value;
}

func bigEndianToHost<T>(value:T) -> T {
    return reverseBytes(value);
}

func hostToBigEndian<T>(value:T) -> T {
    return reverseBytes(value);
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
    swappedBytes.getBytes(&result, length:sizeof(Int16))
    return result
}

protocol Deserialized {
    typealias SelfType
    class func fromString(data:String) -> SelfType?
    
    class func deserialize(data:NSData) -> SelfType
    class func deserialize(data:NSData, start:Int) -> SelfType
    
    class func deserializeFromLittleEndian(data:NSData) -> SelfType
    class func deserializeFromLittleEndian(data:NSData) -> [SelfType]
    class func deserializeFromLittleEndian(data:NSData, start:Int) -> SelfType

    class func deserializeFromBigEndian(data:NSData) -> SelfType
    class func deserializeFromBigEndian(data:NSData) -> [SelfType]
    class func deserializeFromBigEndian(data:NSData, start:Int) -> SelfType
}

protocol Serialized {
    class func serialize<SerializedType>(value:SerializedType) -> NSData
    class func serialize<SerializedType>(values:[SerializedType]) -> NSData
    
    class func serializeToLittleEndian<SerializedType>(value:SerializedType) -> NSData
    class func serializeToLittleEndian<SerializedType>(values:[SerializedType]) -> NSData
    
    class func serializeToBigEndian<SerializedType>(value:SerializedType) -> NSData
    class func serializeToBigEndian<SerializedType>(values:[SerializedType]) -> NSData
}

protocol DeserializedEnum {
    typealias SelfType
    typealias ValueType : Deserialized
    class func fromNative(value:ValueType) -> SelfType?
    class func fromString(value:String) -> SelfType?
    class func stringValues() -> [String]
    var stringValue : String {get}
    func toNative() -> ValueType
}

protocol DeserializedStruct {
    typealias SelfType
    typealias ValueType : Deserialized
    class func fromStrings(values:Dictionary<String, String>) -> DeserializedStruct?
    class func fromArray(values:[ValueType]) -> DeserializedStruct?
    var stringValues : Dictionary<String,String> {get}
    func arrayValue() -> [ValueType]
}