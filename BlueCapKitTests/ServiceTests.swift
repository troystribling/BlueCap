//
//  ServiceTests.swift
//  BlueCapKit
//
//  Created by Troy Stribling on 1/7/15.
//  Copyright (c) 2015 gnos.us. All rights reserved.
//

import UIKit
import XCTest
import CoreBluetooth
import BlueCapKit

class ServiceTests: XCTestCase {

    // ServiceMock
    struct MockValues {
        static var state :CBPeripheralState = .Connected
    }
    
    struct ServiceMock : ServiceWrappable {
        
        let impl = ServiceImpl<ServiceMock>()
        
        init() {            
        }
        
        var uuid : CBUUID! {
            return CBUUID(string:"2f0a0017-69aa-f316-3e78-4194989a6ccc")
        }
        
        var name : String {
            return "Mock"
        }
        
        var state: CBPeripheralState {
            return MockValues.state
        }
        
        func discoverCharacteristics(characteristics:[CBUUID]!) {
        }
        
        func didDiscoverCharacteristics(error:NSError!) {            
        }
        
        func createCharacteristics() {
        }

        func discoverAllCharacteristics() -> Future<ServiceMock> {
            return self.impl.discoverIfConnected(self, characteristics:nil)
        }

    }
    
    // ServiceMock
    let mock = ServiceMock()
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }

    func testDiscoverCharacteristicsSuccess() {
        let onSuccessExpectation = expectationWithDescription("onSuccess fulfilled for future")
        let future = self.mock.impl.discoverIfConnected(self.mock, characteristics:nil)
        future.onSuccess {_ in
            onSuccessExpectation.fulfill()
        }
        future.onFailure {error in
            XCTAssert(false, "onFailure called")
        }
        self.mock.impl.didDiscoverCharacteristics(self.mock, error:nil)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testDiscoverCharacteristicsFailure() {
        let onFailureExpectation = expectationWithDescription("onFailure fulfilled for future")
        let future = self.mock.impl.discoverIfConnected(self.mock, characteristics:nil)
        future.onSuccess {_ in
            XCTAssert(false, "onSuccess called")
        }
        future.onFailure {error in
            onFailureExpectation.fulfill()
        }
        self.mock.impl.didDiscoverCharacteristics(self.mock, error:TestFailure.error)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testDiscoverCharacteristicsDisconnected() {
        MockValues.state = .Disconnected
        let onFailureExpectation = expectationWithDescription("onFailure fulfilled for future")
        let future = self.mock.impl.discoverIfConnected(self.mock, characteristics:nil)
        future.onSuccess {_ in
            XCTAssert(false, "onSuccess called")
        }
        future.onFailure {error in
            onFailureExpectation.fulfill()
            XCTAssert(error.code == PeripheralError.Disconnected.rawValue, "Error code invalid \(error.code)")
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
        MockValues.state = .Connected
    }

}
