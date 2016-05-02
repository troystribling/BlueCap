//
//  BCCentralManagerTests.swift
//  BlueCapKit
//
//  Created by Troy Stribling on 1/7/15.
//  Copyright (c) 2015 Troy Stribling. The MIT License (MIT).
//

import UIKit
import XCTest
import CoreBluetooth
@testable import BlueCapKit

// MARK - BCCentralManagerTests -
class BCCentralManagerTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }

    // MARK: Power on
    func testWhenPowerOn_WhenPoweredOn_CompletesSuccessfully() {
        let mock = CBCentralManagerMock(state: .PoweredOn)
        let centralManager = BCCentralManager(centralManager: mock)
        let expectation = expectationWithDescription("expectation fulfilled for future")
        let future = centralManager.whenPowerOn()
        future.onSuccess {
            expectation.fulfill()
        }
        future.onFailure {error in
            XCTFail("onFailure called")
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testWhenPowerOn_WhenPoweredOff_CompletesSuccessfully() {
        let mock = CBCentralManagerMock(state: .PoweredOn)
        let centralManager = BCCentralManager(centralManager: mock)
        let expectation = expectationWithDescription("expectation fulfilled for future")
        let future = centralManager.whenPowerOn()
        future.onSuccess {
            expectation.fulfill()
        }
        future.onFailure {error in
            XCTFail("onFailure called")
            expectation.fulfill()
        }
        mock.state = .PoweredOn
        centralManager.didUpdateState()
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    // MARK: Power off
    func testWhenPowerOff_WhenPoweredOn_CompletesSuccessfully() {
        let mock = CBCentralManagerMock(state: .PoweredOn)
        let centralManager = BCCentralManager(centralManager: mock)
        let expectation = expectationWithDescription("expectation fulfilled for future")
        let future = centralManager.whenPowerOff()
        future.onSuccess {
            expectation.fulfill()
        }
        future.onFailure {error in
            XCTFail("onFailure called")
            expectation.fulfill()
        }
        mock.state = .PoweredOff
        centralManager.didUpdateState()
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testWhenPowerOff_WhenPoweredOff_CompletesSuccessfully() {
        let mock = CBCentralManagerMock(state: .PoweredOff)
        let centralManager = BCCentralManager(centralManager: mock)
        let expectation = expectationWithDescription("expectation fulfilled for future")
        let future = centralManager.whenPowerOff()
        future.onSuccess {
            expectation.fulfill()
        }
        future.onFailure {error in
            XCTFail("onFailure called")
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    // MARK: Peripheral discovery
    func testStartScanning_WhenPoweredOnAndPeripheralDiscovered_CompletesSuccessfully() {
        let centralMock = CBCentralManagerMock(state: .PoweredOn)
        let centralManager = BCCentralManager(centralManager: centralMock)
        let expectation = expectationWithDescription("expectation fulfilled for future")
        let future = centralManager.startScanning()
        let peripheralMock = CBPeripheralMock()
        future.onSuccess {_ in
            expectation.fulfill()
            XCTAssert(centralMock.scanForPeripheralsWithServicesCalled, "CBCentralManager#scanForPeripheralsWithServices not called")
            if let peripheral = centralManager.peripherals.first where centralManager.peripherals.count == 1 {
                XCTAssert(peripheralMock.setDelegateCalled, "Peripheral delegate not set")
                XCTAssertEqual(peripheral.name, peripheralMock.name, "Peripheral name is invalid")
                XCTAssertEqual(peripheral.identifier, peripheralMock.identifier, "Peripheral identifier is invalid")
            } else {
                XCTFail("Discovered peripheral missing")
            }
        }
        future.onFailure {error in
            XCTFail("onFailure called")
            expectation.fulfill()
        }
        centralManager.didDiscoverPeripheral(peripheralMock, advertisementData: peripheralAdvertisements, RSSI: NSNumber(integer: -45))
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func testStartScanning_WhenPoweredOff_CompletesWithError() {
        let centralMock = CBCentralManagerMock(state: .PoweredOff)
        let centralManager = BCCentralManager(centralManager: centralMock)
        let expectation = expectationWithDescription("expectation fulfilled for future")
        let future = centralManager.startScanning()
        future.onSuccess {_ in
            XCTFail("onSuccess called")
            expectation.fulfill()
        }
        future.onFailure {error in
            expectation.fulfill()
            XCTAssertFalse(centralMock.scanForPeripheralsWithServicesCalled, "CBCentralManager#scanForPeripheralsWithServices is called")
            XCTAssert(error.code == BCError.centralIsPoweredOff.code, "Error code invalid")
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    // MARK: State Restoration
    func testWhenStateRestored_WithPreviousValidState_CompletesSuccessfully() {
        let mock = CBCentralManagerMock()
        let centralManager = BCCentralManager(centralManager: mock)
        let expectation = expectationWithDescription("expectation fulfilled for future")
        let testPeripherals = [CBPeripheralMock(state: .Connected, identifier: NSUUID()), CBPeripheralMock(state: .Connected, identifier: NSUUID())]
        for testPeripheral in testPeripherals {
            let testServices = [CBServiceMock(), CBServiceMock()]
            for testService in testServices {
                let testCharacteristics = [CBCharacteristicMock(), CBCharacteristicMock()]
                testService.characteristics = testCharacteristics
            }
            testPeripheral.services = testServices
        }
        let testScannedServices = [CBUUID(string: NSUUID().UUIDString), CBUUID(string: NSUUID().UUIDString)]
        let testOptions: [String: AnyObject] = [CBCentralManagerOptionShowPowerAlertKey: NSNumber(bool: true),
                                                CBCentralManagerOptionRestoreIdentifierKey: "us.gnos.bluecap.test"]
        let future = centralManager.whenStateRestored()
        future.onSuccess { (peripherals, scannedServices, options) in
            expectation.fulfill()
            XCTAssertEqual(peripherals.count, testPeripherals.count, "Restored peripherals count invalid")
            XCTAssertEqual(scannedServices, testScannedServices, "Scanned services invalid")
            XCTAssertEqual(options[CBCentralManagerOptionShowPowerAlertKey]! as? NSNumber, testOptions[CBCentralManagerOptionShowPowerAlertKey]! as? NSNumber, "Restored option invalid")
            XCTAssertEqual(options[CBCentralManagerOptionRestoreIdentifierKey]! as? NSString, testOptions[CBCentralManagerOptionRestoreIdentifierKey]! as? NSString, "Restored option invalid")
            XCTAssertEqual(Set(peripherals.map { $0.identifier }), Set(testPeripherals.map { $0.identifier }), "Restored peripherals identifier invalid")
            for testPeripheral in testPeripherals {
                let peripheral = centralManager.discoveredPeripherals[testPeripheral.identifier]
                XCTAssertNotNil(peripheral, "Restored peripheral not found")
                let services = peripheral!.services
                let testServices = testPeripheral.services!
                XCTAssertEqual(services.count, testServices.count, "Restored services count invalid")
                XCTAssertEqual(Set(services.map { $0.UUID }), Set(testServices.map { $0.UUID }), "Restored services identifier invalid")
                for testService in testServices {
                    let testCharacteristics = testService.characteristics!
                    let service = peripheral!.discoveredServices[testService.UUID]
                    let characteristics = service!.characteristics
                    XCTAssertEqual(characteristics.count, testCharacteristics.count, "Restored characteristics count invalid")
                    XCTAssertEqual(Set(characteristics.map { $0.UUID }), Set(testCharacteristics.map { $0.UUID }), "Restored characteristics identifier invalid")
                }
            }
        }
        future.onFailure { error in
            XCTFail("onFailure called")
            expectation.fulfill()
        }
        centralManager.willRestoreState(testPeripherals.map { $0 as CBPeripheralInjectable },
                                        scannedServices: testScannedServices, options: testOptions)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testWhenStateRestored_WithPreviousInvalidState_CompletesWithCentralRestoreFailed() {
        let mock = CBCentralManagerMock()
        let centralManager = BCCentralManager(centralManager: mock)
        let expectation = expectationWithDescription("expectation fulfilled for future")
        let future = centralManager.whenStateRestored()
        future.onSuccess { (peripherals, scannedServices, options) in
            XCTFail("onFailure called")
            expectation.fulfill()
        }
        future.onFailure { error in
            expectation.fulfill()
            XCTAssert(error.code == BCError.centralRestoreFailed.code, "Error code invalid")
        }
        centralManager.willRestoreState(nil, scannedServices: nil, options: nil)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
}
