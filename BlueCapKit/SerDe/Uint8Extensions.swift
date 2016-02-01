//
//  ByteExtensions.swift
//  BlueCap
//
//  Created by Troy Stribling on 7/8/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import Foundation

extension UInt8: BCDeserializable {
    
    public static var size: Int {
        return sizeof(UInt8)
    }

    public init?(doubleValue: Double) {
        if doubleValue > 255.0 || doubleValue < 0.0 {
            return nil
        } else {
            self = UInt8(doubleValue)
        }
    }

    public init?(uintValue: UInt16) {
        if uintValue > 255 {
            return nil
        } else {
            self = UInt8(uintValue)
        }
    }

    public init?(intValue: Int16) {
        if intValue > 255 || intValue < 0 {
            return nil
        } else {
            self = UInt8(intValue)
        }
    }

    public static func deserialize(data: NSData) -> UInt8? {
        if data.length >= sizeof(UInt8) {
            var value : UInt8 = 0
            data.getBytes(&value, length: sizeof(UInt8))
            return toHostByteOrder(value)
        } else {
            return nil
        }
    }
    
    public static func deserialize(data: NSData, start: Int) -> UInt8? {
        if data.length >= start + sizeof(UInt8) {
            var value : UInt8 = 0
            data.getBytes(&value, range: NSMakeRange(start, sizeof(UInt8)))
            return toHostByteOrder(value)
        } else {
            return nil
        }
    }

    public static func deserialize(data: NSData) -> [UInt8] {
        let count = data.length / sizeof(UInt8)
        return [Int](0..<count).reduce([]) {(result, start) in
            if let value = self.deserialize(data, start: start) {
                return result + [value]
            } else {
                return result
            }
        }
    }
    
}
