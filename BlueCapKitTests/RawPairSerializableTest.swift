//
//  RawPairSerializableTest.swift
//  BlueCapKit
//
//  Created by Troy Stribling on 2/9/15.
//  Copyright (c) 2015 gnos.us. All rights reserved.
//

import UIKit
import XCTest
import BlueCapKit

class RawPairSerializableTest: XCTestCase {

//    struct RawPair : RawPairDeserializable {
//        
//        let value1:Int8
//        let value2:UInt8
//        
//        // RawArrayPairDeserializable
//        static let uuid = "abc"
//        
//        init?(rawValue:(Int8, UInt8)) {
//            let (raw1, raw2) = rawValue
//            if raw2 > 10 {
//                self.value1 = raw1
//                self.value2 = raw2
//            } else {
//                return nil
//            }
//            
//        }
//        
//        var rawValue : (Int8, UInt8) {
//            return (self.value1, self.value2)
//        }
//        
//    }
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
//    func testSuccessfulDeserilaization() {
//        let data = "02ab".dataFromHexString()
//        if let value : RawPair = Serde.deserialize(data) {
//            XCTAssert(value.value1 == 2 && value.value2 == 171, "RawArrayDeserializable deserialization value invalid: \(value.value1), \(value.value2)")
//        } else {
//            XCTFail("RawArrayDeserializable deserialization failed")
//        }
//    }
//    
//    func testFailedDeserilaization() {
//        let data = "0201c".dataFromHexString()
//        if let value : RawPair = Serde.deserialize(data) {
//            XCTFail("RawArrayDeserializable deserialization succeeded")
//        }
//    }
//    
//    func testSerialization() {
//        let value = RawPair(rawValue:(5, 100))
//        let data = Serde.serialize(value)
//        XCTAssert(data.hexStringValue() == "0564", "RawDeserializable serialization failed: \(data)")
//    }    

}
