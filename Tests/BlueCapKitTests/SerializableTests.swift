//
//  SerializableTests.swift
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

// MARK: - SerializableTests -
class SerializableTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }


    func testSerialize_UInt8_Sucess() {
        let data = SerDe.serialize(UInt8(100))
        XCTAssert(data.hexStringValue() == "64")
    }
    
    func testSerialize_Int8_Sucess() {
        let data = SerDe.serialize(Int8(-100))
        XCTAssert(data.hexStringValue() == "9c")
    }
    
    func testSerialize_UInt16_Sucess() {
        let data = SerDe.serialize(UInt16(1000))
        XCTAssert(data.hexStringValue() == "e803")
    }

    func testSerialize_Int16_Sucess() {
        let data = SerDe.serialize(Int16(-1100))
        XCTAssert(data.hexStringValue() == "b4fb")
    }

    func testSerialize_UInt32_Sucess() {
        let data = SerDe.serialize(UInt32(1000))
        XCTAssert(data.hexStringValue() == "e8030000")
    }

    func testSerialize_UInt8Array_Sucess() {
        let value : [UInt8] = [100, 10]
        let data = SerDe.serialize(value)
        XCTAssert(data.hexStringValue() == "640a")
    }

    func testSerialize_Int8Array_Sucess() {
        let value : [Int8] = [-100, 10]
        let data = SerDe.serialize(value)
        XCTAssert(data.hexStringValue() == "9c0a")
    }
    
    func testSerialize_UInt16Array_Sucess() {
        let value : [UInt16] = [1000, 100]
        let data = SerDe.serialize(value)
        XCTAssert(data.hexStringValue() == "e8036400")
    }

    func testSerialize_Int16Array_Sucess() {
        let value : [Int16] = [-1100, 100]
        let data = SerDe.serialize(value)
        XCTAssert(data.hexStringValue() == "b4fb6400")
    }

    func testSerialize_UInt32Array_Sucess() {
        let value : [UInt16] = [1000, 100]
        let data = SerDe.serialize(value)
        XCTAssert(data.hexStringValue() == "e8036400")
    }

    func testSerialize_Pair_Sucess() {
        let data = Data.serialize(Int16(-1100),  value2:UInt8(100))
        XCTAssert(data.hexStringValue() == "b4fb64")
    }

    func testSerialize_PairArray_Sucess() {
        let value1 = [Int16(-1100), Int16(1000)]
        let value2 = [UInt8(100), UInt8(75)]
        let data = Data.serializeArrays(value1, values2:value2)
        XCTAssert(data.hexStringValue() == "b4fbe803644b")
    }
}
