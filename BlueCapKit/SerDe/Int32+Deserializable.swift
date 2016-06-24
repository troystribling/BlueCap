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
        return sizeof(Int32)
    }

    public init?(doubleValue:Double) {
        if doubleValue > 0xFFFFFFFF || doubleValue < 0.0 {
            return nil
        } else {
            self = Int32(doubleValue)
        }
    }

    public static func deserialize(data: NSData) -> Int32? {
        if data.length >= sizeof(Int32) {
            var value : Int32 = 0
            data.getBytes(&value, length: sizeof(Int32))
            return toHostByteOrder(value)
        } else {
            return nil
        }
    }

    public static func deserialize(data: NSData, start: Int) -> Int32? {
        if data.length >= start + sizeof(Int32) {
            var value : Int32 = 0
            data.getBytes(&value, range:NSMakeRange(start, sizeof(Int32)))
            return toHostByteOrder(value)
        } else {
            return nil
        }
    }

    public static func deserialize(data: NSData) -> [Int32] {
        let size = sizeof(Int32)
        let count = data.length / size
        return [Int](0..<count).reduce([]) {(result, idx) in
            if let value = self.deserialize(data, start: size*idx) {
                return result + [value]
            } else {
                return result
            }
        }
    }
}
