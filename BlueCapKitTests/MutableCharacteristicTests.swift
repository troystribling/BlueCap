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

    func addCharacteristics(onSuccess: (mock: CBPeripheralManagerMock, peripheralManager: PeripheralManagerUT, service: MutableService) -> Void) {
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
        self.addCharacteristics {(mock: CBPeripheralManagerMock, peripheralManager: PeripheralManagerUT, service: MutableService) -> Void in
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
        self.addCharacteristics {(mock: CBPeripheralManagerMock, peripheralManager: PeripheralManagerUT, service: MutableService) -> Void in
            expectation.fulfill()
            let characteristic = peripheralManager.characteristics[0]
            XCTAssertFalse(characteristic.hasSubscriber, "hasSubscriber value invalid")
            XCTAssertFalse(characteristic.isUpdating, "isUpdating value invalid")
            XCTAssertFalse(characteristic.updateValueWithData("aa".dataFromHexString()), "updateValueWithData invalid return status")
            XCTAssertEqual(service.uuid, characteristic.service?.uuid, "characteristic service not found")
            XCTAssertFalse(mock.updateValueCalled, "updateValue not called")
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testSubscribeToUpdates() {
        let expectation = expectationWithDescription("onSuccess fulfilled for future")
        self.addCharacteristics {(mock: CBPeripheralManagerMock, peripheralManager: PeripheralManagerUT, service: MutableService) -> Void in
            expectation.fulfill()
            let characteristic = peripheralManager.characteristics[0]
            peripheralManager.didSubscribeToCharacteristic(characteristic.cbMutableChracteristic)
            XCTAssert(characteristic.hasSubscriber, "hasSubscriber value invalid")
            XCTAssert(characteristic.isUpdating, "isUpdating value invalid")
            XCTAssert(characteristic.updateValueWithData("aa".dataFromHexString()), "updateValueWithData invalid return status")
            XCTAssert(mock.updateValueCalled, "updateValueWithData not called")
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func testUnsubscribeToUpdates() {
        let expectation = expectationWithDescription("onSuccess fulfilled for future")
        self.addCharacteristics {(mock: CBPeripheralManagerMock, peripheralManager: PeripheralManagerUT, service: MutableService) -> Void in
            expectation.fulfill()
            let characteristic = peripheralManager.characteristics[0]
            peripheralManager.didSubscribeToCharacteristic(characteristic.cbMutableChracteristic)
            peripheralManager.didUnsubscribeFromCharacteristic(characteristic.cbMutableChracteristic)
            XCTAssertFalse(characteristic.hasSubscriber, "hasSubscriber value invalid")
            XCTAssertFalse(characteristic.isUpdating, "isUpdating value invalid")
            XCTAssertFalse(characteristic.updateValueWithData("aa".dataFromHexString()), "updateValueWithData invalid return status")
            XCTAssertFalse(mock.updateValueCalled, "updateValueWithData not called")
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testSubscriberUpdateFailed() {
        let expectation = expectationWithDescription("onSuccess fulfilled for future")
        self.addCharacteristics {(mock: CBPeripheralManagerMock, peripheralManager: PeripheralManagerUT, service: MutableService) -> Void in
            expectation.fulfill()
            let characteristic = peripheralManager.characteristics[0]
            peripheralManager.didSubscribeToCharacteristic(characteristic.cbMutableChracteristic)
            XCTAssert(characteristic.hasSubscriber, "hasSubscriber not set")
            XCTAssert(characteristic.isUpdating, "isUpdating not set")
            mock.updateValueReturn = false
            XCTAssertFalse(characteristic.updateValueWithData("aa".dataFromHexString()), "updateValueWithData invalid return status")
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
        self.addCharacteristics {(mock: CBPeripheralManagerMock, peripheralManager: PeripheralManagerUT, service: MutableService) -> Void in
            expectation.fulfill()
            let characteristic = peripheralManager.characteristics[0]
            peripheralManager.didSubscribeToCharacteristic(characteristic.cbMutableChracteristic)
            XCTAssert(characteristic.hasSubscriber, "hasSubscriber not set")
            XCTAssert(characteristic.isUpdating, "isUpdating not set")
            mock.updateValueReturn = false
            XCTAssertFalse(characteristic.updateValueWithData("aa".dataFromHexString()), "updateValueWithData invalid return status")
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
    
    func testStartRespondingToWriteRequestsSuccess() {
        let expectation = expectationWithDescription("onSuccess fulfilled for future")
        self.addCharacteristics {(mock: CBPeripheralManagerMock, peripheralManager: PeripheralManagerUT, service: MutableService) -> Void in
            let characteristic = peripheralManager.characteristics[0]
            let value = "aa".dataFromHexString()
            let requestMock = CBATTRequestMock(characteristic: characteristic.cbMutableChracteristic, offset: 0, value: value)
            let future = characteristic.startRespondingToWriteRequests()
            future.onSuccess {request in
                expectation.fulfill()
                characteristic.respondToRequest(request, withResult: CBATTError.Success)
                XCTAssertEqual(request.characteristic.UUID, characteristic.uuid, "characteristic UUID invalid")
                XCTAssertEqual(peripheralManager.result, CBATTError.Success, "result is invalid")
                XCTAssertEqual(request.value, value, "request value is invalid")
                XCTAssert(peripheralManager.respondToRequestCalled, "respondoRequestNotCalled")                
            }
            future.onFailure {error in
                XCTAssert(false, "onFailure called")
            }
            peripheralManager.didReceiveWriteRequest(requestMock)
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testStartRespondingToMultipleWriteRequestsSuccess() {
        let expectation = expectationWithDescription("onSuccess fulfilled for future")
        var writeCount = 0
        self.addCharacteristics {(mock: CBPeripheralManagerMock, peripheralManager: PeripheralManagerUT, service: MutableService) -> Void in
            let characteristic = peripheralManager.characteristics[0]
            let values = ["aa".dataFromHexString(), "a1".dataFromHexString(), "a2".dataFromHexString(), "a3".dataFromHexString(), "a4".dataFromHexString(), "a5".dataFromHexString()]
            let requestMocks = values.map{CBATTRequestMock(characteristic: characteristic.cbMutableChracteristic, offset: 0, value: $0)}
            let future = characteristic.startRespondingToWriteRequests()
            future.onSuccess {request in
                if writeCount == 0 {
                    expectation.fulfill()
                }
                characteristic.respondToRequest(request, withResult: CBATTError.Success)
                XCTAssertEqual(request.characteristic.UUID, characteristic.uuid, "characteristic UUID invalid")
                XCTAssertEqual(peripheralManager.result, CBATTError.Success, "result is invalid")
                XCTAssertEqual(request.value, values[writeCount], "request value is invalid")
                XCTAssert(peripheralManager.respondToRequestCalled, "respondoRequestNotCalled")
                writeCount++
            }
            future.onFailure {error in
                XCTAssert(false, "onFailure called")
            }
            for requestMock in requestMocks {
                peripheralManager.didReceiveWriteRequest(requestMock)
            }
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testStartRespondingToWriteRequestsFailure() {
        self.addCharacteristics {(mock: CBPeripheralManagerMock, peripheralManager: PeripheralManagerUT, service: MutableService) -> Void in
            let characteristic = peripheralManager.characteristics[0]
            let value = "aa".dataFromHexString()
            let request = CBATTRequestMock(characteristic: characteristic.cbMutableChracteristic, offset: 0, value: value)
            peripheralManager.didReceiveWriteRequest(request)
            XCTAssertEqual(peripheralManager.result, CBATTError.WriteNotPermitted, "result is invalid")
            XCTAssert(peripheralManager.respondToRequestCalled, "respondoRequestNotCalled")
        }
    }

    func testStopRespondingToWriteRequests() {
        self.addCharacteristics {(mock: CBPeripheralManagerMock, peripheralManager: PeripheralManagerUT, service: MutableService) -> Void in
            let characteristic = peripheralManager.characteristics[0]
            let value = "aa".dataFromHexString()
            let request = CBATTRequestMock(characteristic: characteristic.cbMutableChracteristic, offset: 0, value: value)
            let future = characteristic.startRespondingToWriteRequests()
            characteristic.stopRespondingToWriteRequests()
            future.onSuccess {_ in
                XCTAssert(false, "onSuccess called")
            }
            future.onFailure {error in
                XCTAssert(false, "onFailure called")
            }
            peripheralManager.didReceiveWriteRequest(request)
        }
    }

    func testRespondToReadRequestSuccess() {
        self.addCharacteristics {(mock: CBPeripheralManagerMock, peripheralManager: PeripheralManagerUT, service: MutableService) -> Void in
            let characteristic = peripheralManager.characteristics[0]
        }
    }
    
    func testRespondToReadRequestFailure() {
        self.addCharacteristics {(mock: CBPeripheralManagerMock, peripheralManager: PeripheralManagerUT, service: MutableService) -> Void in
            let characteristic = peripheralManager.characteristics[0]
        }
    }

}
