//
//  BCRawArrayDeserializableTests.swift
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

// MARK: - BCRawArrayDeserializableTests -
class BCRawArrayDeserializableTests: XCTestCase {

    struct RawArray: BCRawArrayDeserializable {
        
        let value1:Int8
        let value2:Int8
        
        // RawArrayDeserializable
        static let UUID = "abc"
        static let size = 2
        
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

    func testDeserialize_ValidRawArray_Sucess() {
        let data = "02ab".dataFromHexString()
        if let value : RawArray = BCSerDe.deserialize(data) {
            XCTAssert(value.value1 == 2 && value.value2 == -85, "RawArrayDeserializable deserialization value invalid: \(value.value1), \(value.value2)")
        } else {
            XCTFail("RawArrayDeserializable deserialization failed")
        }
    }
    
    func testDeserialize_InvalidRawArray_Fails() {
        let data = "02ab0c".dataFromHexString()
        if let _ : RawArray = BCSerDe.deserialize(data) {
            XCTFail("RawArrayDeserializable deserialization succeeded")
        }
    }
    
    func testSerialize_ValidRawArray_Success() {
        if let value = RawArray(rawValue: [5, 100]) {
            let data = BCSerDe.serialize(value)
            XCTAssert(data.hexStringValue() == "0564", "RawArrayDeserializable serialization value invalid: \(data)")
        } else {
            XCTFail("RawArrayDeserializable RawArray creation failed")
        }
    }

    func testCreate_InValidRawPairArray_Fails() {
        if let _ = RawArray(rawValue: [5]) {
            XCTFail("RawArrayDeserializable creation succeeded")
        }
    }

}
