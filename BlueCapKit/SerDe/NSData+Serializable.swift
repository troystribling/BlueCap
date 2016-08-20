//
//  NSData+Serializable.swift
//  BlueCap
//
//  Created by Troy Stribling on 6/29/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import Foundation

extension Data: Serializable {
    
    public static func fromString(_ value: String, encoding: String.Encoding = String.Encoding.utf8) -> Data? {
        return value.data(using: encoding).map{ (NSData(data:$0) as Data) }
    }
    
    public static func serialize<T>(_ value: T) -> Data {
        let values = [fromHostByteOrder(value)]
        return Data(bytes: UnsafePointer<UInt8>(values), count:sizeof(T))
    }
    
    public static func serializeArray<T>(_ values: [T]) -> Data {
        let littleValues = values.map{fromHostByteOrder($0)}
        return Data(bytes: UnsafePointer<UInt8>(littleValues), count: sizeof(T)*littleValues.count)
    }

    public static func serialize<T1, T2>(_ value1: T1, value2: T2) -> Data {
        let data = NSMutableData()
        data.setData(Data.serialize(value1))
        data.append(Data.serialize(value2))
        return data as Data
    }

    public static func serializeArrays<T1, T2>(_ values1: [T1], values2: [T2]) -> Data {
        let data = NSMutableData()
        data.setData(Data.serializeArray(values1))
        data.append(Data.serializeArray(values2))
        return data as Data
    }

    public func hexStringValue() -> String {
        var dataBytes = [UInt8](repeating: 0x0, count: self.count)
        (self as NSData).getBytes(&dataBytes, length:self.count)
        let hexString = dataBytes.reduce(""){ (out: String, dataByte: UInt8) in
            return out + (NSString(format: "%02lx", dataByte) as String)
        }
        return hexString
    }
    
}
