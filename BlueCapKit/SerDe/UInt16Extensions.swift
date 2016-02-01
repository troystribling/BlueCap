//
//  UInt16Extensions.swift
//  BlueCap
//
//  Created by Troy Stribling on 7/8/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import Foundation

extension UInt16: BCDeserializable {
    
    public static var size: Int {
        return sizeof(UInt16)
    }

    public init?(doubleValue: Double) {
        if doubleValue >= 65535.0 || doubleValue <= 0.0 {
            return nil
        } else {
            self = UInt16(doubleValue)
        }
    }

    public static func deserialize(data: NSData) -> UInt16? {
        if data.length >= sizeof(UInt16) {
            var value : UInt16 = 0
            data.getBytes(&value, length: sizeof(UInt16))
            return toHostByteOrder(value)
        } else {
            return nil
        }
    }
    
    public static func deserialize(data: NSData, start: Int) -> UInt16? {
        if data.length >= start + sizeof(UInt16) {
            var value : UInt16 = 0
            data.getBytes(&value, range: NSMakeRange(start, sizeof(UInt16)))
            return toHostByteOrder(value)
        } else {
            return nil
        }
    }

    public static func deserialize(data: NSData) -> [UInt16] {
        let size = sizeof(UInt16)
        let count = data.length / size
        return [Int](0..<count).reduce([]) { (result, idx) in
            if let value = self.deserialize(data, start:size*idx) {
                return result + [value]
            } else {
                return result
            }
        }
    }
}
