//
//  UInt16Extensions.swift
//  BlueCap
//
//  Created by Troy Stribling on 7/8/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation

extension UInt16 : Deserialized {
    
    public static func fromString(data:String) -> UInt16? {
        if let intVal = data.toInt() {
            if intVal > 65535 {
                return UInt16(65535)
            } else if intVal < 0 {
                return UInt16(0)
            } else {
                return UInt16(intVal)
            }
        } else {
            return nil
        }
    }

    public static func deserialize(data:NSData) -> UInt16 {
        var value : UInt16 = 0
        if data.length >= sizeof(UInt16) {
            data.getBytes(&value, length:sizeof(UInt16))
        }
        return value
    }
    
    public static func deserialize(data:NSData, start:Int) -> UInt16 {
        var value : UInt16 = 0
        if data.length >= start + sizeof(UInt16) {
            data.getBytes(&value, range: NSMakeRange(start, sizeof(UInt16)))
        }
        return value
    }
    
    public static func deserializeFromLittleEndian(data:NSData) -> UInt16 {
        var value : UInt16 = 0
        if data.length >= sizeof(UInt16) {
            data.getBytes(&value, length:sizeof(UInt16))
        }
        return littleEndianToHost(value)
    }
    
    public static func deserializeArrayFromLittleEndian(data:NSData) -> [UInt16] {
        let size = sizeof(UInt16)
        let count = data.length / size
        return [Int](0..<count).map{self.deserializeFromLittleEndian(data, start:$0*size)}
    }
    
    public static func deserializeFromLittleEndian(data:NSData, start:Int) -> UInt16 {
        var value : UInt16 = 0
        if data.length >= start + sizeof(UInt16) {
            data.getBytes(&value, range:NSMakeRange(start, sizeof(UInt16)))
        }
        return littleEndianToHost(value)
    }
    
    public static func deserializeFromBigEndian(data:NSData) -> UInt16 {
        var value : UInt16 = 0
        if data.length >= sizeof(UInt16) {
            data.getBytes(&value, length:sizeof(UInt16))
        }
        return bigEndianToHost(value)
    }
    
    public static func deserializeArrayFromBigEndian(data:NSData) -> [UInt16] {
        let size = sizeof(UInt16)
        let count = data.length / size
        return [Int](0..<count).map{self.deserializeFromBigEndian(data, start:$0*size)}
    }
    
    public static func deserializeFromBigEndian(data:NSData, start:Int) -> UInt16 {
        var value : UInt16 = 0
        if data.length >= start + sizeof(UInt16) {
            data.getBytes(&value, range:NSMakeRange(start, sizeof(UInt16)))
        }
        return bigEndianToHost(value)
    }
}
