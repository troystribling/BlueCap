//
//  UInt16Extensions.swift
//  BlueCap
//
//  Created by Troy Stribling on 7/8/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation

extension UInt16 : Deserializable {
    
    public static var size : Int {
        return sizeof(UInt16)
    }

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

    public static func deserialize(data:NSData) -> UInt16? {
        if data.length >= sizeof(UInt16) {
            var value : UInt16 = 0
            data.getBytes(&value, length:sizeof(UInt16))
            return toHostByteOrder(value)
        } else {
            return nil
        }
    }
    
    public static func deserialize(data:NSData, start:Int) -> UInt16? {
        if data.length >= start + sizeof(UInt16) {
            var value : UInt16 = 0
            data.getBytes(&value, range:NSMakeRange(start, sizeof(UInt16)))
            return toHostByteOrder(value)
        } else {
            return nil
        }
    }

    public static func deserialize(data:NSData) -> [UInt16] {
        return deserialize(data)
    }
}
