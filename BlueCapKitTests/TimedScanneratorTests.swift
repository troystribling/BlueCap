//
//  TimedScanneratorTests.swift
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

class TimedScanneratorTests: XCTestCase {
    
    var centralManager : CentralManager!
    let mockPerpheral = CBPeripheralMock(state:.Connected)

    override func setUp() {
        self.centralManager = CentralManagerUT(centralManager:CBCentralManagerMock(state:.PoweredOn))
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }

    func testScanSuccessful() {
        let scannerator = TimedScannerator(centralManager:self.centralManager)
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
        let scannerator = TimedScannerator(centralManager:self.centralManager)
        let onFailureExpectation = expectationWithDescription("onFailure fulfilled for future")
        let future = scannerator.startScanning(1)
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
