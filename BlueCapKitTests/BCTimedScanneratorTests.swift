//
//  BCTimedScanneratorTests.swift
//  BlueCapKit
//
//  Created by Troy Stribling on 1/7/15.
//  Copyright (c) 2015 Troy Stribling. The MIT License (MIT).
//

import UIKit
import XCTest
import CoreBluetooth
import CoreLocation
@testable import BlueCapKit

// MARK: - BCTimedScanneratorTests -
class BCTimedScanneratorTests: XCTestCase {
    
    var centralManager: BCCentralManager!
    let mockPerpheral = CBPeripheralMock()
    let context = ImmediateContext()

    override func setUp() {
        self.centralManager = CentralManagerUT(centralManager: CBCentralManagerMock(state: .PoweredOn))
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }

    // MARK: Scan timeout
    func testStartScanning_WhenPeripeharlDiscovered_CompeletesSuccessfully() {
        let scannerator = BCTimedScannerator(centralManager: self.centralManager)
        let expectation = expectationWithDescription("expectation fulfilled for future")
        let future = scannerator.startScanning(2)
        future.onSuccess(self.context) { peripheral in
            expectation.fulfill()
            XCTAssertEqual(peripheral.identifier, self.mockPerpheral.identifier, "Peripheral identifier timeout")
        }
        future.onFailure(self.context) {error in
            expectation.fulfill()
            XCTFail("onFailure called")
        }
        self.centralManager.didDiscoverPeripheral(self.mockPerpheral, advertisementData:peripheralAdvertisements, RSSI:NSNumber(integer: -45))
        waitForExpectationsWithTimeout(5) { error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func testStartScanning_OnScanTimeout_CompletesWithPeripheralScanTimeout() {
        let scannerator = BCTimedScannerator(centralManager :self.centralManager)
        let expectation = expectationWithDescription("expectation fulfilled for future")
        let future = scannerator.startScanning(1)
        future.onSuccess(self.context) { _ in
            expectation.fulfill()
            XCTFail("onSuccess called")
        }
        future.onFailure {error in
            expectation.fulfill()
            XCTAssertEqual(BCError.centralPeripheralScanTimeout.code, error.code, "onFailure error invalid")
        }
        waitForExpectationsWithTimeout(30) { error in
            XCTAssertNil(error, "\(error)")
        }
    }

}
