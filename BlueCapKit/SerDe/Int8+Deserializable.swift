//
//  Int8+Deserializable.swift
//  BlueCap
//
//  Created by Troy Stribling on 7/8/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import Foundation

extension Int8: Deserializable {
    
    public static var size: Int {
        return MemoryLayout<Int8>.size
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

    public static func deserialize(_ data: Data) -> Int8? {
        if data.count >= MemoryLayout<Int8>.size {
            var value : Int8 = 0
            let buffer = UnsafeMutableBufferPointer(start: &value, count: 1)
            _ = data.copyBytes(to: buffer, from:0..<MemoryLayout<Int8>.size)
            return toHostByteOrder(value)
        } else {
            return nil
        }
    }

    public static func deserialize(_ data: Data, start: Int) -> Int8? {
        if data.count >= start + MemoryLayout<Int8>.size {
            var value : Int8 = 0
            let buffer = UnsafeMutableBufferPointer(start: &value, count: 1)
            _ = data.copyBytes(to: buffer, from:start..<start+MemoryLayout<Int8>.size)
            return toHostByteOrder(value)
        } else {
            return nil
        }
    }

    public static func deserialize(_ data: Data) -> [Int8] {
        let count = data.count / MemoryLayout<Int8>.size
        return [Int](0..<count).reduce([]) {(result, start) in
            if let value = self.deserialize(data, start:start) {
                return result + [value]
            } else {
                return result
            }
        }
    }
    
}

