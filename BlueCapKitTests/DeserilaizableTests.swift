//
//  BCDeserilaizableTests.swift
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

// MARK: - BCDeserilaizableTests -
class BCDeserilaizableTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }

    // MARK: UInt8
    func testDeserialize_WhenGivenSerializedUInt8_ReturnsUInt8() {
        let data = BCSerDe.serialize(UInt8(100))
        if let value: UInt8 = UInt8.deserialize(data) {
            XCTAssert(value == 100, "UInt8 deserialization value invalid: \(value)")
        } else {
            XCTFail("UInt8 deserialization failed")
        }
    }

    func testDeserialize_WhenGivenInvalidSerializedUInt8_ReturnsNil() {
        let data = NSData()
        if let value: UInt8 = UInt8.deserialize(data) {
            XCTFail("UInt8 deserialization succeded: \(value)")
        }
    }

    func testDeserialize_WhenGivenSerializedUInt8Array_ReturnsUInt8() {
        let value: [UInt8] = [100, 10]
        let data = BCSerDe.serialize(value)
        let des: [UInt8] = UInt8.deserialize(data)
        XCTAssert(des == [100, 10], "UInt8 array deserialization value invalid: \(des)")
    }


    // MARK: Int8
    func testDeserialize_WhenGivenSerializedInt8_ReturnsInt8() {
        let data = BCSerDe.serialize(Int8(-100))
        if let value: Int8 = BCSerDe.deserialize(data) {
            XCTAssert(value == -100, "Int8 deserialization value invalid: \(value)")
        } else {
            XCTFail("Int8 deserialization failed")
        }
    }

    func testDeserialize_WhenGivenInvalidSerializedInt8_ReturnsNil() {
        let data = NSData()
        if let value: Int8 = Int8.deserialize(data) {
            XCTFail("Int8 deserializaion succeded: \(value)")
        }
    }

    func testDeserialize_WhenGivenSerializedInt8Array_ReturnsInt8() {
        let value: [Int8] = [-100, 10]
        let data = BCSerDe.serialize(value)
        let des: [Int8] = Int8.deserialize(data)
        XCTAssert(des == value, "Int8 array deserialization value invalid: \(des)")
    }

    // MARK: UInt16
    func testDeserialize_WhenGivenSerializedUInt16_ReturnsUInt16() {
        let data = BCSerDe.serialize(UInt16(1000))
        if let value: UInt16 = UInt16.deserialize(data) {
            XCTAssert(value == 1000, "UInt16 deserialization value invalid: \(value)")
        } else {
            XCTFail("UInt16 deserializaion failed")
        }
    }

    func testDeserialize_WhenGivenInvalidSerializedUInt16_ReturnsNil() {
        let data = BCSerDe.serialize(UInt8(100))
        if let value: UInt16 = UInt16.deserialize(data) {
            XCTFail("UInt16 deserialization succeded: \(value)")
        }
    }

    func testDeserialize_WhenGivenSerializedUInt16Array_ReturnsUInt16() {
        let value: [UInt16] = [1000, 100]
        let data = BCSerDe.serialize(value)
        let des : [UInt16] = UInt16.deserialize(data)
        XCTAssert(des == value, "UInt16 array deserialization value invalid: \(des)")
    }

    // MARK: Int16
    func testDeserialize_WhenGivenSerializedInt16_ReturnsInt16() {
        let data = BCSerDe.serialize(Int16(-1100))
        if let value: Int16 = BCSerDe.deserialize(data) {
            XCTAssert(value == -1100, "Int16 deserialization value invalid: \(value)")
        } else {
            XCTFail("Unt16 deserializaion failed")
        }
    }
    
    func testDeserialize_WhenGivenInvalidSerializedInt16_ReturnsNil() {
        let data = BCSerDe.serialize(UInt8(100))
        if let value: Int16 = Int16.deserialize(data) {
            XCTFail("Int16 deserialization succeded: \(value)")
        }
    }
    
    func testDeserialize_WhenGivenSerializedInt16Array_ReturnsInt16() {
        let value: [Int16] = [-1100, 100]
        let data = BCSerDe.serialize(value)
        let des: [Int16] = Int16.deserialize(data)
        XCTAssert(des == value, "Int16 array deserialization value invalid: \(des)")
    }

    // MARK: UInt32
    func testDeserialize_WhenGivenSerializedUInt32_ReturnsUInt32() {
        let data = BCSerDe.serialize(UInt32(1000))
        if let value: UInt32 = UInt32.deserialize(data) {
            XCTAssert(value == 1000, "UInt32 deserialization value invalid: \(value)")
        } else {
            XCTFail("UInt32 deserializaion failed")
        }
    }

    func testDeserialize_WhenGivenInvalidSerializedUInt32_ReturnsNil() {
        let data = BCSerDe.serialize(UInt16(100))
        if let value: UInt32 = UInt32.deserialize(data) {
            XCTFail("UInt32 deserialization succeded: \(value)")
        }
    }

    func testDeserialize_WhenGivenSerializedUIntUInt32_ReturnsUUInt32() {
        let value: [UInt32] = [1000, 100]
        let data = BCSerDe.serialize(value)
        let des : [UInt32] = UInt32.deserialize(data)
        XCTAssert(des == value, "UInt32 array deserialization value invalid: \(des)")
    }

}
