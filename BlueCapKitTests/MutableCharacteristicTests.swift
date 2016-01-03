//
//  MutableCharacteristicTests.swift
//  BlueCapKit
//
//  Created by Troy Stribling on 3/24/15.
//  Copyright (c) 2015 Troy Stribling. The MIT License (MIT).
//

import UIKit
import XCTest
import CoreBluetooth
import CoreLocation
import BlueCapKit

class MutableCharacteristicTests: XCTestCase {
    
    override func setUp() {
        GnosusProfiles.create()
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }

    func addCharacteristics(onSuccess: (mock: CBPeripheralManagerMock, peripheralManager: PeripheralManager, service: MutableService) -> Void) {
        let (mock, peripheralManager) = createPeripheralManager(false, state: .PoweredOn)
        let services = createPeripheralManagerServices(peripheralManager)
        services[0].characteristicsFromProfiles()
        let future = peripheralManager.addService(services[0])
        future.onSuccess {
            mock.isAdvertising = true
            onSuccess(mock: mock, peripheralManager: peripheralManager, service: services[0])
        }
        future.onFailure {error in
            XCTAssert(false, "onFailure called")
        }
        peripheralManager.didAddService(services[0].cbMutableService, error: nil)
    }
    
    func testAddCharacteristicsSuccess() {
        let expectation = expectationWithDescription("onSuccess fulfilled for future")
        self.addCharacteristics {(mock: CBPeripheralManagerMock, peripheralManager: PeripheralManager, service: MutableService) -> Void in
            expectation.fulfill()
            let chracteristics = peripheralManager.characteristics.map{$0.uuid}
            XCTAssertEqual(chracteristics.count, 2, "characteristic count invalid")
            XCTAssert(chracteristics.contains(CBUUID(string: Gnosus.HelloWorldService.Greeting.uuid)), "characteristic uuid is invalid")
            XCTAssert(chracteristics.contains(CBUUID(string: Gnosus.HelloWorldService.UpdatePeriod.uuid)), "characteristic uuid is invalid")
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func testNotSubscribeToUpdates() {
        let expectation = expectationWithDescription("onSuccess fulfilled for future")
        self.addCharacteristics {(mock: CBPeripheralManagerMock, peripheralManager: PeripheralManager, service: MutableService) -> Void in
            expectation.fulfill()
            let characteristic = peripheralManager.characteristics[0]
            XCTAssertFalse(characteristic.hasSubscriber, "hasSubscriber value invalid")
            XCTAssertFalse(characteristic.isUpdating, "isUpdating value invalid")
            XCTAssertFalse(characteristic.updateValueWithData("0".dataFromHexString()), "updateValueWithData invalid return status")
            XCTAssertEqual(service.uuid, characteristic.service?.uuid, "characteristic service not found")
            XCTAssertFalse(mock.updateValueCalled, "updateValue not called")
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testSubscribeToUpdates() {
        let expectation = expectationWithDescription("onSuccess fulfilled for future")
        self.addCharacteristics {(mock: CBPeripheralManagerMock, peripheralManager: PeripheralManager, service: MutableService) -> Void in
            expectation.fulfill()
            let characteristic = peripheralManager.characteristics[0]
            peripheralManager.didSubscribeToCharacteristic(characteristic.cbMutableChracteristic)
            XCTAssert(characteristic.hasSubscriber, "hasSubscriber value invalid")
            XCTAssert(characteristic.isUpdating, "isUpdating value invalid")
            XCTAssert(characteristic.updateValueWithData("0".dataFromHexString()), "updateValueWithData invalid return status")
            XCTAssert(mock.updateValueCalled, "updateValueWithData not called")
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func testUnsubscribeToUpdates() {
        let expectation = expectationWithDescription("onSuccess fulfilled for future")
        self.addCharacteristics {(mock: CBPeripheralManagerMock, peripheralManager: PeripheralManager, service: MutableService) -> Void in
            expectation.fulfill()
            let characteristic = peripheralManager.characteristics[0]
            peripheralManager.didSubscribeToCharacteristic(characteristic.cbMutableChracteristic)
            peripheralManager.didUnsubscribeFromCharacteristic(characteristic.cbMutableChracteristic)
            XCTAssertFalse(characteristic.hasSubscriber, "hasSubscriber value invalid")
            XCTAssertFalse(characteristic.isUpdating, "isUpdating value invalid")
            XCTAssertFalse(characteristic.updateValueWithData("0".dataFromHexString()), "updateValueWithData invalid return status")
            XCTAssertFalse(mock.updateValueCalled, "updateValueWithData not called")
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testSubscriberUpdateFailed() {
        let expectation = expectationWithDescription("onSuccess fulfilled for future")
        self.addCharacteristics {(mock: CBPeripheralManagerMock, peripheralManager: PeripheralManager, service: MutableService) -> Void in
            expectation.fulfill()
            let characteristic = peripheralManager.characteristics[0]
            peripheralManager.didSubscribeToCharacteristic(characteristic.cbMutableChracteristic)
            XCTAssert(characteristic.hasSubscriber, "hasSubscriber not set")
            XCTAssert(characteristic.isUpdating, "isUpdating not set")
            mock.updateValueReturn = false
            XCTAssertFalse(characteristic.updateValueWithData("0".dataFromHexString()), "updateValueWithData invalid return status")
            XCTAssertFalse(characteristic.isUpdating, "isUpdating not set")
            XCTAssert(characteristic.hasSubscriber, "hasSubscriber not set")
            XCTAssert(mock.updateValueCalled, "updateValueWithData not called")
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func testResumeSubscriberUpdates() {
        let expectation = expectationWithDescription("onSuccess fulfilled for future")
        self.addCharacteristics {(mock: CBPeripheralManagerMock, peripheralManager: PeripheralManager, service: MutableService) -> Void in
            expectation.fulfill()
            let characteristic = peripheralManager.characteristics[0]
            peripheralManager.didSubscribeToCharacteristic(characteristic.cbMutableChracteristic)
            XCTAssert(characteristic.hasSubscriber, "hasSubscriber not set")
            XCTAssert(characteristic.isUpdating, "isUpdating not set")
            mock.updateValueReturn = false
            XCTAssertFalse(characteristic.updateValueWithData("0".dataFromHexString()), "updateValueWithData invalid return status")
            XCTAssertFalse(characteristic.isUpdating, "isUpdating not set")
            XCTAssert(characteristic.hasSubscriber, "hasSubscriber not set")
            XCTAssert(mock.updateValueCalled, "updateValueWithData not called")
            peripheralManager.isReadyToUpdateSubscribers()
            XCTAssert(characteristic.isUpdating, "isUpdating not set")
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
//    func testStartRespondingToWriteRequests() {
//        let expectation = expectationWithDescription("onFailure fulfilled for future")
//        self.addCharacteristics {(mock: CBPeripheralManagerMock, peripheralManager: PeripheralManager, service: MutableService) -> Void in
//            let characteristic = peripheralManager.characteristics[0]
//            let future = characteristic.startRespondingToWriteRequests()
//            future.onSuccess {_ in
//                expectation.fulfill()
//            }
//            future.onFailure {error in
//                XCTAssert(false, "onFailure called")
//            }
//            mock.impl.didRespondToWriteRequest(RequestMock())
//        }
//        waitForExpectationsWithTimeout(2) {error in
//            XCTAssertNil(error, "\(error)")
//        }
//    }
//
//    func testStopRespondingToWriteRequests() {
//        let mock = MutableCharacteristicMock()
//        let future = mock.impl.startRespondingToWriteRequests()
//        mock.impl.stopRespondingToWriteRequests()
//        future.onSuccess {_ in
//            XCTAssert(false, "onSuccess called")
//        }
//        future.onFailure {error in
//            XCTAssert(false, "onFailure called")
//        }
//        mock.impl.didRespondToWriteRequest(RequestMock())
//    }

}
