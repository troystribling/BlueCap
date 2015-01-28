//
//  Int8Extensions.swift
//  BlueCap
//
//  Created by Troy Stribling on 7/8/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation

extension Int8 : Deserializable {
    
    public static var size : Int {
        return sizeof(Int8)
    }

    public init?(stringValue:String) {
        if let value = stringValue.toInt() {
            if value > 128 || value < -128 {
                 return nil
            } else {
                self = Int8(value)
            }
        } else {
            return nil
        }
    }

    public init?(value:Double) {
        if value >= 127.0 || value <= -128.0 {
            return nil
        } else {
            self = Int8(value)
        }
    }

    public static func deserialize(data:NSData) -> Int8? {
        if data.length >= sizeof(Int8) {
            var value : Int8 = 0
            data.getBytes(&value, length:sizeof(Int8))
            return toHostByteOrder(value)
        } else {
            return nil
        }
    }

    public static func deserialize(data:NSData, start:Int) -> Int8? {
        if data.length >= start + sizeof(Int8) {
            var value : Int8 = 0
            data.getBytes(&value, range: NSMakeRange(start, sizeof(Int8)))
            return toHostByteOrder(value)
        } else {
            return nil
        }
    }

    public static func deserialize(data:NSData) -> [Int8] {
        return deserialize(data)
    }
    
}

