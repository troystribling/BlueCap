//
//  DeserilaizableTests.swift
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

// MARK: - DeserilaizableTests -
class DeserilaizableTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }

    // MARK: UInt8
    func testDeserialize_WhenGivenSerializedUInt8_ReturnsUInt8() {
        let data = SerDe.serialize(UInt8(100))
        if let value: UInt8 = UInt8.deserialize(data) {
            XCTAssert(value == 100)
        } else {
            XCTFail()
        }
    }

    func testDeserialize_WhenGivenInvalidSerializedUInt8_ReturnsNil() {
        let data = Data()
        if let _: UInt8 = UInt8.deserialize(data) {
            XCTFail()
        }
    }

    func testDeserialize_WhenGivenSerializedUInt8Array_ReturnsUInt8() {
        let value: [UInt8] = [100, 10]
        let data = SerDe.serialize(value)
        let des: [UInt8] = UInt8.deserialize(data)
        XCTAssert(des == [100, 10])
    }


    // MARK: Int8
    func testDeserialize_WhenGivenSerializedInt8_ReturnsInt8() {
        let data = SerDe.serialize(Int8(-100))
        if let value: Int8 = SerDe.deserialize(data) {
            XCTAssert(value == -100)
        } else {
            XCTFail()
        }
    }

    func testDeserialize_WhenGivenInvalidSerializedInt8_ReturnsNil() {
        let data = Data()
        if let _: Int8 = Int8.deserialize(data) {
            XCTFail()
        }
    }

    func testDeserialize_WhenGivenSerializedInt8Array_ReturnsInt8() {
        let value: [Int8] = [-100, 10]
        let data = SerDe.serialize(value)
        let des: [Int8] = Int8.deserialize(data)
        XCTAssert(des == value)
    }

    // MARK: UInt16
    func testDeserialize_WhenGivenSerializedUInt16_ReturnsUInt16() {
        let data = SerDe.serialize(UInt16(1000))
        if let value: UInt16 = UInt16.deserialize(data) {
            XCTAssert(value == 1000)
        } else {
            XCTFail()
        }
    }

    func testDeserialize_WhenGivenInvalidSerializedUInt16_ReturnsNil() {
        let data = SerDe.serialize(UInt8(100))
        if let _: UInt16 = UInt16.deserialize(data) {
            XCTFail()
        }
    }

    func testDeserialize_WhenGivenSerializedUInt16Array_ReturnsUInt16() {
        let value: [UInt16] = [1000, 100]
        let data = SerDe.serialize(value)
        let des : [UInt16] = UInt16.deserialize(data)
        XCTAssert(des == value)
    }

    // MARK: Int16
    func testDeserialize_WhenGivenSerializedInt16_ReturnsInt16() {
        let data = SerDe.serialize(Int16(-1100))
        if let value: Int16 = SerDe.deserialize(data) {
            XCTAssert(value == -1100)
        } else {
            XCTFail()
        }
    }
    
    func testDeserialize_WhenGivenInvalidSerializedInt16_ReturnsNil() {
        let data = SerDe.serialize(UInt8(100))
        if let _: Int16 = Int16.deserialize(data) {
            XCTFail()
        }
    }
    
    func testDeserialize_WhenGivenSerializedInt16Array_ReturnsInt16() {
        let value: [Int16] = [-1100, 100]
        let data = SerDe.serialize(value)
        let des: [Int16] = Int16.deserialize(data)
        XCTAssert(des == value)
    }

    // MARK: Int32
    func testDeserialize_WhenGivenSerializedInt32_ReturnsInt32() {
        let data = SerDe.serialize(Int32(1000))
        if let value: Int32 = Int32.deserialize(data) {
            XCTAssert(value == 1000)
        } else {
            XCTFail()
        }
    }

    func testDeserialize_WhenGivenInvalidSerializedInt32_ReturnsNil() {
        let data = SerDe.serialize(Int16(100))
        if let _: Int32 = Int32.deserialize(data) {
            XCTFail()
        }
    }

    func testDeserialize_WhenGivenSerializedUIntInt32_ReturnsInt32() {
        let value: [UInt32] = [1000, 100]
        let data = SerDe.serialize(value)
        let des : [UInt32] = UInt32.deserialize(data)
        XCTAssert(des == value)
    }

    // MARK: UInt32
    func testDeserialize_WhenGivenSerializedUInt32_ReturnsUInt32() {
        let data = SerDe.serialize(UInt32(1000))
        if let value: UInt32 = UInt32.deserialize(data) {
            XCTAssert(value == 1000)
        } else {
            XCTFail()
        }
    }

    func testDeserialize_WhenGivenInvalidSerializedUInt32_ReturnsNil() {
        let data = SerDe.serialize(UInt16(100))
        if let _: UInt32 = UInt32.deserialize(data) {
            XCTFail()
        }
    }

    func testDeserialize_WhenGivenSerializedUIntUInt32_ReturnsUInt32() {
        let value: [UInt32] = [1000, 100]
        let data = SerDe.serialize(value)
        let des : [UInt32] = UInt32.deserialize(data)
        XCTAssert(des == value)
    }

}
