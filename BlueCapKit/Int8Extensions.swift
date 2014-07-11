//
//  Int8Extensions.swift
//  BlueCap
//
//  Created by Troy Stribling on 7/8/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation

extension Int8 : Deserialized {
    
    static func fromString(data:String) -> Int8? {
        if let intVal = data.toInt() {
            if intVal > 127 {
                return Int8(127)
            } else if intVal < -128 {
                return Int8(-128)
            }
            return Int8(intVal)
        } else {
            return nil
        }
    }

    static func deserialize(data:NSData) -> Int8 {
        var value : Int8 = 0
        data.getBytes(&value, length:sizeof(Int8))
        return value
    }
    
    static func deserialize(data:NSData, start:Int) -> Int8 {
        var value : Int8 = 0
        data.getBytes(&value, range: NSMakeRange(start, sizeof(Int8)))
        return value
    }
    
    static func deserializeFromLittleEndian(data:NSData) -> Int8 {
        return deserialize(data)
    }
    
    static func deserializeFromLittleEndian(data:NSData) -> Int8[] {
        return []
    }
    
    static func deserializeFromLittleEndian(data:NSData, start:Int) -> Int8 {
        return deserialize(data, start:start)
    }
    
    static func deserializeFromBigEndian(data:NSData) -> Int8 {
        return deserialize(data)
    }
    
    static func deserializeFromBigEndian(data:NSData) -> Int8[] {
        return []
    }
    
    static func deserializeFromBigEndian(data:NSData, start:Int) -> Int8 {
        return deserialize(data, start:start)
    }

}
