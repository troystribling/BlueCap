//
//  UInt8+Deserializable.swift
//  BlueCap
//
//  Created by Troy Stribling on 7/8/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import Foundation

extension UInt8: Deserializable {
    
    public static var size: Int {
        return MemoryLayout<UInt8>.size
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

    public static func deserialize(_ data: Data) -> UInt8? {
        if data.count >= MemoryLayout<UInt8>.size {
            var value : UInt8 = 0
            let buffer = UnsafeMutableBufferPointer(start: &value, count: 1)
            _ = data.copyBytes(to: buffer, from:0..<MemoryLayout<UInt8>.size)
            return toHostByteOrder(value)
        } else {
            return nil
        }
    }
    
    public static func deserialize(_ data: Data, start: Int) -> UInt8? {
        if data.count >= start + MemoryLayout<UInt8>.size {
            var value : UInt8 = 0
            let buffer = UnsafeMutableBufferPointer(start: &value, count: 1)
            _ = data.copyBytes(to: buffer, from:start..<start+MemoryLayout<UInt8>.size)
            return toHostByteOrder(value)
        } else {
            return nil
        }
    }

    public static func deserialize(_ data: Data) -> [UInt8] {
        let count = data.count / MemoryLayout<UInt8>.size
        return [Int](0..<count).reduce([]) {(result, start) in
            if let value = self.deserialize(data, start: start) {
                return result + [value]
            } else {
                return result
            }
        }
    }
    
}
