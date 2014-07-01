//
//  NSDataExtensions.swift
//  BlueCap
//
//  Created by Troy Stribling on 6/29/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation

extension NSData {

    // Bytes
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

    // Int16
    convenience init(int16ToLittle value:Int16) {
        self.init(bytes:[CFSwapInt16HostToLittle(UInt16(value))], length:2)
    }
    
    convenience init(int16ArrayToLittle values:Int16[]) {
        let littleValues = values.map{value in CFSwapInt16HostToLittle(UInt16(value))}
        self.init(bytes:littleValues, length:2*littleValues.count)
    }
    
    func int16FromLittleValue(start:Int) -> Int16 {
        var value : UInt16 = 0
        self.getBytes(&value, range:NSMakeRange(start,2))
        return Int16(CFSwapInt16LittleToHost(value))
    }

    func int16FromLittleValue() -> Int16 {
        var value : UInt16 = 0
        self.getBytes(&value, length: 2)
        return Int16(CFSwapInt16LittleToHost(value))
    }

    convenience init(int16ToBig value:Int16) {
        self.init(bytes:[CFSwapInt16HostToBig(UInt16(value))], length:2)
    }
    
    convenience init(int16ArrayToBig values:Int16[]) {
        let bigValues = values.map{value in CFSwapInt16HostToBig(UInt16(value))}
        self.init(bytes:bigValues, length:2*bigValues.count)
    }

    func int16FromBigValue(start:Int) -> Int16 {
        var value : UInt16 = 0
        self.getBytes(&value, range:NSMakeRange(start,2))
        return Int16(CFSwapInt16LittleToHost(value))
    }

    func int16FromBigValue() -> Int16 {
        var value : UInt16 = 0
        self.getBytes(&value, length:2)
        return Int16(CFSwapInt16LittleToHost(value))
    }

    // UInt16
    
    // string value
    func hexStringValue() -> String {
        var dataBytes = Array<Byte>(count:self.length, repeatedValue:0x0)
        self.getBytes(&dataBytes, length:self.length)
        return dataBytes.reduce(""){(out:String, byte:Byte) in
            return out + NSString(format:"%02lx", byte)
        }
    }
    
    
}
