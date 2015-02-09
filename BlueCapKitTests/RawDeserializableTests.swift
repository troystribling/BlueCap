//
//  RawDeserializableTests.swift
//  BlueCapKit
//
//  Created by Troy Stribling on 2/9/15.
//  Copyright (c) 2015 gnos.us. All rights reserved.
//

import Cocoa
import XCTest
import BlueCapKit

class RawDeserializableTests: XCTestCase {

    public enum Enabled: UInt8, RawDeserializable {
        case No     = 0
        case Yes    = 1
        case Maybe  = 2
    }

    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }

    func testSuccessfulDeserilaization() {
        
    }

    func testFailedDeserilaization() {
        
    }
    
    func testSerialization() {
        
    }

}
