//
//  CentralManagerTests.swift
//  BlueCapKit
//
//  Created by Troy Stribling on 1/7/15.
//  Copyright (c) 2015 gnos.us. All rights reserved.
//

import UIKit
import XCTest
import CoreBluetooth
import BlueCapKit

class CentralManagerTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }

    func testPowerOnWhenPoweredOn() {
        let mock = CentralManagerMock(state:.PoweredOn)
        let expectation = expectationWithDescription("onSuccess fulfilled for future")
        let future = mock.impl.powerOn(mock)
        future.onSuccess {
            expectation.fulfill()
        }
        future.onFailure{error in
            XCTAssert(false, "onFailure called")
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testPowerOnWhenPoweredOff() {
        let mock = CentralManagerMock(state:.PoweredOff)
        let expectation = expectationWithDescription("onSuccess fulfilled for future")
        let future = mock.impl.powerOn(mock)
        future.onSuccess {
            expectation.fulfill()
        }
        future.onFailure{error in
            XCTAssert(false, "onFailure called")
        }
        mock.state = .PoweredOn
        mock.impl.didUpdateState(mock)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testPowerOffWhenPoweredOn() {
        let mock = CentralManagerMock(state:.PoweredOn)
        let expectation = expectationWithDescription("onSuccess fulfilled for future")
        let future = mock.impl.powerOff(mock)
        future.onSuccess {
            expectation.fulfill()
        }
        future.onFailure{error in
            XCTAssert(false, "onFailure called")
        }
        mock.state = .PoweredOff
        mock.impl.didUpdateState(mock)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testPowerOffWhenPoweredOff() {
        let mock = CentralManagerMock(state:.PoweredOff)
        let expectation = expectationWithDescription("onSuccess fulfilled for future")
        let future = mock.impl.powerOff(mock)
        future.onSuccess {
            expectation.fulfill()
        }
        future.onFailure{error in
            XCTAssert(false, "onFailure called")
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testServiceScanning() {
        let mock = CentralManagerMock(state:.PoweredOff)
        let expectation = expectationWithDescription("onSuccess fulfilled for future")
        let future = mock.impl.startScanning(mock)
        future.onSuccess {_ in
            expectation.fulfill()
        }
        future.onFailure{error in
            XCTAssert(false, "onFailure called")
        }
        mock.impl.didDiscoverPeripheral(PeripheralMock(name:"Mock"))
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
}
