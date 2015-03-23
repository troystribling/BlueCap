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
    struct ServiceMock : ServiceWrappable {
        
        let impl = ServiceImpl<ServiceMock>()
        
        var _state :CBPeripheralState

        init(state:CBPeripheralState = .Connected) {
            self._state = state
        }
        
        var uuid : CBUUID! {
            return CBUUID(string:"2f0a0017-69aa-f316-3e78-4194989a6ccc")
        }
        
        var name : String {
            return "Mock"
        }
        
        var state: CBPeripheralState {
            return self._state
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
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }

    func testDiscoverCharacteristicsSuccess() {
        let mock = ServiceMock()
        let onSuccessExpectation = expectationWithDescription("onSuccess fulfilled for future")
        let future = mock.impl.discoverIfConnected(mock, characteristics:nil)
        future.onSuccess {_ in
            onSuccessExpectation.fulfill()
        }
        future.onFailure {error in
            XCTAssert(false, "onFailure called")
        }
        mock.impl.didDiscoverCharacteristics(mock, error:nil)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testDiscoverCharacteristicsFailure() {
        let mock = ServiceMock()
        let onFailureExpectation = expectationWithDescription("onFailure fulfilled for future")
        let future = mock.impl.discoverIfConnected(mock, characteristics:nil)
        future.onSuccess {_ in
            XCTAssert(false, "onSuccess called")
        }
        future.onFailure {error in
            onFailureExpectation.fulfill()
        }
        mock.impl.didDiscoverCharacteristics(mock, error:TestFailure.error)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testDiscoverCharacteristicsDisconnected() {
        let mock = ServiceMock(state:.Disconnected)
        let onFailureExpectation = expectationWithDescription("onFailure fulfilled for future")
        let future = mock.impl.discoverIfConnected(mock, characteristics:nil)
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
    }

}
