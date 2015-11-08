//
//  CentralManagerTests.swift
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

class CentralManagerTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }

    func testPowerOnWhenPoweredOn() {
        let mock = CBCentralManagerMock(state:.PoweredOn)
        let centralManager = CentralManager(centralManager:mock)
        let expectation = expectationWithDescription("onSuccess fulfilled for future")
        let future = centralManager.powerOn()
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
        let mock = CBCentralManagerMock(state:.PoweredOn)
        let centralManager = CentralManager(centralManager:mock)
        let expectation = expectationWithDescription("onSuccess fulfilled for future")
        let future = centralManager.powerOn()
        future.onSuccess {
            expectation.fulfill()
        }
        future.onFailure{error in
            XCTAssert(false, "onFailure called")
        }
        mock.state = .PoweredOn
        centralManager.didUpdateState()
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testPowerOffWhenPoweredOn() {
        let mock = CBCentralManagerMock(state:.PoweredOn)
        let centralManager = CentralManager(centralManager:mock)
        let expectation = expectationWithDescription("onSuccess fulfilled for future")
        let future = centralManager.powerOff()
        future.onSuccess {
            expectation.fulfill()
        }
        future.onFailure{error in
            XCTAssert(false, "onFailure called")
        }
        mock.state = .PoweredOff
        centralManager.didUpdateState()
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testPowerOffWhenPoweredOff() {
        let mock = CBCentralManagerMock(state:.PoweredOff)
        let centralManager = CentralManager(centralManager:mock)
        let expectation = expectationWithDescription("onSuccess fulfilled for future")
        let future = centralManager.powerOff()
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

    func testPeripheralDiscoverWhenPoweredOn() {
        let centralMock = CBCentralManagerMock(state:.PoweredOn)
        let centralManager = CentralManager(centralManager:centralMock)
        let expectation = expectationWithDescription("onSuccess fulfilled for future")
        let future = centralManager.startScanning()
        let peripheralMock = CBPeripheralMock()
        future.onSuccess {_ in
            expectation.fulfill()
            XCTAssert(centralMock.scanForPeripheralsWithServicesCalled, "CBCentralManager#scanForPeripheralsWithServices not called")
            if let peripheral = centralManager.peripherals.first where centralManager.peripherals.count == 1 {
                XCTAssert(peripheralMock.setDelegateCalled, "Peripheral delegate not set")
                XCTAssert(peripheral.name == peripheralMock.name, "Peripheral name is invalid")
                XCTAssert(peripheral.identifier == peripheralMock.identifier, "Peripheral identifier is invalid")
            } else {
                XCTAssert(false, "Discovered peripheral missing")
            }
        }
        future.onFailure{error in
            XCTAssert(false, "onFailure called")
        }
        centralManager.didDiscoverPeripheral(peripheralMock, advertisementData:peripheralAdvertisements, RSSI:NSNumber(integer: -45))
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func testPeripheralDiscoveredWhenPoweredOff() {
        let centralMock = CBCentralManagerMock(state:.PoweredOff)
        let centralManager = CentralManager(centralManager:centralMock)
        let expectation = expectationWithDescription("onFailure fulfilled for future")
        let future = centralManager.startScanning()
        future.onSuccess {_ in
            XCTAssert(false, "onSuccess called")
        }
        future.onFailure{error in
            expectation.fulfill()
            XCTAssertFalse(centralMock.scanForPeripheralsWithServicesCalled, "CBCentralManager#scanForPeripheralsWithServices is called")
            XCTAssert(error.code == BCError.centralIsPoweredOff.code, "Error code invalid")
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
}
