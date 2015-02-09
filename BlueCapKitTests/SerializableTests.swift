//
//  SerializableTests.swift
//  BlueCapKit
//
//  Created by Troy Stribling on 2/8/15.
//  Copyright (c) 2015 gnos.us. All rights reserved.
//

import UIKit
import XCTest
import BlueCapKit

class SerializableTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }


    func testSerializeUInt8() {
        let data = Serde.serialize(UInt8(100))
        XCTAssert(data.hexStringValue() == "64", "UInt8 serialization failed: \(data)")
    }
    
    func testSerializeInt8() {
        let data = Serde.serialize(Int8(-100))
        XCTAssert(data.hexStringValue() == "9c", "Int8 serialization failed: \(data)")
    }
    
    func testSerializeUInt16() {
        let data = Serde.serialize(UInt16(1000))
        XCTAssert(data.hexStringValue() == "e803", "UInt16 serialization failed: \(data)")
    }

    func testSerializeInt16() {
        let data = Serde.serialize(Int16(-1100))
        XCTAssert(data.hexStringValue() == "b4fb", "Int16 serialization failed: \(data)")
    }
    
    func testSerializeUInt8Array() {
        let value : [UInt8] = [100, 10]
        let data = Serde.serialize(value)
        XCTAssert(data.hexStringValue() == "640a", "UInt8 array serialization failed: \(data)")
    }

    func testSerializeInt8Array() {
        let value : [Int8] = [-100, 10]
        let data = Serde.serialize(value)
        XCTAssert(data.hexStringValue() == "9c0a", "Int8 array serialization failed: \(data)")
    }
    
    func testSerializeUInt16Array() {
        let value : [UInt16] = [1000, 100]
        let data = Serde.serialize(value)
        XCTAssert(data.hexStringValue() == "e8036400", "UInt16 array serialization failed: \(data)")
    }

    func testSerializeInt16Array() {
        let value : [Int16] = [-1100, 100]
        let data = Serde.serialize(value)
        XCTAssert(data.hexStringValue() == "b4fb6400", "Int16 array serialization failed: \(data)")
    }

    func testSerializePair() {
        let value = (Int16(-1100), UInt8(100))
        let data = NSData.serialize(value)
        XCTAssert(data.hexStringValue() == "b4fb64", "Pair serialization failed: \(data)")
    }

    func testSerializeArrayPair() {
        let value = ([Int16(-1100), Int16(1000)] , [UInt8(100), UInt8(75)])
        let data = NSData.serialize(value)
        XCTAssert(data.hexStringValue() == "b4fbe803644b", "Pair serialization failed: \(data)")
    }
}
