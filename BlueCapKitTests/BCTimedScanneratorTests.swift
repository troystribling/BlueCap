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
import BlueCapKit

// MARK: - BCTimedScanneratorTests -
class BCTimedScanneratorTests: XCTestCase {
    
    var centralManager: BCCentralManager!
    let mockPerpheral = CBPeripheralMock(state:.Connected)

    override func setUp() {
        self.centralManager = CentralManagerUT(centralManager: CBCentralManagerMock(state: .PoweredOn))
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }

    // MARK: Scan timeout
    func testScanSuccessful() {
        let scannerator = BCTimedScannerator(centralManager: self.centralManager)
        let onSuccessExpectation = expectationWithDescription("onSuccess fulfilled for future")
        let future = scannerator.startScanning(2)
        future.onSuccess {_ in
            onSuccessExpectation.fulfill()
        }
        future.onFailure {error in
            XCTAssert(false, "onFailure called")
        }
        self.centralManager.didDiscoverPeripheral(self.mockPerpheral, advertisementData:peripheralAdvertisements, RSSI:NSNumber(integer: -45))
        waitForExpectationsWithTimeout(5) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func testScanTimeout() {
        let scannerator = BCTimedScannerator(centralManager :self.centralManager)
        let onFailureExpectation = expectationWithDescription("onFailure fulfilled for future")
        let future = scannerator.startScanning(1)
        future.onSuccess {_ in
            XCTAssert(false, "onSuccess called")
        }
        future.onFailure {error in
            onFailureExpectation.fulfill()
            XCTAssertEqual(BCPeripheralErrorCode.DiscoveryTimeout.rawValue, error.code, "onFailure error invalid")
        }
        waitForExpectationsWithTimeout(30) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

}
