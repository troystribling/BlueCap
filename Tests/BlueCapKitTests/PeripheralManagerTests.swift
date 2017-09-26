//
//  PeripheralManagerTests.swift
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

// MARK: - PeripheralManagerTests -

class PeripheralManagerTests: XCTestCase {

    let peripheralName  = "Test Peripheral"
    let advertisedUUIDs = CBUUID(string: Gnosus.HelloWorldService.Greeting.uuid)
    let immediateContext = ImmediateContext()

    override func setUp() {
        GnosusProfiles.create(profileManager: profileManager)
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }

    // MARK: whenStateChanges

    func testWhenStateChangesOnStateChange_CompletesSuccessfully() {
        let (mock, peripheralManager) = createPeripheralManager(false, state: .poweredOff)
        let stream = peripheralManager.whenStateChanges()
        mock.state = .poweredOn
        peripheralManager.didUpdateState(mock)
        XCTAssertFutureStreamSucceeds(stream, context: TestContext.immediate, validations: [
            { state in
                XCTAssertEqual(state, .poweredOff)
            },
            { state in
                XCTAssertEqual(state, .poweredOn)
            }
        ])
    }


    // MARK: Start advertising

    func testStartAdvertising_WhenNoErrorInAckAndNotAdvertising_CompletesSuccessfully() {
        let (mock, peripheralManager) = createPeripheralManager(false, state: .poweredOn)
        let future = peripheralManager.startAdvertising(self.peripheralName, uuids: [self.advertisedUUIDs])
        peripheralManager.didStartAdvertising(nil)
        XCTAssertFutureSucceeds(future, context: self.immediateContext) { _ in
            XCTAssert(mock.startAdvertisingCalled)
            XCTAssert(peripheralManager.isAdvertising)
            if let advertisedData = mock.advertisementData, let name = advertisedData[CBAdvertisementDataLocalNameKey] as? String, let uuids = advertisedData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID] {
                XCTAssertEqual(name, self.peripheralName)
                XCTAssertEqual(uuids[0], self.advertisedUUIDs)
            } else {
                XCTFail()
            }
        }
    }

    func testStartAdvertising_WhenErrorInAckAndNotAdvertising_CompletesWithAckError() {
        let (mock, peripheralManager) = createPeripheralManager(false, state: .poweredOn)
        let future = peripheralManager.startAdvertising(self.peripheralName, uuids: [self.advertisedUUIDs])
        peripheralManager.didStartAdvertising(TestFailure.error)
        XCTAssertFutureFails(future, context: self.immediateContext) { error in
            XCTAssertEqualErrors(error, TestFailure.error)
            XCTAssert(mock.startAdvertisingCalled)
            if let advertisedData = mock.advertisementData, let name = advertisedData[CBAdvertisementDataLocalNameKey] as? String, let uuids = advertisedData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID] {
                XCTAssertEqual(name, self.peripheralName)
                XCTAssertEqual(uuids[0], self.advertisedUUIDs)
            } else {
                XCTFail()
            }
        }
    }

    func testStartAdvertising_WhenAdvertising_CompletesWithErrorPeripheralManagerIsAdvertising() {
        let (mock, peripheralManager) = createPeripheralManager(true, state: .poweredOn)
        let future = peripheralManager.startAdvertising(self.peripheralName, uuids: [self.advertisedUUIDs])
        XCTAssertFutureFails(future, context: self.immediateContext) { error in
            XCTAssertEqualErrors(error, PeripheralManagerError.isAdvertising)
            XCTAssert(mock.advertisementData == nil)
        }
    }

    // MARK: iBeacon

    func testStartAdvertising_WheniBeaconAndNoErrorInAckAndNotAdvertising_CompletesSuccessfully() {
        let (mock, peripheralManager) = createPeripheralManager(false, state: .poweredOn)
        let future = peripheralManager.startAdvertising(BeaconRegion(proximityUUID: UUID(), identifier: "Beacon Regin"))
        peripheralManager.didStartAdvertising(nil)
        XCTAssertFutureSucceeds(future, context: self.immediateContext) { _ in
            XCTAssert(mock.startAdvertisingCalled)
            XCTAssert(peripheralManager.isAdvertising)
        }
    }

    func testStartAdvertising_WheniBeaconAndErrorInAckAndNotAdvertising_CompletesWithAckError() {
        let (mock, peripheralManager) = createPeripheralManager(false, state: .poweredOn)
        let future = peripheralManager.startAdvertising(BeaconRegion(proximityUUID: UUID(), identifier: "Beacon Regin"))
        peripheralManager.didStartAdvertising(TestFailure.error)
        XCTAssertFutureFails(future, context: self.immediateContext) { error in
            XCTAssertEqualErrors(error, TestFailure.error)
            XCTAssert(mock.startAdvertisingCalled)
        }
    }

    func testStartAdvertising_WheniBeaconAdvertising_CompletesWithErrorPeripheralManagerIsAdvertising() {
        let (mock, peripheralManager) = createPeripheralManager(true, state: .poweredOn)
        let future = peripheralManager.startAdvertising(BeaconRegion(proximityUUID: UUID(), identifier: "Beacon Regin"))
        XCTAssertFutureFails(future, context: self.immediateContext) { error in
            XCTAssertEqualErrors(error, PeripheralManagerError.isAdvertising)
            XCTAssertFalse(mock.startAdvertisingCalled)
        }
    }

    // MARK: Stop advertising

    func testStopAdvertising_WhenAdvertising_CompletesSuccessfully() {
        let (mock, peripheralManager) = createPeripheralManager(true, state: .poweredOn)
        let future = peripheralManager.stopAdvertising()
        XCTAssertFutureSucceeds(future, timeout: 5.0) { _ in
            XCTAssert(mock.stopAdvertisingCalled)
        }
    }

    func testStopAdvertising_WhenNotAdvertising_StopsAdvertising() {
        let (mock, peripheralManager) = createPeripheralManager(false, state: .poweredOn)
        let future = peripheralManager.stopAdvertising()
        XCTAssertFutureSucceeds(future, context: self.immediateContext) { (_) -> Void in
            XCTAssertFalse(mock.stopAdvertisingCalled)
        }
    }

    func testStopAdvertising_WhenAdvertisingAndTimeoutIsExceeded_CompletesWithErrorStopAdvertisingTimeout() {
        let (mock, peripheralManager) = createPeripheralManager(true, state: .poweredOn, stopAdvertiseFail: true)
        let future = peripheralManager.stopAdvertising(timeout: 0.5)
        XCTAssertFutureFails(future, timeout: 20.0) { error in
            XCTAssertEqualErrors(error, PeripheralManagerError.stopAdvertisingTimeout)
            XCTAssertTrue(mock.stopAdvertisingCalled)
        }
    }
    
    // MARK: Add Service

    func testAddService_WhenNoError_CompletesSuccess() {
        let (mock, peripheralManager) = createPeripheralManager(false, state: .poweredOn)
        let service = createPeripheralManagerService()
        let future = peripheralManager.add(service)
        peripheralManager.didAddService(service.cbMutableService, error: nil)
        XCTAssertFutureSucceeds(future, context: self.immediateContext) { _ in
            let peripheralServices = peripheralManager.services
            XCTAssert(mock.addServiceCalled)
            XCTAssertEqual(peripheralServices.count, 1)
            XCTAssertEqual(peripheralServices[0].uuid, service.uuid)
        }
    }

    func testAddService_WhenErrorinCallback_CompletesWithCallbackError() {
        let (mock, peripheralManager) = createPeripheralManager(false, state: .poweredOn)
        let service = createPeripheralManagerService(peripheralManager)
        let future = peripheralManager.add(service)
        peripheralManager.didAddService(service.cbMutableService, error: TestFailure.error)
        XCTAssertFutureFails(future, context: self.immediateContext) { error in
            let peripheralServices = peripheralManager.services
            XCTAssertEqualErrors(error, TestFailure.error)
            XCTAssert(mock.addServiceCalled)
            XCTAssertEqual(peripheralServices.count, 0)
        }
    }

    func testAddService_WithDublicateUUIDs_CompletesSuccess() {
        let (mock, peripheralManager) = createPeripheralManager(false, state: .poweredOn)
        let services = createDuplicatePeripheralManagerServices()
        _ = peripheralManager.add(services[0])
        peripheralManager.didAddService(services[0].cbMutableService, error: nil)
        let future = peripheralManager.add(services[1])
        peripheralManager.didAddService(services[1].cbMutableService, error: nil)
        XCTAssertFutureSucceeds(future, context: self.immediateContext) { _ in
            let peripheralServices = peripheralManager.services
            XCTAssert(mock.addServiceCalled)
            XCTAssertEqual(peripheralServices.count, 2)
        }
    }

    // MARK: Remove Service

    func testRemovedService_WhenServiceIsPresent_RemovesService() {
        let (mock, peripheralManager) = createPeripheralManager(false, state: .poweredOn)
        let service = createPeripheralManagerService(peripheralManager)
        let future = peripheralManager.add(service)
        peripheralManager.didAddService(service.cbMutableService, error: nil)
        XCTAssertFutureSucceeds(future, timeout: 5.0) { _ in
            peripheralManager.remove(service)
            let peripheralServices = peripheralManager.services
            XCTAssert(mock.removeServiceCalled)
            XCTAssertEqual(peripheralServices.count, 0)
            if let removedService = mock.removedService {
                XCTAssertEqual(removedService.uuid, service.uuid)
            } else {
                XCTFail()
            }
        }
    }

    func testRemovedService_WhenNoServiceIsPresent_DoesNothing() {
        let (mock, peripheralManager) = createPeripheralManager(false, state: .poweredOn)
        let service = createPeripheralManagerService(peripheralManager)
        peripheralManager.remove(service)
        XCTAssert(mock.removeServiceCalled, "CBPeripheralManager#removeService not called")
    }

    func testRemovedAllServices_WhenServicesArePresent_RemovesAllServices() {
        let (mock, peripheralManager) = createPeripheralManager(false, state: .poweredOn)
        let service = createPeripheralManagerService(peripheralManager)
        let future = peripheralManager.add(service)
        peripheralManager.didAddService(service.cbMutableService, error: nil)
        XCTAssertFutureSucceeds(future, timeout: 5.0) { _ in
            peripheralManager.removeAllServices()
            let peripheralServices = peripheralManager.services
            XCTAssert(mock.removeAllServicesCalled, "CBPeripheralManager#removeAllServices not called")
            XCTAssertEqual(peripheralServices.count, 0, "peripheralManager service count invalid")
        }
    }

    func testRemovedService_WithDuplicateUUIDs_RemovesService() {
        let (mock, peripheralManager) = createPeripheralManager(false, state: .poweredOn)
        let services = createDuplicatePeripheralManagerServices()
        _ = peripheralManager.add(services[0])
        peripheralManager.didAddService(services[0].cbMutableService, error: nil)
        let future = peripheralManager.add(services[1])
        peripheralManager.didAddService(services[1].cbMutableService, error: nil)
        XCTAssertFutureSucceeds(future, context: self.immediateContext) { _ in
            peripheralManager.remove(services[0])
            XCTAssert(mock.removeServiceCalled)
            let peripheralServices = peripheralManager.services
            XCTAssertEqual(peripheralServices.count, 1)
            XCTAssertEqual(peripheralManager.service(withUUID: services[1].uuid)?.count, 1)
            if let removedService = mock.removedService {
                XCTAssertEqual(removedService.uuid, services[0].uuid)
            } else {
                XCTFail()
            }
        }
    }

    // MARK: State Restoration

    func testWhenStateRestored_WithPreviousValidState_CompletesSuccessfully() {
        let (_, peripheralManager) = createPeripheralManager(false, state: .poweredOn)
        let testServices = [CBMutableServiceMock(), CBMutableServiceMock()]
        for testService in testServices {
            let testCharacteristics = [CBMutableCharacteristicMock(), CBMutableCharacteristicMock()]
            testService.characteristics = testCharacteristics
        }
        let future = peripheralManager.whenStateRestored()
        peripheralManager.willRestoreState(testServices.map { $0 as CBMutableServiceInjectable }, advertisements: peripheralAdvertisements)
        XCTAssertFutureSucceeds(future, context: self.immediateContext) { advertisements in
                let services = peripheralManager.services
                XCTAssertEqual(advertisements.localName!, peripheralAdvertisements[CBAdvertisementDataLocalNameKey]! as! String)
                XCTAssertEqual(advertisements.txPower!, peripheralAdvertisements[CBAdvertisementDataTxPowerLevelKey]! as! NSNumber)
                XCTAssertEqual(services.count, testServices.count)
                XCTAssertEqual(Set(services.map { $0.uuid }), Set(testServices.map { $0.uuid }))
                for testService in testServices {
                    let testCharacteristics = testService.characteristics!
                    let service = peripheralManager.services.filter { $0.uuid == testService.uuid }.first!
                    let characteristics = service.characteristics
                    XCTAssertEqual(characteristics.count, testCharacteristics.count)
                    XCTAssertEqual(Set(characteristics.map { $0.uuid }), Set(testCharacteristics.map { $0.uuid }))
                }
        }
    }

    func testWhenStateRestored_WithPreviousInvalidState_CompletesWithCentralRestoreFailed() {
        let (_, peripheralManager) = createPeripheralManager(false, state: .poweredOn)
        let future = peripheralManager.whenStateRestored()
        peripheralManager.willRestoreState(nil, advertisements: nil)
        XCTAssertFutureFails(future, context: self.immediateContext) { error in
                XCTAssertEqualErrors(error, PeripheralManagerError.restoreFailed)
        }
    }
}
