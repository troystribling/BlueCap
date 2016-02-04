//
//  BCSerializableTests.swift
//  BlueCapKit
//
//  Created by Troy Stribling on 2/8/15.
//  Copyright (c) 2015 Troy Stribling. The MIT License (MIT).
//

import UIKit
import XCTest
import CoreBluetooth
import CoreLocation
import BlueCapKit

class SBCerializableTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }


    func testSerializeUInt8() {
        let data = BCSerDe.serialize(UInt8(100))
        XCTAssert(data.hexStringValue() == "64", "UInt8 serialization value invalid: \(data.hexStringValue())")
    }
    
    func testSerializeInt8() {
        let data = BCSerDe.serialize(Int8(-100))
        XCTAssert(data.hexStringValue() == "9c", "Int8 serialization value invalid: \(data.hexStringValue())")
    }
    
    func testSerializeUInt16() {
        let data = BCSerDe.serialize(UInt16(1000))
        XCTAssert(data.hexStringValue() == "e803", "UInt16 serialization value invalid: \(data.hexStringValue())")
    }

    func testSerializeInt16() {
        let data = BCSerDe.serialize(Int16(-1100))
        XCTAssert(data.hexStringValue() == "b4fb", "Int16 serialization value invalid: \(data.hexStringValue())")
    }
    
    func testSerializeUInt8Array() {
        let value : [UInt8] = [100, 10]
        let data = BCSerDe.serialize(value)
        XCTAssert(data.hexStringValue() == "640a", "UInt8 array serialization value invalid: \(data.hexStringValue())")
    }

    func testSerializeInt8Array() {
        let value : [Int8] = [-100, 10]
        let data = BCSerDe.serialize(value)
        XCTAssert(data.hexStringValue() == "9c0a", "Int8 array serialization value invalid: \(data.hexStringValue())")
    }
    
    func testSerializeUInt16Array() {
        let value : [UInt16] = [1000, 100]
        let data = BCSerDe.serialize(value)
        XCTAssert(data.hexStringValue() == "e8036400", "UInt16 array serialization value invalid: \(data.hexStringValue())")
    }

    func testSerializeInt16Array() {
        let value : [Int16] = [-1100, 100]
        let data = BCSerDe.serialize(value)
        XCTAssert(data.hexStringValue() == "b4fb6400", "Int16 array serialization value invalid: \(data.hexStringValue())")
    }

    func testSerializePair() {
        let data = NSData.serialize(Int16(-1100),  value2:UInt8(100))
        XCTAssert(data.hexStringValue() == "b4fb64", "Pair serialization value invalid: \(data.hexStringValue())")
    }

    func testSerializeArrayPair() {
        let value1 = [Int16(-1100), Int16(1000)]
        let value2 = [UInt8(100), UInt8(75)]
        let data = NSData.serializeArrays(value1, values2:value2)
        XCTAssert(data.hexStringValue() == "b4fbe803644b", "Pair serialization value invalid: \(data.hexStringValue())")
    }
}
