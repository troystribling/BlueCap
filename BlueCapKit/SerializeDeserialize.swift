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
    typealias DeserializedType
    
    class func fromString(data:String) -> DeserializedType?
    
    class func deserialize(data:NSData) -> DeserializedType
    class func deserialize(data:NSData, start:Int) -> DeserializedType
    
    class func deserializeFromLittleEndian(data:NSData) -> DeserializedType
    class func deserializeFromLittleEndian(data:NSData) -> DeserializedType[]
    class func deserializeFromLittleEndian(data:NSData, start:Int) -> DeserializedType

    class func deserializeFromBigEndian(data:NSData) -> DeserializedType
    class func deserializeFromBigEndian(data:NSData) -> DeserializedType[]
    class func deserializeFromBigEndian(data:NSData, start:Int) -> DeserializedType
}

protocol Serialized {
    class func serialize<SerializedType>(value:SerializedType) -> NSData
    class func serialize<SerializedType>(values:SerializedType[]) -> NSData
    
    class func serializeToLittleEndian<SerializedType>(value:SerializedType) -> NSData
    class func serializeToLittleEndian<SerializedType>(values:SerializedType[]) -> NSData
    
    class func serializeToBigEndian<SerializedType>(value:SerializedType) -> NSData
    class func serializeToBigEndian<SerializedType>(values:SerializedType[]) -> NSData
}

protocol DeserializedEnumStatic {
    typealias EnumType
    class func fromRaw(value:Byte) -> EnumType?
    class func fromString(value:String) -> EnumType?
    class func stringValues() -> String[]
    
}

protocol DeserializedEnumInstance {
    var stringValue : String {get}
    func toRaw() -> Byte
}

protocol DeserializedStructStatic {
    typealias StructType
    typealias ValueType
    class func fromStrings(values:Dictionary<String, String>) -> StructType
    class func fromArray(values:Array<ValueType>) -> StructType
}

protocol DeserializedStructInstance {
    typealias ValueType
    var stringValues : Dictionary<String,String> {get}
    func arrayValue() -> Array<ValueType>
}