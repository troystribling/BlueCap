//
//  UInt32Extensions.swift
//  BlueCap
//
//  Created by Troy Stribling on 7/8/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import Foundation

extension UInt32: BCDeserializable {
    
    public static var size : Int {
        return sizeof(UInt32)
    }

    public init?(doubleValue:Double) {
        if doubleValue > 0xFFFFFFFF || doubleValue < 0.0 {
            return nil
        } else {
            self = UInt32(doubleValue)
        }
    }

    public static func deserialize(data:NSData) -> UInt32? {
        if data.length >= sizeof(UInt32) {
            var value : UInt32 = 0
            data.getBytes(&value, length:sizeof(UInt32))
            return toHostByteOrder(value)
        } else {
            return nil
        }
    }
    
    public static func deserialize(data:NSData, start:Int) -> UInt32? {
        if data.length >= start + sizeof(UInt32) {
            var value : UInt32 = 0
            data.getBytes(&value, range:NSMakeRange(start, sizeof(UInt32)))
            return toHostByteOrder(value)
        } else {
            return nil
        }
    }

    public static func deserialize(data:NSData) -> [UInt32] {
        let size = sizeof(UInt32)
        let count = data.length / size
        return [Int](0..<count).reduce([]) {(result, idx) in
            if let value = self.deserialize(data, start:size*idx) {
                return result + [value]
            } else {
                return result
            }
        }
    }
}
