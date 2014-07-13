//
//  ByteExtensions.swift
//  BlueCap
//
//  Created by Troy Stribling on 7/8/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation

extension Byte : Deserialized {
    
    static func fromString(data:String) -> Deserialized? {
        if let intVal = data.toInt() {
            if intVal > 255 {
                return Byte(255)
            } else if intVal < 0 {
                return Byte(0)
            } else {
                return Byte(intVal)
            }
        } else {
            return nil
        }
    }

    static func deserialize(data:NSData) -> Deserialized {
        var value : Byte = 0
        data.getBytes(&value, length:sizeof(Byte))
        return value
    }
    
    static func deserialize(data:NSData, start:Int) -> Deserialized {
        var value : Byte = 0
        data.getBytes(&value, range: NSMakeRange(start, sizeof(Byte)))
        return value
    }
    
    static func deserializeFromLittleEndian(data:NSData) -> Deserialized {
        return deserialize(data)
    }
    
    static func deserializeFromLittleEndian(data:NSData) -> [Deserialized] {
        let count = data.length / sizeof(Byte)
        return [Int](0..<count).map{(i) in self.deserializeFromLittleEndian(data, start:i)}
    }
    
    static func deserializeFromLittleEndian(data:NSData, start:Int) -> Deserialized {
        return deserialize(data, start:start)
    }
    
    static func deserializeFromBigEndian(data:NSData) -> Deserialized {
        return deserialize(data)
    }
    
    static func deserializeFromBigEndian(data:NSData) -> [Deserialized] {
        let count = data.length / sizeof(Byte)
        return [Int](0..<count).map{(i) in self.deserializeFromBigEndian(data, start:i)}
    }
    
    static func deserializeFromBigEndian(data:NSData, start:Int) -> Deserialized {
        return deserialize(data, start:start)
    }

}
