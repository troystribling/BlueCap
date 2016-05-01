//
//  BCPeripheralManagerTests.swift
//  BlueCapKit
//
//  Created by Troy Stribling on 3/25/15.
//  Copyright (c) 2015 Troy Stribling. The MIT License (MIT).
//

import UIKit
import XCTest
import CoreBluetooth
import CoreLocation
@testable import BlueCapKit

// MARK: - BCPeripheralManagerTests -
class BCPeripheralManagerTests: XCTestCase {

    let peripheralName  = "Test Peripheral"
    let advertisedUUIDs = CBUUID(string: Gnosus.HelloWorldService.Greeting.UUID)
  
    override func setUp() {
        GnosusProfiles.create()
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }

    // MARK: Power on
    func testWhenPowerOn_WhenPoweredOn_CompletesSuccessfully() {
        let (_, peripheralManager) = createPeripheralManager(false, state: .PoweredOn)
        let expectation = expectationWithDescription("onSuccess fulfilled for future")
        let future = peripheralManager.whenPowerOn()
        future.onSuccess {
            expectation.fulfill()
        }
        future.onFailure {error in
            expectation.fulfill()
            XCTFail("onFailure called")
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testWhenPowerOn_WhenInitiallyPoweredOff_CompletesSuccessfully() {
        let (mock, peripheralManager) = createPeripheralManager(false, state: .PoweredOff)
        let expectation = expectationWithDescription("onSuccess fulfilled for future")
        let future = peripheralManager.whenPowerOn()
        future.onSuccess {
            expectation.fulfill()
        }
        future.onFailure {error in
            expectation.fulfill()
            XCTFail("onFailure called")
        }
        mock.state = .PoweredOn
        peripheralManager.didUpdateState()
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    // MARK: Power off
    func testWhenPowerOff_WhenInitiallyPoweredOn_CompletesSuccessfully() {
        let (mock, peripheralManager) = createPeripheralManager(false, state: .PoweredOn)
        let expectation = expectationWithDescription("onSuccess fulfilled for future")
        let future = peripheralManager.whenPowerOff()
        future.onSuccess {
            expectation.fulfill()
        }
        future.onFailure {error in
            expectation.fulfill()
            XCTFail("onFailure called")
        }
        mock.state = .PoweredOff
        peripheralManager.didUpdateState()
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testWhenPowerOff_WhenPoweredOff_CompletesSuccessfully() {
        let (_, peripheralManager) = createPeripheralManager(false, state: .PoweredOff)
        let expectation = expectationWithDescription("onSuccess fulfilled for future")
        let future = peripheralManager.whenPowerOff()
        future.onSuccess {
            expectation.fulfill()
        }
        future.onFailure {error in
            expectation.fulfill()
            XCTFail("onFailure called")
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    // MARK: Start advertising
    func testStartAdvertising_WhenNoErrorInAckAndNotAdvertising_CompletesSuccessfully() {
        let (mock, peripheralManager) = createPeripheralManager(false, state: .PoweredOn)
        let expectation = expectationWithDescription("onSuccess fulfilled for future")
        let future = peripheralManager.startAdvertising(self.peripheralName, uuids:[self.advertisedUUIDs])
        future.onSuccess {
            expectation.fulfill()
            XCTAssert(mock.startAdvertisingCalled, "startAdvertising not called")
            XCTAssert(peripheralManager.isAdvertising, "isAdvertising invalid value")
            if let advertisedData = mock.advertisementData,
                   name = advertisedData[CBAdvertisementDataLocalNameKey] as? String,
                   uuids = advertisedData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID] {
                XCTAssertEqual(name, self.peripheralName, "peripheralName invalid")
                XCTAssertEqual(uuids[0], self.advertisedUUIDs, "advertised UUIDs invalid")
            } else {
                XCTFail("advertisementData not found")
            }
        }
        future.onFailure {error in
            expectation.fulfill()
            XCTFail("onFailure called")
        }
        peripheralManager.didStartAdvertising(nil)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testStartAdvertising_WhenErrorInAckAndNotAdvertising_CompletesWithAckError() {
        let (mock, peripheralManager) = createPeripheralManager(false, state: .PoweredOn)
        let expectation = expectationWithDescription("onFailure fulfilled for future")
        let future = peripheralManager.startAdvertising(self.peripheralName, uuids:[self.advertisedUUIDs])
        future.onSuccess {
            expectation.fulfill()
            XCTFail("onSuccess called")
        }
        future.onFailure {error in
            expectation.fulfill()
            XCTAssertEqual(error.code, TestFailure.error.code, "error code invalid")
            XCTAssert(mock.startAdvertisingCalled, "startAdvertising not called")
            if let advertisedData = mock.advertisementData,
                name = advertisedData[CBAdvertisementDataLocalNameKey] as? String,
                uuids = advertisedData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID] {
                    XCTAssertEqual(name, self.peripheralName, "peripheralName invalid")
                    XCTAssertEqual(uuids[0], self.advertisedUUIDs, "advertised UUIDs invalid")
            } else {
                XCTFail("advertisementData not found")
            }
        }
        peripheralManager.didStartAdvertising(TestFailure.error)
        waitForExpectationsWithTimeout(2) { error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testStartAdvertising_WhenAdvertising_CompletesWithErrorPeripheralManagerIsAdvertising() {
        let (mock, peripheralManager) = createPeripheralManager(true, state: .PoweredOn)
        let expectation = expectationWithDescription("onFailure fulfilled for future")
        let future = peripheralManager.startAdvertising(self.peripheralName, uuids:[self.advertisedUUIDs])
        future.onSuccess {
            expectation.fulfill()
            XCTFail("onSuccess called")
        }
        future.onFailure { error in
            expectation.fulfill()
            XCTAssertEqual(error.code, BCPeripheralManagerErrorCode.IsAdvertising.rawValue, "Error code is invalid")
            XCTAssert(mock.advertisementData == nil, "advertisementData found")
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    // MARK: iBeacon
    func testStartAdvertising_WheniBeaconAndNoErrorInAckAndNotAdvertising_CompletesSuccessfully() {
        let (mock, peripheralManager) = createPeripheralManager(false, state: .PoweredOn)
        let expectation = expectationWithDescription("onSuccess fulfilled for future")
        let future = peripheralManager.startAdvertising(FLBeaconRegion(proximityUUID: NSUUID(), identifier: "Beacon Regin"))
        future.onSuccess {
            expectation.fulfill()
            XCTAssert(mock.startAdvertisingCalled, "startAdvertising not called")
            XCTAssert(peripheralManager.isAdvertising, "isAdvertising invalid value")
        }
        future.onFailure { error in
            expectation.fulfill()
            XCTFail("onFailure called")
        }
        peripheralManager.didStartAdvertising(nil)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testStartAdvertising_WheniBeaconAndErrorInAckAndNotAdvertising_CompletesWithAckError() {
        let (mock, peripheralManager) = createPeripheralManager(false, state: .PoweredOn)
        let expectation = expectationWithDescription("onFailure fulfilled for future")
        let future = peripheralManager.startAdvertising(FLBeaconRegion(proximityUUID: NSUUID(), identifier: "Beacon Regin"))
        future.onSuccess {
            expectation.fulfill()
            XCTFail("onSuccess called")
        }
        future.onFailure { error in
            expectation.fulfill()
            XCTAssertEqual(error.code, TestFailure.error.code, "error code invalid")
            XCTAssert(mock.startAdvertisingCalled, "startAdvertising not called")
        }
        peripheralManager.didStartAdvertising(TestFailure.error)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testStartAdvertising_WheniBeaconAdvertising_CompletesWithErrorPeripheralManagerIsAdvertising() {
        let (mock, peripheralManager) = createPeripheralManager(true, state: .PoweredOn)
        let expectation = expectationWithDescription("onFailure fulfilled for future")
        let future = peripheralManager.startAdvertising(FLBeaconRegion(proximityUUID: NSUUID(), identifier: "Beacon Regin"))
        future.onSuccess {
            expectation.fulfill()
            XCTFail("onSuccess called")
        }
        future.onFailure {error in
            expectation.fulfill()
            XCTAssertEqual(error.code, BCPeripheralManagerErrorCode.IsAdvertising.rawValue, "Error code is invalid \(error.code)")
            XCTAssertFalse(mock.startAdvertisingCalled, "startAdvertising not called")
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    // MARK: Stop advertising
    func testStopAdvertising_WhenAdvertising_CompletesSuccessfully() {
        let (mock, peripheralManager) = createPeripheralManager(true, state: .PoweredOn)
        let expectation = expectationWithDescription("onSuccess fulfilled for future")
        let future = peripheralManager.stopAdvertising()
        future.onSuccess {
            expectation.fulfill()
            XCTAssert(mock.stopAdvertisingCalled, "stopAdvertisingCalled not called")
        }
        future.onFailure {error in
            expectation.fulfill()
            XCTFail("onFailure called")
        }
        mock.isAdvertising = false
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testStopAdvertising_WhenNotAdvertising_CompletesWithPeripheralManagerIsNotAdvertising() {
        let (mock, peripheralManager) = createPeripheralManager(false, state: .PoweredOn)
        let expectation = expectationWithDescription("onFailure fulfilled for future")
        let future = peripheralManager.stopAdvertising()
        future.onSuccess {
            expectation.fulfill()
            XCTFail("onSuccess called")
        }
        future.onFailure {error in
            XCTAssertEqual(error.code, BCPeripheralManagerErrorCode.IsNotAdvertising.rawValue, "Error code is invalid")
            XCTAssertFalse(mock.stopAdvertisingCalled, "stopAdvertisingCalled called")
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    // MARK: Add Service
    func testAddService_WhenNoErrorInAck_CompletesSuccess() {
        let (mock, peripheralManager) = createPeripheralManager(false, state: .PoweredOn)
        let services = createPeripheralManagerServices(peripheralManager)
        let expectation = expectationWithDescription("onSuccess fulfilled for future")
        let future = peripheralManager.addService(services[0])
        future.onSuccess {
            expectation.fulfill()
            let peripheralServices = peripheralManager.services
            XCTAssert(mock.addServiceCalled, "addService not called")
            XCTAssertEqual(peripheralServices.count, 1, "peripheralManager service count invalid")
            XCTAssertEqual(peripheralServices[0].UUID, services[0].UUID, "addedService has invalid UUID")
            if let addedService = mock.addedService {
                XCTAssertEqual(services[0].UUID, addedService.UUID, "addedService UUID invalid")
            } else {
                XCTFail("addService not found")
            }
        }
        future.onFailure {error in
            expectation.fulfill()
            XCTFail("onFailure called")
        }
        peripheralManager.didAddService(services[0].cbMutableService, error: nil)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testAddService_WhenErrorOnAck_CompletesWithAckError() {
        let (mock, peripheralManager) = createPeripheralManager(false, state: .PoweredOn)
        let services = createPeripheralManagerServices(peripheralManager)
        let expectation = expectationWithDescription("onSuccess fulfilled for future")
        let future = peripheralManager.addService(services[0])
        future.onSuccess {
            expectation.fulfill()
            XCTFail("onSuccess called")
        }
        future.onFailure {error in
            expectation.fulfill()
            let peripheralServices = peripheralManager.services
            XCTAssertEqual(TestFailure.error.code, error.code, "error code is invalid")
            XCTAssert(mock.addServiceCalled, "addService not called")
            XCTAssertEqual(peripheralServices.count, 0, "peripheralManager service count invalid")
        }
        peripheralManager.didAddService(services[0].cbMutableService, error: TestFailure.error)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testAddServices_WhenNoErrorInAck_CompletesSuccessfully() {
        let (mock, peripheralManager) = createPeripheralManager(false, state: .PoweredOn)
        let services = createPeripheralManagerServices(peripheralManager)
        let expectation = expectationWithDescription("onSuccess fulfilled for future")
        let future = peripheralManager.addServices(services)
        future.onSuccess {
            expectation.fulfill()
            let peripheralServices = peripheralManager.services.map { $0.UUID }
            XCTAssert(mock.addServiceCalled, "addService not called")
            XCTAssertEqual(peripheralServices.count, 2, "peripheralManager service count invalid")
            XCTAssert(peripheralServices.contains(services[0].UUID), "addedService has invalid UUID")
            XCTAssert(peripheralServices.contains(services[1].UUID), "addedService has invalid UUID")
        }
        future.onFailure {error in
            expectation.fulfill()
            XCTFail("onFailure called")
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testAddServices_WhenErrorInAck_CompletesWithAckError() {
        let (mock, peripheralManager) = createPeripheralManager(false, state: .PoweredOn)
        let services = createPeripheralManagerServices(peripheralManager)
        let expectation = expectationWithDescription("onSuccess fulfilled for future")
        let future = peripheralManager.addServices(services)
        peripheralManager.error = TestFailure.error
        future.onSuccess {
            expectation.fulfill()
            XCTFail("onSuccess called")
        }
        future.onFailure {error in
            expectation.fulfill()
            let peripheralServices = peripheralManager.services
            XCTAssertEqual(TestFailure.error.code, error.code, "error code is invalid")
            XCTAssert(mock.addServiceCalled, "addService not called")
            XCTAssertEqual(peripheralServices.count, 0, "peripheralManager service count invalid")
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    // MARK: Remove Service
    func testRemovedService_WhenServiceIsPresent_RemovesService() {
        let (mock, peripheralManager) = createPeripheralManager(false, state: .PoweredOn)
        let services = createPeripheralManagerServices(peripheralManager)
        let expectation = expectationWithDescription("onSuccess fulfilled for future")
        let addServicesFuture = peripheralManager.addServices(services)
        addServicesFuture.onSuccess {
            expectation.fulfill()
            peripheralManager.removeService(services[0])
            let peripheralServices = peripheralManager.services
            XCTAssert(mock.removeServiceCalled, "removeService not called")
            XCTAssertEqual(peripheralServices.count, 1, "peripheralManager service count invalid")
            XCTAssertEqual(peripheralServices[0].UUID, services[1].UUID, "addedService has invalid UUID")
            if let removedService = mock.removedService {
                XCTAssertEqual(removedService.UUID, services[0].UUID, "removeService has invalid UUID")
            } else {
                XCTFail("removedService not found")
            }
        }
        addServicesFuture.onFailure {error in
            expectation.fulfill()
            XCTFail("onFailure called")
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testRemovedService_WhenSNoerviceIsPresent_DoesNothing() {
        let (mock, peripheralManager) = createPeripheralManager(false, state: .PoweredOn)
        let services = createPeripheralManagerServices(peripheralManager)
        peripheralManager.removeService(services[0])
        XCTAssert(mock.removeServiceCalled, "removeService not called")
    }

    func testRemovedAllServices_WhenServicesArePresent_RemovesAllServices() {
        let (mock, peripheralManager) = createPeripheralManager(false, state: .PoweredOn)
        let services = createPeripheralManagerServices(peripheralManager)
        let expectation = expectationWithDescription("onSuccess fulfilled for future")
        let addServicesFuture = peripheralManager.addServices(services)
        addServicesFuture.onSuccess {
            expectation.fulfill()
            peripheralManager.removeAllServices()
            let peripheralServices = peripheralManager.services
            XCTAssert(mock.removeAllServicesCalled, "removeAllServices not called")
            XCTAssertEqual(peripheralServices.count, 0, "peripheralManager service count invalid")
        }
        addServicesFuture.onFailure {error in
            expectation.fulfill()
            XCTFail("onFailure called")
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    // MARK: State Restoration
    func testWhenStateRestored_WithPreviousValidState_CompletesSuccessfully() {
        let (_, peripheralManager) = createPeripheralManager(false, state: .PoweredOn)
        let expectation = expectationWithDescription("onFailure fulfilled for future")
        let testServices = [CBMutableServiceMock(), CBMutableServiceMock()]
        for testService in testServices {
            let testCharacteristics = [CBMutableCharacteristicMock(), CBMutableCharacteristicMock()]
            testService.characteristics = testCharacteristics
        }
        let future = peripheralManager.whenStateRestored()
        future.onSuccess { (services, advertisements) in
            expectation.fulfill()
            XCTAssertEqual(advertisements.localName, peripheralAdvertisements[CBAdvertisementDataLocalNameKey], "Restored advertisement invalid")
            XCTAssertEqual(advertisements.txPower, peripheralAdvertisements[CBAdvertisementDataTxPowerLevelKey], "Restored advertisement invalid")
            XCTAssertEqual(services.count, testServices.count, "Restored service count invalid")
            XCTAssertEqual(Set(services.map { $0.UUID }), Set(testServices.map { $0.UUID }), "Restored services identifier invalid")
            for testService in testServices {
                let testCharacteristics = testService.characteristics!
                let service = peripheralManager.configuredServices[testService.UUID]
                let characteristics = service!.characteristics
                XCTAssertEqual(characteristics.count, testCharacteristics.count, "Restored characteristics count invalid")
                XCTAssertEqual(Set(characteristics.map { $0.UUID }), Set(testCharacteristics.map { $0.UUID }), "Restored characteristics identifier invalid")
            }

        }
        future.onFailure { error in
            expectation.fulfill()
            XCTFail("onFailure called")
        }
        peripheralManager.willRestoreState(testServices.map { $0 as CBMutableServiceInjectable }, advertisements: peripheralAdvertisements)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testWhenStateRestored_WithPreviousInvalidState_CompletesWithCentralRestoreFailed() {
        let (_, peripheralManager) = createPeripheralManager(false, state: .PoweredOn)
        let expectation = expectationWithDescription("onFailure fulfilled for future")
        let future = peripheralManager.whenStateRestored()
        future.onSuccess { (services, advertisements) in
            expectation.fulfill()
            XCTFail("onSuccess called")
        }
        future.onFailure { error in
            expectation.fulfill()
        }
        peripheralManager.willRestoreState(nil, advertisements: nil)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
}
