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
@testable import BlueCapKit

// MARK: - BCSerializableTests -
class BCSerializableTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }


    func testSerialize_UInt8_Sucess() {
        let data = BCSerDe.serialize(UInt8(100))
        XCTAssert(data.hexStringValue() == "64", "UInt8 serialization value invalid: \(data.hexStringValue())")
    }
    
    func testSerialize_Int8_Sucess() {
        let data = BCSerDe.serialize(Int8(-100))
        XCTAssert(data.hexStringValue() == "9c", "Int8 serialization value invalid: \(data.hexStringValue())")
    }
    
    func testSerialize_UInt16_Sucess() {
        let data = BCSerDe.serialize(UInt16(1000))
        XCTAssert(data.hexStringValue() == "e803", "UInt16 serialization value invalid: \(data.hexStringValue())")
    }

    func testSerialize_Int16_Sucess() {
        let data = BCSerDe.serialize(Int16(-1100))
        XCTAssert(data.hexStringValue() == "b4fb", "Int16 serialization value invalid: \(data.hexStringValue())")
    }

    func testSerialize_UInt32_Sucess() {
        let data = BCSerDe.serialize(UInt32(1000))
        XCTAssert(data.hexStringValue() == "e8030000", "UInt16 serialization value invalid: \(data.hexStringValue())")
    }

    func testSerialize_UInt8Array_Sucess() {
        let value : [UInt8] = [100, 10]
        let data = BCSerDe.serialize(value)
        XCTAssert(data.hexStringValue() == "640a", "UInt8 array serialization value invalid: \(data.hexStringValue())")
    }

    func testSerialize_Int8Array_Sucess() {
        let value : [Int8] = [-100, 10]
        let data = BCSerDe.serialize(value)
        XCTAssert(data.hexStringValue() == "9c0a", "Int8 array serialization value invalid: \(data.hexStringValue())")
    }
    
    func testSerialize_UInt16Array_Sucess() {
        let value : [UInt16] = [1000, 100]
        let data = BCSerDe.serialize(value)
        XCTAssert(data.hexStringValue() == "e8036400", "UInt16 array serialization value invalid: \(data.hexStringValue())")
    }

    func testSerialize_Int16Array_Sucess() {
        let value : [Int16] = [-1100, 100]
        let data = BCSerDe.serialize(value)
        XCTAssert(data.hexStringValue() == "b4fb6400", "Int16 array serialization value invalid: \(data.hexStringValue())")
    }

    func testSerialize_UInt32Array_Sucess() {
        let value : [UInt16] = [1000, 100]
        let data = BCSerDe.serialize(value)
        XCTAssert(data.hexStringValue() == "e8036400", "UInt16 array serialization value invalid: \(data.hexStringValue())")
    }

    func testSerialize_Pair_Sucess() {
        let data = NSData.serialize(Int16(-1100),  value2:UInt8(100))
        XCTAssert(data.hexStringValue() == "b4fb64", "Pair serialization value invalid: \(data.hexStringValue())")
    }

    func testSerialize_PairArray_Sucess() {
        let value1 = [Int16(-1100), Int16(1000)]
        let value2 = [UInt8(100), UInt8(75)]
        let data = NSData.serializeArrays(value1, values2:value2)
        XCTAssert(data.hexStringValue() == "b4fbe803644b", "Pair serialization value invalid: \(data.hexStringValue())")
    }
}
