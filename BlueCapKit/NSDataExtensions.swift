//
//  NSDataExtensions.swift
//  BlueCap
//
//  Created by Troy Stribling on 6/29/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation

// swap
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

extension NSData {
    
    // Byte
    convenience init(byte value:Byte) {
        self.init(bytes:[value], length:1)
    }
    
    convenience init(bytes values:Byte[]) {
        self.init(bytes:values, length:values.count)
    }
    
    func byteValue() -> Byte {
        var value : Byte = 0
        self.getBytes(&value, length:1)
        return value
    }
    
    func byteValue(start:Int) -> Byte {
        var value : Byte = 0
        self.getBytes(&value, range: NSMakeRange(start, 1))
        return value
    }
    
    // Int8
    convenience init(int8 value:Int8) {
        self.init(bytes:[value], length:1)
    }
    
    convenience init(int8s values:Int8[]) {
        self.init(bytes:values, length:values.count)
    }
    
    func int8Value() -> Int8 {
        var value : Int8 = 0
        self.getBytes(&value, length:1)
        return value
    }
    
    func int8Value(start:Int) -> Int8 {
        var value : Int8 = 0
        self.getBytes(&value, range: NSMakeRange(start, 1))
        return value
    }
    
    // Little Endian
    convenience init<T>(toLittleEndian value:T) {
        self.init(bytes:[hostToLittle(value)], length:sizeof(T))
    }
    
    convenience init<T>(toLittleEndian values:T[]) {
        let littleValues = values.map{value in hostToLittle(value)}
        self.init(bytes:littleValues, length:sizeof(T)*littleValues.count)
    }
    
    func uint16FromLittleEndianValue() -> UInt16 {
        var value : UInt16 = 0
        self.getBytes(&value, length:sizeof(UInt16))
        return littleToHost(value)
    }
    
    func uint16FromLittleEndianValue(start:Int) -> UInt16 {
        var value : UInt16 = 0
        self.getBytes(&value, range:NSMakeRange(start, sizeof(UInt16)))
        return bigToHost(value)
    }
    
    func int16FromLittleEndianValue() -> Int16 {
        var value : Int16 = 0
        self.getBytes(&value, length:sizeof(Int16))
        return littleToHost(value)
    }
    
    func int16FromLittleEndianValue(start:Int) -> Int16 {
        var value : Int16 = 0
        self.getBytes(&value, range:NSMakeRange(start, sizeof(Int16)))
        return bigToHost(value)
    }
    
    // Big Endian
    convenience init<T>(toBigEndian value:T) {
        self.init(bytes:[hostToBig(value)], length:sizeof(T))
    }
    
    convenience init<T>(toBigEndian values:T[]) {
        let bigValues = values.map{value in hostToBig(value)}
        self.init(bytes:bigValues, length:sizeof(T)*bigValues.count)
    }
    
    func uint16FromBigEndianValue() -> UInt16 {
        var value : UInt16 = 0
        self.getBytes(&value, length:sizeof(UInt16))
        return bigToHost(value)
    }
    
    func uint16FromBigEndianValue(start:Int) -> UInt16 {
        var value : UInt16 = 0
        self.getBytes(&value, range:NSMakeRange(start, sizeof(UInt16)))
        return bigToHost(value)
    }
    
    func int16FromBigEndianValue() -> Int16 {
        var value : Int16 = 0
        self.getBytes(&value, length:sizeof(Int16))
        return bigToHost(value)
    }
    
    func int16FromBigEndianValue(start:Int) -> Int16 {
        var value : Int16 = 0
        self.getBytes(&value, range:NSMakeRange(start, sizeof(Int16)))
        return bigToHost(value)
    }
    
    // utils
    func hexStringValue() -> String {
        var dataBytes = Array<Byte>(count:self.length, repeatedValue:0x0)
        self.getBytes(&dataBytes, length:self.length)
        var hexString = dataBytes.reduce(""){(out:String, dataByte:Byte) in
            out +  NSString(format:"%02lx", dataByte)
        }
        return hexString
    }
}
