//
//  RawArrayDeserializableTests.swift
//  BlueCapKit
//
//  Created by Troy Stribling on 2/9/15.
//  Copyright (c) 2015 gnos.us. All rights reserved.
//

import UIKit
import XCTest
import BlueCapKit

class RawArrayDeserializableTests: XCTestCase {

    struct RawArray : RawArrayDeserializable {
        
        let value1:Int8
        let value2:Int8
        
        // RawArrayDeserializable
        static let uuid = "abc"
        
        init?(rawValue:[Int8]) {
            if rawValue.count == 2 {
                self.value1 = rawValue[0]
                self.value2 = rawValue[1]
            } else {
                return nil
            }
        }
        
        var rawValue : [Int8] {
            return [self.value1, self.value2]
        }
        
    }

    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }

    func testSuccessfulDeserilaization() {
        let data = "02ab".dataFromHexString()
        if let value : RawArray = Serde.deserialize(data) {
            XCTAssert(value.value1 == 2 && value.value2 == -85, "RawArrayDeserializable deserialization value invalid: \(value.value1), \(value.value2)")
        } else {
            XCTFail("RawArrayDeserializable deserialization failed")
        }
    }
    
    func testFailedDeserilaization() {
        let data = "02ab0c".dataFromHexString()
        if let value : RawArray = Serde.deserialize(data) {
            XCTFail("RawArrayDeserializable deserialization succeeded")
        }
    }
    
    func testSerialization() {
        if let value = RawArray(rawValue:[5, 100]) {
            let data = Serde.serialize(value)
            XCTAssert(data.hexStringValue() == "0564", "RawArrayDeserializable serialization value invalid: \(data)")
        } else {
            XCTFail("RawArrayDeserializable RawArray creation failed")
        }
    }

}
