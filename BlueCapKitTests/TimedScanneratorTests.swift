//
//  TimedScanneratorTests.swift
//  BlueCapKit
//
//  Created by Troy Stribling on 1/7/15.
//  Copyright (c) 2015 gnos.us. All rights reserved.
//

import UIKit
import XCTest
import CoreBluetooth
import BlueCapKit

class TimedScanneratorTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }

    func testScanSuccessful() {
        let mock = TimedScanneratorMock()
        let onSuccessExpectation = expectationWithDescription("onSuccess fulfilled for future")
        let future = mock.impl.startScanning(mock, timeoutSeconds:2)
        future.onSuccess {_ in
            onSuccessExpectation.fulfill()
        }
        future.onFailure {error in
            XCTAssert(false, "onFailure called")
        }
        mock.didDiscoverPeripheral(PeripheralMock())
        waitForExpectationsWithTimeout(5) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func testScanTimeout() {
        let mock = TimedScanneratorMock()
        let onFailureExpectation = expectationWithDescription("onFailure fulfilled for future")
        let future = mock.impl.startScanning(mock, timeoutSeconds:1)
        future.onSuccess {_ in
            XCTAssert(false, "onSuccess called")
        }
        future.onFailure {error in
            XCTAssert(PeripheralError.DiscoveryTimeout.rawValue == error.code, "onFailure error invalid \(error.code)")
            onFailureExpectation.fulfill()
        }
        waitForExpectationsWithTimeout(10) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

}
