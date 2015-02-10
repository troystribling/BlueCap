//
//  RawDeserializableTests.swift
//  BlueCapKit
//
//  Created by Troy Stribling on 2/9/15.
//  Copyright (c) 2015 gnos.us. All rights reserved.
//

import UIKit
import XCTest
import BlueCapKit

class RawDeserializableTests: XCTestCase {

    public enum Testit: UInt8, RawDeserializable {
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

    func testSuccessfulDeserilaization() {
        let data = "02".dataFromHexString()
        if let value : Testit = Serde.deserialize(data) {
            XCTAssert(value == .Maybe, "RawDeserializable deserailization failed: \(data)")
        } else {
            XCTFail("RawDeserializable deserailization failed")
        }
    }

    func testFailedDeserilaization() {
        let data = "03".dataFromHexString()
        if let value : Testit = Serde.deserialize(data) {
            XCTFail("RawDeserializable deserailization succeeded")
        }
    }
    
    func testSerialization() {
        let value = Testit.Yes
        let data = Serde.serialize(value)
        XCTAssert(data.hexStringValue() == "01", "RawDeserializable serualization failed: \(data)")
    }

}
