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

    public init?(stringValue:String) {
        if let value = stringValue.toInt() {
            if value > 255 || value < 0 {
                return nil
            } else {
                self = Byte(value)
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
