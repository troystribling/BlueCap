//
//  BCRawArrayPairDeserializableTests.swift
//  BlueCapKit
//
//  Created by Troy Stribling on 2/10/15.
//  Copyright (c) 2015 Troy Stribling. The MIT License (MIT).
//

import UIKit
import XCTest
import CoreBluetooth
import CoreLocation
@testable import BlueCapKit

// MARK: - BCRawArrayPairDeserializableTests -
class BCRawArrayPairDeserializableTests: XCTestCase {

    struct Pair: BCRawArrayPairDeserializable {
        
        let value1: [Int8]
        let value2: [UInt8]
        static let size1: Int = 2
        static let size2: Int = 2
        
        // RawArrayPairDeserializable
        static let UUID = "abc"
        
        var rawValue1: [Int8]  {
            return self.value1
        }
        
        var rawValue2: [UInt8] {
            return self.value2
        }
        
        init?(rawValue1: [Int8], rawValue2: [UInt8]) {
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

    func testDeserialize_ValidRawPairArray_Sucess() {
        let data = "02ab03ab".dataFromHexString()
        if let value : Pair = BCSerDe.deserialize(data) {
            XCTAssert(value.value1 == [Int8]([2, -85]) && value.value2 == [UInt8]([3, 171]), "RawPairDeserializableTests deserialization value invalid: \(value.value1), \(value.value2)")
        } else {
            XCTFail("RawArrayPair deserialization failed")
        }
    }
    
    func testDeserialize_InvalidRawPairArray_Fails() {
        let data = "020103".dataFromHexString()
        if let _ : Pair = BCSerDe.deserialize(data) {
            XCTFail("RawArrayPair deserialization succeeded")
        }
    }
    
    func testSerialize_ValidRawPairArray_Sucess() {
        if let value = Pair(rawValue1:[2, -85], rawValue2:[3, 171]) {
            let data = BCSerDe.serialize(value)
            XCTAssert(data.hexStringValue() == "02ab03ab", "RawDeserializable serialization failed: \(data.hexStringValue())")
        } else {
            XCTFail("RawArrayPair creation failed")
        }
    }
    
    func testCreate_InValidRawPairArray_Fails() {
        if let _ = Pair(rawValue1: [5], rawValue2: [1]) {
            XCTFail("RawArrayPair creation succeeded")
        }
    }

}
