//
//  RawDeserializableTests.swift
//  BlueCapKit
//
//  Created by Troy Stribling on 2/9/15.
//  Copyright (c) 2015 Troy Stribling. The MIT License (MIT).
//

import UIKit
import XCTest
import BlueCapKit

class RawDeserializableTests: XCTestCase {

    enum Testit: UInt8, RawDeserializable {
        case No     = 0
        case Yes    = 1
        case Maybe  = 2        
        static let uuid = "abc"
    }

    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }

    func testSuccessfulDeserialization() {
        let data = "02".dataFromHexString()
        if let value : Testit = Serde.deserialize(data) {
            XCTAssert(value == .Maybe, "RawDeserializable deserialization value wrong: \(data)")
        } else {
            XCTFail("RawDeserializable deserialization failed")
        }
    }

    func testFailedDeserialization() {
        let data = "03".dataFromHexString()
        if let value : Testit = Serde.deserialize(data) {
            XCTFail("RawDeserializable deserialization succeeded")
        }
    }
    
    func testSerialization() {
        let value = Testit.Yes
        let data = Serde.serialize(value)
        XCTAssert(data.hexStringValue() == "01", "RawDeserializable serialization failed: \(data)")
    }

}
