//
//  Int8Extensions.swift
//  BlueCap
//
//  Created by Troy Stribling on 7/8/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import Foundation

extension Int8: BCDeserializable {
    
    public static var size: Int {
        return sizeof(Int8)
    }

    public init?(doubleValue: Double) {
        if doubleValue >= 127.0 || doubleValue <= -128.0 {
            return nil
        } else {
            self = Int8(doubleValue)
        }
    }

    public init?(uintValue: UInt16) {
        if uintValue > 255 {
            return nil
        } else {
            self = Int8(uintValue)
        }
    }
    
    public init?(intValue: Int16) {
        if intValue > 255 || intValue < 0 {
            return nil
        } else {
            self = Int8(intValue)
        }
    }

    public static func deserialize(data :NSData) -> Int8? {
        if data.length >= sizeof(Int8) {
            var value : Int8 = 0
            data.getBytes(&value, length:sizeof(Int8))
            return toHostByteOrder(value)
        } else {
            return nil
        }
    }

    public static func deserialize(data: NSData, start: Int) -> Int8? {
        if data.length >= start + sizeof(Int8) {
            var value : Int8 = 0
            data.getBytes(&value, range: NSMakeRange(start, sizeof(Int8)))
            return toHostByteOrder(value)
        } else {
            return nil
        }
    }

    public static func deserialize(data: NSData) -> [Int8] {
        let count = data.length / sizeof(Int8)
        return [Int](0..<count).reduce([]) {(result, start) in
            if let value = self.deserialize(data, start:start) {
                return result + [value]
            } else {
                return result
            }
        }
    }
    
}

