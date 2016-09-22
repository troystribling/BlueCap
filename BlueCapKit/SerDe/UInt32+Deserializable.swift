//
//  UInt32+Deserializable.swift
//  BlueCap
//
//  Created by Troy Stribling on 7/8/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import Foundation

extension UInt32: Deserializable {
    
    public static var size : Int {
        return MemoryLayout<UInt32>.size
    }

    public init?(doubleValue: Double) {
        if doubleValue > 0xFFFFFFFF || doubleValue < 0.0 {
            return nil
        } else {
            self = UInt32(doubleValue)
        }
    }

    public static func deserialize(_ data: Data) -> UInt32? {
        if data.count >= MemoryLayout<UInt32>.size {
            var value : UInt32 = 0
            let buffer = UnsafeMutableBufferPointer(start: &value, count: 1)
            _ = data.copyBytes(to: buffer, from:0..<MemoryLayout<UInt32>.size)
            return toHostByteOrder(value)
        } else {
            return nil
        }
    }
    
    public static func deserialize(_ data: Data, start: Int) -> UInt32? {
        if data.count >= start + MemoryLayout<UInt32>.size {
            var value : UInt32 = 0
            let buffer = UnsafeMutableBufferPointer(start: &value, count: 1)
            _ = data.copyBytes(to: buffer, from:start..<start+MemoryLayout<UInt32>.size)
            return toHostByteOrder(value)
        } else {
            return nil
        }
    }

    public static func deserialize(_ data: Data) -> [UInt32] {
        let size = MemoryLayout<UInt32>.size
        let count = data.count / size
        return [Int](0..<count).reduce([]) {(result, idx) in
            if let value = self.deserialize(data, start:size*idx) {
                return result + [value]
            } else {
                return result
            }
        }
    }
}
