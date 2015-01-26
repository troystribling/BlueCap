//
//  ByteExtensions.swift
//  BlueCap
//
//  Created by Troy Stribling on 7/8/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation

extension UInt8 : Deserializable {
    
    public static var size : Int {
        return sizeof(UInt8)
    }

    public static func fromString(data:String) -> UInt8? {
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

    public static func deserialize(data:NSData) -> UInt8? {
        if data.length >= sizeof(UInt8) {
            var value : Byte = 0
            data.getBytes(&value, length:sizeof(Byte))
            return toHostByteOrder(value)
        } else {
            return nil
        }
    }
    
    public static func deserialize(data:NSData, start:Int) -> UInt8? {
        if data.length >= start + sizeof(UInt8) {
            var value : Byte = 0
            data.getBytes(&value, range: NSMakeRange(start, sizeof(UInt8)))
            return toHostByteOrder(value)
        } else {
            return nil
        }
    }

    public static func deserialize(data:NSData) -> [UInt8] {
        return deserialize(data)
    }
    
}
