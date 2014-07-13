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

func byteArrayValue<T>(value:T) -> Byte[] {
    let data = NSData(bytes:[value], length:sizeof(T))
    var byteArray = Byte[](count:sizeof(T), repeatedValue:0)
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
    class func fromString(data:String) -> Deserialized?
    
    class func deserialize(data:NSData) -> Deserialized
    class func deserialize(data:NSData, start:Int) -> Deserialized
    
    class func deserializeFromLittleEndian(data:NSData) -> Deserialized
    class func deserializeFromLittleEndian(data:NSData) -> Deserialized[]
    class func deserializeFromLittleEndian(data:NSData, start:Int) -> Deserialized

    class func deserializeFromBigEndian(data:NSData) -> Deserialized
    class func deserializeFromBigEndian(data:NSData) -> Deserialized[]
    class func deserializeFromBigEndian(data:NSData, start:Int) -> Deserialized
}

protocol Serialized {
    class func serialize<SerializedType>(value:SerializedType) -> NSData
    class func serialize<SerializedType>(values:SerializedType[]) -> NSData
    
    class func serializeToLittleEndian<SerializedType>(value:SerializedType) -> NSData
    class func serializeToLittleEndian<SerializedType>(values:SerializedType[]) -> NSData
    
    class func serializeToBigEndian<SerializedType>(value:SerializedType) -> NSData
    class func serializeToBigEndian<SerializedType>(values:SerializedType[]) -> NSData
}

protocol DeserializedEnum {
    typealias ValueType
    class func fromNative(value:ValueType) -> DeserializedEnum?
    class func fromString(value:String) -> DeserializedEnum?
    class func stringValues() -> String[]
    var stringValue : String {get}
    func toNative() -> ValueType
}

protocol DeserializedStruct {
    typealias ValueType
    class func fromStrings(values:Dictionary<String, String>) -> DeserializedStruct?
    class func fromArray(values:ValueType[]) -> DeserializedStruct?
    var stringValues : Dictionary<String,String> {get}
    func arrayValue() -> ValueType[]
}