//
//  RawArrayPairDeserializableTests.swift
//  BlueCapKit
//
//  Created by Troy Stribling on 2/10/15.
//  Copyright (c) 2015 Troy Stribling. The MIT License (MIT).
//

import UIKit
import XCTest
import BlueCapKit

class RawArrayPairDeserializableTests: XCTestCase {

    struct Pair : RawArrayPairDeserializable {
        
        let value1:[Int8]
        let value2:[UInt8]
        static let size1 : Int = 2
        static let size2 : Int = 2
        
        // RawArrayPairDeserializable
        static let uuid = "abc"
        
        var rawValue1 : [Int8]  {
            return self.value1
        }
        
        var rawValue2 : [UInt8] {
            return self.value2
        }
        
        init?(rawValue1:[Int8], rawValue2:[UInt8]) {
            if rawValue1.count == Pair.size1 && rawValue2.count == Pair.size2 {
                self.value1 = rawValue1
                self.value2 = rawValue2
            } else {
                return nil
            }
        }
        
    }

    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }

    func testSuccessfulDeserialization() {
        let data = "02ab03ab".dataFromHexString()
        if let value : Pair = Serde.deserialize(data) {
            XCTAssert(value.value1 == [Int8]([2, -85]) && value.value2 == [UInt8]([3, 171]), "RawPairDeserializableTests deserialization value invalid: \(value.value1), \(value.value2)")
        } else {
            XCTFail("RawPairDeserializableTests deserialization failed")
        }
    }
    
    func testFailedDeserialization() {
        let data = "020103".dataFromHexString()
        if let value : Pair = Serde.deserialize(data) {
            XCTFail("RawPairDeserializableTests deserialization succeeded")
        }
    }
    
    func testSuccessfuleSerialization() {
        if let value = Pair(rawValue1:[2, -85], rawValue2:[3, 171]) {
            let data = Serde.serialize(value)
            println("data length:\(data.length)")
            XCTAssert(data.hexStringValue() == "02ab03ab", "RawDeserializable serialization failed: \(data.hexStringValue())")
        } else {
            XCTFail("RawPairDeserializableTests RawArray creation failed")
        }
    }
    
    func testFailedeSerialization() {
        if let value = Pair(rawValue1:[5], rawValue2:[1]) {
            XCTFail("RawPairDeserializableTests RawArray creation succeeded")
        }
    }

}
