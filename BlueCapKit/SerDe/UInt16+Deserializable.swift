//
//  UInt16+Deserializable.swift
//  BlueCap
//
//  Created by Troy Stribling on 7/8/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import Foundation

extension UInt16: Deserializable {
    
    public static var size: Int {
        return MemoryLayout<UInt16>.size
    }

    public init?(doubleValue: Double) {
        if doubleValue >= 65535.0 || doubleValue <= 0.0 {
            return nil
        } else {
            self = UInt16(doubleValue)
        }
    }

    public static func deserialize(_ data: Data) -> UInt16? {
        if data.count >= MemoryLayout<UInt16>.size {
            var value : UInt16 = 0
            let buffer = UnsafeMutableBufferPointer(start: &value, count: 1)
            _ = data.copyBytes(to: buffer, from:0..<MemoryLayout<UInt16>.size)
            return toHostByteOrder(value)
        } else {
            return nil
        }
    }
    
    public static func deserialize(_ data: Data, start: Int) -> UInt16? {
        if data.count >= start + MemoryLayout<UInt16>.size {
            var value : UInt16 = 0
            let buffer = UnsafeMutableBufferPointer(start: &value, count: 1)
            _ = data.copyBytes(to: buffer, from:start..<start+MemoryLayout<UInt16>.size)
            return toHostByteOrder(value)
        } else {
            return nil
        }
    }

    public static func deserialize(_ data: Data) -> [UInt16] {
        let size = MemoryLayout<UInt16>.size
        let count = data.count / size
        return [Int](0..<count).reduce([]) { (result, idx) in
            if let value = self.deserialize(data, start:size*idx) {
                return result + [value]
            } else {
                return result
            }
        }
    }
}
