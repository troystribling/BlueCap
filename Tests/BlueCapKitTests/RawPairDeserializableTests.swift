//
//  RawPairDeserializableTests.swift
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

// MARK: - RawPairDeserializableTests -
class RawPairDeserializableTests: XCTestCase {
    
    struct Pair: RawPairDeserializable {
        
        let value1: Int8
        let value2: UInt8
        
        // RawArrayPairDeserializable
        static let uuid = "abc"
        
        var rawValue1: Int8  {
            return self.value1
        }
        
        var rawValue2: UInt8 {
            return self.value2
        }
        
        init?(rawValue1: Int8, rawValue2: UInt8) {
            if rawValue2 > 10 {
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
    
    func testDeserialize_ValidPairDeserializable_Sucess() {
        let data = "02ab".dataFromHexString()
        if let value : Pair = SerDe.deserialize(data) {
            XCTAssert(value.value1 == 2 && value.value2 == 171)
        } else {
            XCTFail()
        }
    }
    
    func testDeserialize_InvalidPairDeserializable_Fails() {
        let data = "0201".dataFromHexString()
        if let _ : Pair = SerDe.deserialize(data) {
            XCTFail()
        }
    }
    
    func testSerialize_ValidPairDeserializable_Sucess() {
        if let value = Pair(rawValue1:5, rawValue2:100) {
            let data = SerDe.serialize(value)
            XCTAssert(data.hexStringValue() == "0564")
        } else {
            XCTFail()
        }
    }

    func testCreate_InvalidPairDeserializable_Fails() {
        if let _ = Pair(rawValue1:5, rawValue2:1) {
            XCTFail()
        }
    }

}
