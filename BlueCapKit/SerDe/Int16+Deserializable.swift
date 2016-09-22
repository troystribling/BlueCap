//
//  Int16+Deserializable.swift
//  BlueCap
//
//  Created by Troy Stribling on 7/8/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import Foundation

extension Int16: Deserializable {
    
    public static var size: Int {
        return MemoryLayout<Int16>.size
    }
    
    public init?(doubleValue: Double) {
        if doubleValue >= 32767.0 || doubleValue <= -32768.0 {
            return nil
        } else {
            self = Int16(doubleValue)
        }
    }
    
    public static func deserialize(_ data: Data) -> Int16? {
        if data.count >= MemoryLayout<Int16>.size {
            var value: Int16 = 0
            let buffer = UnsafeMutableBufferPointer(start: &value, count: 1)
            _ = data.copyBytes(to: buffer, from:0..<MemoryLayout<Int16>.size)
            return toHostByteOrder(value)
        } else {
            return nil
        }
    }

    public static func deserialize(_ data: Data, start: Int) -> Int16? {
        if data.count >= (MemoryLayout<Int16>.size + start)  {
            var value : Int16 = 0
            let buffer = UnsafeMutableBufferPointer(start: &value, count: 1)
            _ = data.copyBytes(to: buffer, from:start..<start+MemoryLayout<Int16>.size)
            return toHostByteOrder(value)
        } else {
            return nil
        }
    }
    
    public static func deserialize(_ data: Data) -> [Int16] {
        let size = MemoryLayout<Int16>.size
        let count = data.count / size
        return [Int](0..<count).reduce([]) {(result, idx) in
            if let value = self.deserialize(data, start:idx*size) {
                return result + [value]
            } else {
                return result
            }
        }
    }
    
}
