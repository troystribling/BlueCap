//
//  Int32+Deserializable.swift
//  BlueCapKit
//
//  Created by Troy Stribling on 6/23/16.
//  Copyright © 2016 Troy Stribling. All rights reserved.
//

import Foundation

extension Int32: Deserializable {

    public static var size : Int {
        return MemoryLayout<Int32>.size
    }

    public init?(doubleValue:Double) {
        if doubleValue > 0xFFFFFFFF || doubleValue < 0.0 {
            return nil
        } else {
            self = Int32(doubleValue)
        }
    }

    public static func deserialize(_ data: Data) -> Int32? {
        if data.count >= MemoryLayout<Int32>.size {
            var value : Int32 = 0
            let buffer = UnsafeMutableBufferPointer(start: &value, count: 1)
            _ = data.copyBytes(to: buffer, from:0..<MemoryLayout<Int32>.size)
            return toHostByteOrder(value)
        } else {
            return nil
        }
    }

    public static func deserialize(_ data: Data, start: Int) -> Int32? {
        if data.count >= start + MemoryLayout<Int32>.size {
            var value : Int32 = 0
            let buffer = UnsafeMutableBufferPointer(start: &value, count: 1)
            _ = data.copyBytes(to: buffer, from:start..<start+MemoryLayout<Int32>.size)
            return toHostByteOrder(value)
        } else {
            return nil
        }
    }

    public static func deserialize(_ data: Data) -> [Int32] {
        let size = MemoryLayout<Int32>.size
        let count = data.count / size
        return [Int](0..<count).reduce([]) {(result, idx) in
            if let value = self.deserialize(data, start: size*idx) {
                return result + [value]
            } else {
                return result
            }
        }
    }
}
