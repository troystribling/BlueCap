//
//  SerDe.swift
//  BlueCap
//
//  Created by Troy Stribling on 7/8/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import Foundation
import CoreBluetooth

// MARK: - Byte Swap -

func toHostByteOrder<T>(_ value: T) -> T {
    return value;
}

func fromHostByteOrder<T>(_ value: T) -> T {
    return value;
}

func byteArrayValue<T>(_ value: T) -> [UInt8] {
    var value = value
    return withUnsafePointer(to: &value) { ptr in
        ptr.withMemoryRebound(to: UInt8.self, capacity: MemoryLayout<T>.size) { bytes in
            let buffer = UnsafeBufferPointer(start: bytes, count:  MemoryLayout<T>.size)
            return Array(buffer)
        }
    }
}

// MARK: - SerDe Protocols -

public protocol Deserializable {
    static var size : Int { get }
    static func deserialize(_ data: Data) -> Self?
    static func deserialize(_ data: Data, start:Int) -> Self?
    static func deserialize(_ data: Data) -> [Self]
}

public protocol Serializable {
    static func fromString(_ value: String, encoding: String.Encoding) -> Data?
    static func serialize<T>(_ value: T) -> Data
    static func serialize<T>(_ values: [T]) -> Data
    static func serialize<T1, T2>(_ value1: T1, value2: T2) -> Data
    static func serialize<T1, T2>(_ value1: [T1], value2: [T2]) -> Data
}

public protocol CharacteristicConfigurable {
    static var name: String { get }
    static var uuid: String { get }
    static var permissions: CBAttributePermissions { get }
    static var properties: CBCharacteristicProperties { get }
    static var initialValue: Data? { get }
}

public protocol ServiceConfigurable {
    static var name: String { get }
    static var uuid: String { get }
    static var tag: String { get }
}

public protocol StringDeserializable {
    static var stringValues: [String] { get }
    var stringValue: [String : String] { get }
    init?(stringValue:[String : String])
}

public protocol RawDeserializable {
    associatedtype RawType
    static var uuid: String { get }
    var rawValue: RawType { get }
    init?(rawValue: RawType)
}

public protocol RawArrayDeserializable {
    associatedtype RawType
    static var uuid: String { get }
    static var size: Int { get }
    var rawValue: [RawType] { get }
    init?(rawValue: [RawType])
}

public protocol RawPairDeserializable {
    associatedtype RawType1
    associatedtype RawType2
    static var uuid: String { get }
    var rawValue1: RawType1 { get }
    var rawValue2: RawType2 { get }
    init?(rawValue1: RawType1, rawValue2: RawType2)
}

public protocol RawArrayPairDeserializable {
    associatedtype RawType1
    associatedtype RawType2
    static var uuid: String { get }
    static var size1: Int { get }
    static var size2: Int { get }
    var rawValue1: [RawType1] { get }
    var rawValue2: [RawType2] { get }
    init?(rawValue1: [RawType1], rawValue2: [RawType2])
}

// MARK: - SerDe -

public struct SerDe {
    
    public static func serialize(_ value: String, encoding: String.Encoding = String.Encoding.utf8) -> Data? {
        return Data.fromString(value, encoding: encoding)
    }

    public static func deserialize(_ data: Data, encoding: String.Encoding = String.Encoding.utf8) -> String? {
        return String(data: data, encoding: encoding)
    }

    public static func deserialize<T: Deserializable>(_ data: Data) -> T? {
        return T.deserialize(data)
    }

    public static func serialize<T: Deserializable>(_ value: T) -> Data {
        return Data.serialize(value)
    }

    public static func serialize<T: Deserializable>(_ values: [T]) -> Data {
        return Data.serializeArray(values)
    }

    public static func deserialize<T: RawDeserializable>(_ data: Data) -> T? where T.RawType: Deserializable {
        return T.RawType.deserialize(data).flatMap{ T(rawValue: $0) }
    }

    public static func serialize<T: RawDeserializable>(_ value: T) -> Data {
        return Data.serialize(value.rawValue)
    }

    public static func deserialize<T: RawArrayDeserializable>(_ data: Data) -> T? where T.RawType: Deserializable {
        if data.count >= T.size {
            return T(rawValue:T.RawType.deserialize(data))
        } else {
            return nil
        }
    }

    public static func serialize<T: RawArrayDeserializable>(_ value: T) -> Data {
        return Data.serializeArray(value.rawValue)
    }

    public static func deserialize<T: RawPairDeserializable>(_ data: Data) -> T? where T.RawType1: Deserializable,  T.RawType2: Deserializable {
        if data.count >= (T.RawType1.size + T.RawType2.size) {
            let rawData1 = data.subdata(in: 0..<T.RawType1.size)
            let rawData2 = data.subdata(in: T.RawType1.size..<T.RawType2.size+T.RawType1.size)
            return T.RawType1.deserialize(rawData1).flatMap { rawValue1 in
                T.RawType2.deserialize(rawData2).flatMap { rawValue2 in
                    T(rawValue1: rawValue1, rawValue2: rawValue2)
                }
            }
        } else {
            return nil
        }
    }

    public static func serialize<T: RawPairDeserializable>(_ value: T) -> Data {
        return Data.serialize(value.rawValue1, value2: value.rawValue2)
    }

    public static func deserialize<T: RawArrayPairDeserializable>(_ data: Data) -> T? where T.RawType1: Deserializable,  T.RawType2: Deserializable {
        if data.count >= (T.size1 + T.size2) {
            let rawData1 = data.subdata(in: 0..<T.size1)
            let rawData2 = data.subdata(in: T.size1..<T.size2+T.size2)
            return T(rawValue1:T.RawType1.deserialize(rawData1), rawValue2: T.RawType2.deserialize(rawData2))
        } else {
            return nil
        }
    }

    public static func serialize<T: RawArrayPairDeserializable>(_ value: T) -> Data {
        return Data.serializeArrays(value.rawValue1, values2: value.rawValue2)
    }
}




