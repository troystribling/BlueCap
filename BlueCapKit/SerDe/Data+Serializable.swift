//
//  Data+Serializable.swift
//  BlueCap
//
//  Created by Troy Stribling on 6/29/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import Foundation

extension Data: Serializable {
    
    public static func fromString(_ value: String, encoding: String.Encoding = String.Encoding.utf8) -> Data? {
        return value.data(using: encoding)
    }
    
    public static func serialize<T>(_ value: T) -> Data {
        var littleValue = fromHostByteOrder(value)
        let size = MemoryLayout<T>.size
        return withUnsafePointer(to: &littleValue) { ptr in
            ptr.withMemoryRebound(to: UInt8.self, capacity: size) { bytes in
                Data(bytes: bytes, count: size)
            }
        }
    }
    
    public static func serializeArray<T>(_ values: [T]) -> Data {
        let littleValues = values.map{ fromHostByteOrder($0) }
        return littleValues.withUnsafeBufferPointer { Data(buffer: $0) }
    }

    public static func serialize<T1, T2>(_ value1: T1, value2: T2) -> Data {
        var data = Data.serialize(value1)
        data.append(Data.serialize(value2))
        return data
    }

    public static func serializeArrays<T1, T2>(_ values1: [T1], values2: [T2]) -> Data {
        var data = Data.serializeArray(values1)
        data.append(Data.serializeArray(values2))
        return data
    }

    public func hexStringValue() -> String {
        var dataBytes = [UInt8](repeating: 0x00, count: self.count)
        let buffer = UnsafeMutableBufferPointer(start: &dataBytes, count: self.count)
        _ = self.copyBytes(to: buffer, from:0..<self.count)
        let hexString = dataBytes.reduce(""){ (out: String, dataByte: UInt8) in
            return out + (NSString(format: "%02lx", dataByte) as String)
        }
        return hexString
    }
    
}
