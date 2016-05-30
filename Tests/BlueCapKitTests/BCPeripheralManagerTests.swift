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
    let immediateContext = ImmediateContext()

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
        let future = peripheralManager.whenPowerOn()
        XCTAssertFutureSucceeds(future, context: self.immediateContext)
    }

    func testWhenPowerOn_WhenInitiallyPoweredOff_CompletesSuccessfully() {
        let (mock, peripheralManager) = createPeripheralManager(false, state: .PoweredOff)
        let future = peripheralManager.whenPowerOn()
        mock.state = .PoweredOn
        peripheralManager.didUpdateState()
        XCTAssertFutureSucceeds(future, context: self.immediateContext)
    }

    // MARK: Power off
    func testWhenPowerOff_WhenInitiallyPoweredOn_CompletesSuccessfully() {
        let (mock, peripheralManager) = createPeripheralManager(false, state: .PoweredOn)
        let future = peripheralManager.whenPowerOff()
        mock.state = .PoweredOff
        peripheralManager.didUpdateState()
        XCTAssertFutureSucceeds(future, context: self.immediateContext)
    }

    func testWhenPowerOff_WhenPoweredOff_CompletesSuccessfully() {
        let (_, peripheralManager) = createPeripheralManager(false, state: .PoweredOff)
        let future = peripheralManager.whenPowerOff()
        XCTAssertFutureSucceeds(future, context: self.immediateContext)
    }

    // MARK: Start advertising
    func testStartAdvertising_WhenNoErrorInAckAndNotAdvertising_CompletesSuccessfully() {
        let (mock, peripheralManager) = createPeripheralManager(false, state: .PoweredOn)
        let future = peripheralManager.startAdvertising(self.peripheralName, uuids:[self.advertisedUUIDs])
        peripheralManager.didStartAdvertising(nil)
        XCTAssertFutureSucceeds(future, context: self.immediateContext) {
            XCTAssert(mock.startAdvertisingCalled, "CBPeripheralManager#startAdvertising not called")
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
    }

    func testStartAdvertising_WhenErrorInAckAndNotAdvertising_CompletesWithAckError() {
        let (mock, peripheralManager) = createPeripheralManager(false, state: .PoweredOn)
        let future = peripheralManager.startAdvertising(self.peripheralName, uuids:[self.advertisedUUIDs])
        peripheralManager.didStartAdvertising(TestFailure.error)
        XCTAssertFutureFails(future, context: self.immediateContext) { error in
            XCTAssertEqual(error.code, TestFailure.error.code, "error code invalid")
            XCTAssert(mock.startAdvertisingCalled, "CBPeripheralManager#startAdvertising not called")
            if let advertisedData = mock.advertisementData,
                name = advertisedData[CBAdvertisementDataLocalNameKey] as? String,
                uuids = advertisedData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID] {
                XCTAssertEqual(name, self.peripheralName, "peripheralName invalid")
                XCTAssertEqual(uuids[0], self.advertisedUUIDs, "advertised UUIDs invalid")
            } else {
                XCTFail("advertisementData not found")
            }
        }
    }

    func testStartAdvertising_WhenAdvertising_CompletesWithErrorPeripheralManagerIsAdvertising() {
        let (mock, peripheralManager) = createPeripheralManager(true, state: .PoweredOn)
        let future = peripheralManager.startAdvertising(self.peripheralName, uuids:[self.advertisedUUIDs])
        XCTAssertFutureFails(future, context: self.immediateContext) { error in
            XCTAssertEqual(error.code, BCPeripheralManagerErrorCode.IsAdvertising.rawValue, "Error code is invalid")
            XCTAssert(mock.advertisementData == nil, "advertisementData found")
        }
    }

    // MARK: iBeacon
    func testStartAdvertising_WheniBeaconAndNoErrorInAckAndNotAdvertising_CompletesSuccessfully() {
        let (mock, peripheralManager) = createPeripheralManager(false, state: .PoweredOn)
        let future = peripheralManager.startAdvertising(FLBeaconRegion(proximityUUID: NSUUID(), identifier: "Beacon Regin"))
        peripheralManager.didStartAdvertising(nil)
        XCTAssertFutureSucceeds(future, context: self.immediateContext) { error in
            XCTAssert(mock.startAdvertisingCalled, "CBPeripheralManager#startAdvertising not called")
            XCTAssert(peripheralManager.isAdvertising, "isAdvertising invalid value")
        }
    }

    func testStartAdvertising_WheniBeaconAndErrorInAckAndNotAdvertising_CompletesWithAckError() {
        let (mock, peripheralManager) = createPeripheralManager(false, state: .PoweredOn)
        let future = peripheralManager.startAdvertising(FLBeaconRegion(proximityUUID: NSUUID(), identifier: "Beacon Regin"))
        peripheralManager.didStartAdvertising(TestFailure.error)
        XCTAssertFutureFails(future, context: self.immediateContext) { error in
            XCTAssertEqual(error.code, TestFailure.error.code, "error code invalid")
            XCTAssert(mock.startAdvertisingCalled, "CBPeripheralManager#startAdvertising not called")
        }
    }

    func testStartAdvertising_WheniBeaconAdvertising_CompletesWithErrorPeripheralManagerIsAdvertising() {
        let (mock, peripheralManager) = createPeripheralManager(true, state: .PoweredOn)
        let future = peripheralManager.startAdvertising(FLBeaconRegion(proximityUUID: NSUUID(), identifier: "Beacon Regin"))
        XCTAssertFutureFails(future, context: self.immediateContext) { error in
            XCTAssertEqual(error.code, BCPeripheralManagerErrorCode.IsAdvertising.rawValue, "Error code is invalid \(error.code)")
            XCTAssertFalse(mock.startAdvertisingCalled, "CBPeripheralManager#startAdvertising not called")
        }
    }

    // MARK: Stop advertising
    func testStopAdvertising_WhenAdvertising_CompletesSuccessfully() {
        let (mock, peripheralManager) = createPeripheralManager(true, state: .PoweredOn)
        let future = peripheralManager.stopAdvertising()
        mock.isAdvertising = false
        XCTAssertFutureSucceeds(future, timeout: 5) {
            XCTAssert(mock.stopAdvertisingCalled, "CBPeripheralManager#stopAdvertisingCalled not called")
        }
    }

    func testStopAdvertising_WhenNotAdvertising_CompletesWithPeripheralManagerIsNotAdvertising() {
        let (mock, peripheralManager) = createPeripheralManager(false, state: .PoweredOn)
        let future = peripheralManager.stopAdvertising()
        XCTAssertFutureFails(future, context: self.immediateContext) { error in
            XCTAssertEqual(error.code, BCPeripheralManagerErrorCode.IsNotAdvertising.rawValue, "Error code is invalid")
            XCTAssertFalse(mock.stopAdvertisingCalled, "CBPeripheralManager#stopAdvertisingCalled called")
        }
    }

    // MARK: Add Service
    func testAddService_WhenNoErrorInAck_CompletesSuccess() {
        let (mock, peripheralManager) = createPeripheralManager(false, state: .PoweredOn)
        let services = createPeripheralManagerServices(peripheralManager)
        let future = peripheralManager.addService(services[0])
        peripheralManager.didAddService(services[0].cbMutableService, error: nil)
        XCTAssertFutureSucceeds(future, context: self.immediateContext) {
            let peripheralServices = peripheralManager.services
            XCTAssert(mock.addServiceCalled, "CBPeripheralManager#addService not called")
            XCTAssertEqual(peripheralServices.count, 1, "peripheralManager service count invalid")
            XCTAssertEqual(peripheralServices[0].UUID, services[0].UUID, "addedService has invalid UUID")
        }
    }

    func testAddService_WhenErrorOnAck_CompletesWithAckError() {
        let (mock, peripheralManager) = createPeripheralManager(false, state: .PoweredOn)
        let services = createPeripheralManagerServices(peripheralManager)
        let future = peripheralManager.addService(services[0])
        peripheralManager.didAddService(services[0].cbMutableService, error: TestFailure.error)
        XCTAssertFutureFails(future, context: self.immediateContext) { error in
            let peripheralServices = peripheralManager.services
            XCTAssertEqual(TestFailure.error.code, error.code, "error code is invalid")
            XCTAssert(mock.addServiceCalled, "CBPeripheralManager#addService not called")
            XCTAssertEqual(peripheralServices.count, 0, "peripheralManager service count invalid")
        }
    }

    func testAddServices_WhenNoErrorInAck_CompletesSuccessfully() {
        let (mock, peripheralManager) = createPeripheralManager(false, state: .PoweredOn)
        let services = createPeripheralManagerServices(peripheralManager)
        let future = peripheralManager.addServices(services)
        XCTAssertFutureSucceeds(future, timeout: 5.0) {
            let peripheralServices = peripheralManager.services.map { $0.UUID }
            XCTAssert(mock.addServiceCalled, "CBPeripheralManager#addService not called")
            XCTAssertEqual(peripheralServices.count, 2, "peripheralManager service count invalid")
            XCTAssert(peripheralServices.contains(services[0].UUID), "addedService has invalid UUID")
            XCTAssert(peripheralServices.contains(services[1].UUID), "addedService has invalid UUID")
        }
    }

    func testAddServices_WhenErrorInAck_CompletesWithAckError() {
        let (mock, peripheralManager) = createPeripheralManager(false, state: .PoweredOn)
        let services = createPeripheralManagerServices(peripheralManager)
        let future = peripheralManager.addServices(services)
        peripheralManager.error = TestFailure.error
        XCTAssertFutureFails(future, timeout: 5.0) { error in
            let peripheralServices = peripheralManager.services
            XCTAssertEqual(TestFailure.error.code, error.code, "error code is invalid")
            XCTAssert(mock.addServiceCalled, "CBPeripheralManager#addService not called")
            XCTAssertEqual(peripheralServices.count, 0, "peripheralManager service count invalid")
        }
    }

    // MARK: Remove Service
    func testRemovedService_WhenServiceIsPresent_RemovesService() {
        let (mock, peripheralManager) = createPeripheralManager(false, state: .PoweredOn)
        let services = createPeripheralManagerServices(peripheralManager)
        let future = peripheralManager.addServices(services)
        XCTAssertFutureSucceeds(future, timeout: 5.0) {
            peripheralManager.removeService(services[0])
            let peripheralServices = peripheralManager.services
            XCTAssert(mock.removeServiceCalled, "CBPeripheralManager#removeService not called")
            XCTAssertEqual(peripheralServices.count, 1, "peripheralManager service count invalid")
            XCTAssertEqual(peripheralServices[0].UUID, services[1].UUID, "addedService has invalid UUID")
            if let removedService = mock.removedService {
                XCTAssertEqual(removedService.UUID, services[0].UUID, "removeService has invalid UUID")
            } else {
                XCTFail("removedService not found")
            }
        }
    }

    func testRemovedService_WhenNoServiceIsPresent_DoesNothing() {
        let (mock, peripheralManager) = createPeripheralManager(false, state: .PoweredOn)
        let services = createPeripheralManagerServices(peripheralManager)
        peripheralManager.removeService(services[0])
        XCTAssert(mock.removeServiceCalled, "CBPeripheralManager#removeService not called")
    }

    func testRemovedAllServices_WhenServicesArePresent_RemovesAllServices() {
        let (mock, peripheralManager) = createPeripheralManager(false, state: .PoweredOn)
        let services = createPeripheralManagerServices(peripheralManager)
        let future = peripheralManager.addServices(services)
        XCTAssertFutureSucceeds(future, timeout: 5.0) {
            peripheralManager.removeAllServices()
            let peripheralServices = peripheralManager.services
            XCTAssert(mock.removeAllServicesCalled, "CBPeripheralManager#removeAllServices not called")
            XCTAssertEqual(peripheralServices.count, 0, "peripheralManager service count invalid")
        }
    }

    // MARK: State Restoration
    func testWhenStateRestored_WithPreviousValidState_CompletesSuccessfully() {
        let (_, peripheralManager) = createPeripheralManager(false, state: .PoweredOn)
        let testServices = [CBMutableServiceMock(), CBMutableServiceMock()]
        for testService in testServices {
            let testCharacteristics = [CBMutableCharacteristicMock(), CBMutableCharacteristicMock()]
            testService.characteristics = testCharacteristics
        }
        let future = peripheralManager.whenStateRestored()
        peripheralManager.willRestoreState(testServices.map { $0 as CBMutableServiceInjectable }, advertisements: peripheralAdvertisements)
        XCTAssertFutureStreamSucceeds(future, context: self.immediateContext, validations: [
            { (services, advertisements) in
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
        ])
    }

    func testWhenStateRestored_WithPreviousInvalidState_CompletesWithCentralRestoreFailed() {
        let (_, peripheralManager) = createPeripheralManager(false, state: .PoweredOn)
        let future = peripheralManager.whenStateRestored()
        peripheralManager.willRestoreState(nil, advertisements: nil)
        XCTAssertFutureStreamFails(future, context: self.immediateContext, validations: [
            { error in
                XCTAssertEqual(error.code, BCError.peripheralManagerRestoreFailed.code, "Invalide error code")
            }
        ])
    }
}
