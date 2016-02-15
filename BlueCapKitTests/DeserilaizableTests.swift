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
import BlueCapKit

// MARK: - BCDeserilaizableTests -
class BCDeserilaizableTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }

    // MARK: UInt8
    func testSuccessfulDeserializeUInt8() {
        let data = BCSerDe.serialize(UInt8(100))
        if let value: UInt8 = BCSerDe.deserialize(data) {
            XCTAssert(value == 100, "UInt8 deserialization value invalid: \(value)")
        } else {
            XCTFail("UInt8 deserialization failed")
        }
    }

    func testFailedDeserializeUInt8() {
        let data = NSData()
        if let value: UInt8 = BCSerDe.deserialize(data) {
            XCTFail("UInt8 deserialization succeded: \(value)")
        }
    }

    func testDeserializeUInt8Array() {
        let value: [UInt8] = [100, 10]
        let data = BCSerDe.serialize(value)
        let des: [UInt8] = UInt8.deserialize(data)
        XCTAssert(des == [100, 10], "UInt8 array deserialization value invalid: \(des)")
    }


    // MARK: Int8
    func testSuccessfulDeserializeInt8() {
        let data = BCSerDe.serialize(Int8(-100))
        if let value: Int8 = BCSerDe.deserialize(data) {
            XCTAssert(value == -100, "Int8 deserialization value invalid: \(value)")
        } else {
            XCTFail("Int8 deserialization failed")
        }
    }

    func testFailedDeserializeInt8() {
        let data = NSData()
        if let value: UInt8 = BCSerDe.deserialize(data) {
            XCTFail("Int8 deserializaion succeded: \(value)")
        }
    }

    func testDeserializeInt8Array() {
        let value: [Int8] = [-100, 10]
        let data = BCSerDe.serialize(value)
        let des: [Int8] = Int8.deserialize(data)
        XCTAssert(des == [-100, 10], "Int8 array deserialization value invalid: \(des)")
    }

    // MARK: UInt16
    func testSuccessfulDeserializeUInt16() {
        let data = BCSerDe.serialize(UInt16(1000))
        if let value: UInt16 = BCSerDe.deserialize(data) {
            XCTAssert(value == 1000, "UInt16 deserialization value invalid: \(value)")
        } else {
            XCTFail("UInt16 deserializaion failed")
        }
    }

    func testFailedDeserializeUInt16() {
        let data = BCSerDe.serialize(UInt8(100))
        if let value: UInt16 = BCSerDe.deserialize(data) {
            XCTFail("UInt16 deserialization succeded: \(value)")
        }
    }

    func testDeserializeUInt16Array() {
        let value: [UInt16] = [1000, 100]
        let data = BCSerDe.serialize(value)
        let des : [UInt16] = UInt16.deserialize(data)
        XCTAssert(des == [1000, 100], "UInt16 array deserialization value invalid: \(des)")
    }

    // MARK: Int16
    func testSuccessfulDeserializeInt16() {
        let data = BCSerDe.serialize(Int16(-1100))
        if let value: Int16 = BCSerDe.deserialize(data) {
            XCTAssert(value == -1100, "Int16 deserialization value invalid: \(value)")
        } else {
            XCTFail("Unt16 deserializaion failed")
        }
    }
    
    func testFailedDeserializeInt16() {
        let data = BCSerDe.serialize(UInt8(100))
        if let value: Int16 = BCSerDe.deserialize(data) {
            XCTFail("Int16 deserialization succeded: \(value)")
        }
    }
    
    func testDeserializeInt16Array() {
        let value: [Int16] = [-1100, 100]
        let data = BCSerDe.serialize(value)
        let des: [Int16] = Int16.deserialize(data)
        XCTAssert(des == [-1100, 100], "Int16 array deserialization value invalid: \(des)")
    }

    // TODO: UInt32

}
