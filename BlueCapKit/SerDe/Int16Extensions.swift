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
    
    public init?(stringValue:String) {
        if let value = stringValue.toInt() {
            if value > 32767 || value < -32768 {
                return nil
            } else {
                self = Int16(value)
            }
        } else {
            return nil
        }
    }

    public init?(value:Double) {
        if value >= 32767.0 || value <= -32768.0 {
            return nil
        } else {
            self = Int16(value)
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
