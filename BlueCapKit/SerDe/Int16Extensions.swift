//
//  Int16Extensions.swift
//  BlueCap
//
//  Created by Troy Stribling on 7/8/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation

extension Int16 : Deserializable {
    
    public static var size : Int {
        return sizeof(Int16)
    }
    
    public static func fromString(data:String) -> Int16? {
        if let intVal = data.toInt() {
            if intVal > 32767 {
                return Int16(32767)
            } else if intVal < -32768 {
                return Int16(-32768)
            } else {
                return Int16(intVal)
            }
        } else {
            return nil
        }
    }

    public static func deserialize(data:NSData) -> Int16? {
        if data.length >= sizeof(Int16) {
            var value : Int16 = 0
            data.getBytes(&value , length:sizeof(Int16))
            return toHostByteOrder(value)
        } else {
            return nil
        }
    }

    public static func deserialize(data:NSData, start:Int) -> Int16? {
        if data.length >= (sizeof(Int16) + start)  {
            var value : Int16 = 0
            data.getBytes(&value, range:NSMakeRange(start, sizeof(Int16)))
            return toHostByteOrder(value)
        } else {
            return nil
        }
    }
    
    public static func deserialize(data:NSData) -> [Int16] {
        return deserialize(data)
    }
    
}
