//
//  Int8Extensions.swift
//  BlueCap
//
//  Created by Troy Stribling on 7/8/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation

extension Int8 : Deserialized {
    
    public static func fromString(data:String) -> Int8? {
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

    public static func deserialize(data:NSData) -> Int8 {
        var value : Int8 = 0
        if data.length >= sizeof(Int8) {
            data.getBytes(&value, length:sizeof(Int8))
        }
        return value
    }
    
    public static func deserialize(data:NSData, start:Int) -> Int8 {
        var value : Int8 = 0
        if data.length >= start + sizeof(Int8) {
            data.getBytes(&value, range: NSMakeRange(start, sizeof(Int8)))
        }
        return value
    }
    
    public static func deserializeFromLittleEndian(data:NSData) -> Int8 {
        return deserialize(data)
    }
    
    public static func deserializeArrayFromLittleEndian(data:NSData) -> [Int8] {
        let count = data.length / sizeof(Int8)
        return [Int](0..<count).map{self.deserializeFromLittleEndian(data, start:$0)}
    }
    
    public static func deserializeFromLittleEndian(data:NSData, start:Int) -> Int8 {
        return deserialize(data, start:start)
    }
    
    public static func deserializeFromBigEndian(data:NSData) -> Int8 {
        return deserialize(data)
    }
    
    public static func deserializeArrayFromBigEndian(data:NSData) -> [Int8] {
        let count = data.length / sizeof(Int8)
        return [Int](0..<count).map{self.deserializeFromBigEndian(data, start:$0)}
    }
    
    public static func deserializeFromBigEndian(data:NSData, start:Int) -> Int8 {
        return deserialize(data, start:start)
    }

}
