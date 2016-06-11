//
//  RawDeserializableTests.swift
//  BlueCapKit
//
//  Created by Troy Stribling on 2/9/15.
//  Copyright (c) 2015 Troy Stribling. The MIT License (MIT).
//

import UIKit
import XCTest
import CoreBluetooth
import CoreLocation
@testable import BlueCapKit

// MARK: - RawDeserializableTests -
class RawDeserializableTests: XCTestCase {

    enum Testit: UInt8, RawDeserializable {
        case No     = 0
        case Yes    = 1
        case Maybe  = 2        
        static let UUID = "abc"
    }

    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }

    func testDeserialize_ValidRawDeserializable_Sucess() {
        let data = "02".dataFromHexString()
        if let value : Testit = SerDe.deserialize(data) {
            XCTAssert(value == .Maybe, "RawDeserializable deserialization value wrong: \(data)")
        } else {
            XCTFail("RawDeserializable deserialization failed")
        }
    }

    func testDeserialize_InvalidRawDeserializable_Fails() {
        let data = "03".dataFromHexString()
        if let _ : Testit = SerDe.deserialize(data) {
            XCTFail("RawDeserializable deserialization succeeded")
        }
    }
    
    func testSerialize_ValidRawDeserializable_Sucess() {
        let value = Testit.Yes
        let data = SerDe.serialize(value)
        XCTAssert(data.hexStringValue() == "01", "RawDeserializable serialization failed: \(data)")
    }

    func testCreate_InvalidRawDeserializable_Fails() {
        if let _ = Testit(rawValue: 5) {
            XCTFail("RawDeserializable creation succeeded")
        }
    }

}
