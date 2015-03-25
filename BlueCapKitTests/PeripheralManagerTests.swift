//
//  PeripheralManagerTests.swift
//  BlueCapKit
//
//  Created by Troy Stribling on 3/25/15.
//  Copyright (c) 2015 gnos.us. All rights reserved.
//

import Cocoa
import XCTest

class PeripheralManagerTests: XCTestCase {

    // PeripheralmanagerMock
    class PeripheralmanagerMock : PeripheralManagerWrappable {
        var uuid : CBUUID  {
        }
        
        var name : String {
        }
    }
    
    class MutableServiceMock : MutableServiceWrappable {
        
    }
    
    // PeripheralmanagerMock
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }

}
