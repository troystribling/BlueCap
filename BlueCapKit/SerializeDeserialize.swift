//
//  ByteSwap.swift
//  BlueCap
//
//  Created by Troy Stribling on 7/8/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation

func littleToHost<T>(value:T) -> T {
    return value;
}

func hostToLittle<T>(value:T) -> T {
    return value;
}

func bigToHost<T>(value:T) -> T {
    return reverseBytes(value);
}

func hostToBig<T>(value:T) -> T {
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

protocol DeserializeData {
    typealias DeserializedType
    class func deserialize(data:NSData) -> DeserializedType
    class func deserialize(data:NSData, start:Int) -> DeserializedType
}

protocol SerializeType {
    class func serialize<SerializedType>(value:SerializedType) -> NSData
    class func serialize<SerializedType>(values:SerializedType[]) -> NSData
}
