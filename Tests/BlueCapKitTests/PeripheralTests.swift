//
//  PeripheralTests.swift
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

// MARK - PeripheralTests -
class PeripheralTests: XCTestCase {

    let RSSI = -45
    let updatedRSSI1 = -50
    let updatedRSSI2 = -75

    var centralManagerMock: CBCentralManagerMock!
    var centralManager: CentralManager!

    let mockServices = [
        CBServiceMock(uuid: CBUUID(string:"2f0a0017-69aa-f316-3e78-4194989a6ccc")),
        CBServiceMock(uuid: CBUUID(string:"2f0a0017-69aa-f316-3e78-4194989a6fff"))
    ]

    let dublicateMockServices = [
        CBServiceMock(uuid: CBUUID(string:"2f0a0017-69aa-f316-3e78-4194989a6ccc")),
        CBServiceMock(uuid: CBUUID(string:"2f0a0017-69aa-f316-3e78-4194989a6fff")),
        CBServiceMock(uuid: CBUUID(string:"2f0a0017-69aa-f316-3e78-4194989a6fff"))
    ]

    override func setUp() {
        Peripheral.RECONNECT_DELAY = TimeInterval(0.0)
        super.setUp()
        self.centralManagerMock = CBCentralManagerMock(state: .poweredOn)
        self.centralManager = CentralManagerUT(centralManager: self.centralManagerMock)
    }
    
    override func tearDown() {
        super.tearDown()
    }

    // MARK: discoverAllServices

    func testDiscoverAllServices_WhenConnectedAndNoErrorInResponse_CompletesSuccessfully() {
        let mockPeripheral = CBPeripheralMock(state: .connected)
        let peripheral = Peripheral(cbPeripheral: mockPeripheral, centralManager: self.centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        let future = peripheral.discoverAllServices()
        peripheral.didDiscoverServices(self.mockServices.map { $0 as CBServiceInjectable }, error:nil)
        XCTAssertFutureSucceeds(future, context: TestContext.immediate) { _ in
            let discoveredServices = peripheral.services
            XCTAssertEqual(discoveredServices.count, 2)
            XCTAssertEqual(mockPeripheral.discoverServicesCalledCount, 1)
            XCTAssert(mockPeripheral.discoverServicesCalled)
            XCTAssertFalse(mockPeripheral.discoverCharacteristicsCalled)
        }
    }

    func testDiscoverAllServices_WhenConnectedAndErrorInResponse_CompletesWithResponseError() {
        let mockPeripheral = CBPeripheralMock(state: .connected)
        let peripheral = Peripheral(cbPeripheral: mockPeripheral, centralManager: self.centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        let future = peripheral.discoverAllServices()
        peripheral.didDiscoverServices(self.mockServices.map { $0 as CBServiceInjectable }, error: TestFailure.error)
        XCTAssertFutureFails(future, context: TestContext.immediate) { error in
            let discoveredServices = peripheral.services
            XCTAssertEqual(discoveredServices.count, 0)
            XCTAssertEqualErrors(error, TestFailure.error)
            XCTAssertEqual(mockPeripheral.discoverServicesCalledCount, 1)
            XCTAssert(mockPeripheral.discoverServicesCalled)
            XCTAssertFalse(mockPeripheral.discoverCharacteristicsCalled)
        }
    }

    func testDiscoverAllServices_WhenDisconnected_CompletesWithPeripheralDisconnected() {
        let mockPeripheral = CBPeripheralMock(state: .disconnected)
        let peripheral = Peripheral(cbPeripheral: mockPeripheral, centralManager: centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        let future = peripheral.discoverAllServices()
        XCTAssertFutureFails(future, context: TestContext.immediate) { error in
            let discoveredServices = peripheral.services
            XCTAssertEqual(discoveredServices.count, 0)
            XCTAssertEqualErrors(error, PeripheralError.disconnected)
            XCTAssertEqual(mockPeripheral.discoverServicesCalledCount, 0)
            XCTAssertFalse(mockPeripheral.discoverServicesCalled)
            XCTAssertFalse(mockPeripheral.discoverCharacteristicsCalled)
        }

    }

    func testDiscoverAllServices_WhenConnectedOnTimeout_CompletesWithServiceDiscoveryTimeout() {
        let mockPeripheral = CBPeripheralMock(state: .connected)
        let peripheral = Peripheral(cbPeripheral: mockPeripheral, centralManager: centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        let future = peripheral.discoverAllServices(timeout: 0.25)
        XCTAssertFutureFails(future, timeout: 5.0) { error in
            let discoveredServices = peripheral.services
            XCTAssertEqual(discoveredServices.count, 0)
            XCTAssertEqualErrors(error, PeripheralError.serviceDiscoveryTimeout)
            XCTAssertEqual(mockPeripheral.discoverServicesCalledCount, 1)
            XCTAssert(mockPeripheral.discoverServicesCalled)
            XCTAssertFalse(mockPeripheral.discoverCharacteristicsCalled)
        }
    }

    func testDiscoverAllServices_WithDuplicateUUIDs_CompletesSuccessfully() {
        let mockPeripheral = CBPeripheralMock(state: .connected)
        let peripheral = Peripheral(cbPeripheral: mockPeripheral, centralManager: self.centralManager, advertisements: peripheralAdvertisements, RSSI: RSSI)
        let future = peripheral.discoverAllServices()
        peripheral.didDiscoverServices(dublicateMockServices.map { $0 as CBServiceInjectable }, error:nil)
        XCTAssertFutureSucceeds(future, context: TestContext.immediate) { _ in
            let discoveredServices = peripheral.services
            XCTAssertEqual(discoveredServices.count, 3)
            XCTAssertEqual(mockPeripheral.discoverServicesCalledCount, 1)
            XCTAssertEqual(peripheral.services(withUUID: self.dublicateMockServices[0].uuid)!.count, 1)
            XCTAssertEqual(peripheral.services(withUUID: self.dublicateMockServices[1].uuid)!.count, 2)
            XCTAssert(mockPeripheral.discoverServicesCalled)
            XCTAssertFalse(mockPeripheral.discoverCharacteristicsCalled)
        }
    }

    // MARK: connect
    
    func testConnect_WhenDisconnected_CompletesSuccesfullyAndYields() {
        let mockPeripheral = CBPeripheralMock(state: .disconnected)
        let peripheral = Peripheral(cbPeripheral: mockPeripheral, centralManager: centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        let stream = peripheral.connect(connectionTimeout: 120.0)
        peripheral.didConnectPeripheral()
        XCTAssertFutureStreamSucceeds(stream, context: TestContext.immediate, validations: [
            { _ in
                XCTAssert(self.centralManagerMock.connectPeripheralCalled)
            }
        ])
    }

    func testConnect_WhenConnected_DoesNotCallConnect() {
        let mockPeripheral = CBPeripheralMock(state: .connected)
        let peripheral = Peripheral(cbPeripheral: mockPeripheral, centralManager: centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        let _ = peripheral.connect()
        XCTAssertFalse(centralManagerMock.connectPeripheralCalled)
    }

    func testConnect_WhenDisconnectedWithConnectionError_CompletesWithConnectionError() {
        let mockPeripheral = CBPeripheralMock(state: .disconnected)
        let peripheral = Peripheral(cbPeripheral: mockPeripheral, centralManager: centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        let stream = peripheral.connect(connectionTimeout: 120.0)
        XCTAssert(centralManagerMock.connectPeripheralCalled)
        peripheral.didFailToConnectPeripheral(TestFailure.error)
        XCTAssertFutureStreamFails(stream, context:  TestContext.immediate, validations: [
            { error in
                XCTAssertEqualErrors(error, TestFailure.error)
                XCTAssertEqual(peripheral.disconnectionCount, 1)
                XCTAssertEqual(peripheral.timeoutCount, 0)
            }
        ])
    }

    func testConnect_WhenDisconnectedAndDisconnectCalled_CompletesWithErrorDisconnected() {
        let mockPeripheral = CBPeripheralMock(state: .disconnected)
        let peripheral = PeripheralUT(cbPeripheral: mockPeripheral, centralManager: centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        let stream = peripheral.connect()
        peripheral.disconnect()
        XCTAssertFutureStreamFails(stream, context: TestContext.immediate, validations: [
            { error in
                XCTAssertEqualErrors(error, PeripheralError.forcedDisconnect)
                XCTAssertEqual(peripheral.disconnectionCount, 0)
                XCTAssertEqual(peripheral.timeoutCount, 0)
            }
        ])
    }
    
    func testConnect_WhenConnectedAndDisconnectCalled_CompletesWithErrorForcedDisconnect() {
        let mockPeripheral = CBPeripheralMock(state: .connected)
        let peripheral = Peripheral(cbPeripheral: mockPeripheral, centralManager: centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        let stream = peripheral.connect()
        peripheral.disconnect()
        peripheral.didDisconnectPeripheral(nil)
        XCTAssertFutureStreamFails(stream, context: TestContext.immediate, validations: [
            { error in
                XCTAssertEqualErrors(error, PeripheralError.forcedDisconnect)
                XCTAssertEqual(peripheral.disconnectionCount, 0)
                XCTAssertEqual(peripheral.timeoutCount, 0)
            }
        ])
    }

    func testConnect_WhenConnectedAndPeripheralDisconnectsWithoutError_CompletesWithErrorDisconnect() {
        let mockPeripheral = CBPeripheralMock(state: .connected)
        let peripheral = Peripheral(cbPeripheral: mockPeripheral, centralManager: centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        let stream = peripheral.connect()
        peripheral.didDisconnectPeripheral(nil)
        XCTAssertFutureStreamFails(stream, context: TestContext.immediate, validations: [
            { error in
                XCTAssertEqualErrors(error, PeripheralError.disconnected)
                XCTAssertEqual(peripheral.disconnectionCount, 1)
                XCTAssertEqual(peripheral.timeoutCount, 0)
            }
        ])
    }

    func testConnect_WhenConnectedAndPeripheralDisconnectsWithError_CompletesErrorDisconnect() {
        let mockPeripheral = CBPeripheralMock(state: .connected)
        let peripheral = Peripheral(cbPeripheral: mockPeripheral, centralManager: centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        let stream = peripheral.connect()
        peripheral.didDisconnectPeripheral(TestFailure.error)
        XCTAssertFutureStreamFails(stream, context: TestContext.immediate, validations: [
            { error in
                XCTAssertEqualErrors(error, TestFailure.error)
                XCTAssertEqual(peripheral.disconnectionCount, 1)
                XCTAssertEqual(peripheral.timeoutCount, 0)
            }
        ])
    }


    func testConnect_WhenDisconnectedByConnectionTimeout_CompletesWithErrorConnectionTimeout() {
        let mockPeripheral = CBPeripheralMock(state: .disconnected)
        let peripheral = PeripheralUT(cbPeripheral: mockPeripheral, centralManager: centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        let stream = peripheral.connect(connectionTimeout: 0.25)
        XCTAssertFutureStreamFails(stream, timeout: 5.0, validations: [
            { error in
                XCTAssertEqualErrors(error, PeripheralError.connectionTimeout)
                XCTAssertEqual(self.centralManagerMock.connectPeripheralCount, 1)
                XCTAssertEqual(peripheral.disconnectionCount, 0)
                XCTAssertEqual(peripheral.timeoutCount, 1)
            }
        ])
    }
    
    func testConnect_WhenDisconnectedWithNoError_CompletesWithErrorDisconnected() {
        let mockPeripheral = CBPeripheralMock(state:.disconnected)
        let peripheral = Peripheral(cbPeripheral: mockPeripheral, centralManager: centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        let stream = peripheral.connect()
        peripheral.didDisconnectPeripheral(nil)
        XCTAssertFutureStreamFails(stream, timeout: 5.0, validations: [
            { error in
                XCTAssertEqualErrors(error, PeripheralError.disconnected)
                XCTAssertEqual(self.centralManagerMock.connectPeripheralCount, 1)
                XCTAssertEqual(peripheral.disconnectionCount, 1)
                XCTAssertEqual(peripheral.timeoutCount, 0)
            }
        ])
    }

    func testConnect_WhenDisconnectedWithError_CompletesWithError() {
        let mockPeripheral = CBPeripheralMock(state:.disconnected)
        let peripheral = Peripheral(cbPeripheral: mockPeripheral, centralManager: centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        let stream = peripheral.connect()
        peripheral.didDisconnectPeripheral(TestFailure.error)
        XCTAssertFutureStreamFails(stream, timeout: 5.0, validations: [
            { error in
                XCTAssertEqualErrors(error, TestFailure.error)
                XCTAssertEqual(self.centralManagerMock.connectPeripheralCount, 1)
                XCTAssertEqual(peripheral.disconnectionCount, 1)
                XCTAssertEqual(peripheral.timeoutCount, 0)
            }
        ])
    }

    // MARK: Read RSSI
    func testReadRSSI_WhenConnected_CompletesSuccessfully() {
        let mockPeripheral = CBPeripheralMock(state: .connected)
        let peripheral = Peripheral(cbPeripheral: mockPeripheral, centralManager: centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        let future = peripheral.readRSSI()
        peripheral.didReadRSSI(NSNumber(value: Int32(self.updatedRSSI1)), error: nil)
        XCTAssertFutureSucceeds(future, context: TestContext.immediate) { rssi in
            XCTAssertEqual(rssi, self.updatedRSSI1)
            XCTAssertEqual(peripheral.RSSI, self.updatedRSSI1)
        }
    }

    func testReadRSSI_WhenDisconnected_CompletesWithPeripheralDisconnected() {
        let mockPeripheral = CBPeripheralMock(state: .disconnected)
        let peripheral = Peripheral(cbPeripheral: mockPeripheral, centralManager: centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        let future = peripheral.readRSSI()
        XCTAssertFutureFails(future, context: TestContext.immediate) { error in
            XCTAssertEqualErrors(error, PeripheralError.disconnected)
        }
    }

    func testReadRSSI_WhenConnectedAndErrorInResponse_CompletesWithResponseError() {
        let mockPeripheral = CBPeripheralMock(state: .connected)
        let peripheral = Peripheral(cbPeripheral: mockPeripheral, centralManager: centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        let future = peripheral.readRSSI()
        peripheral.didReadRSSI(NSNumber(value: Int32(self.updatedRSSI1)), error: TestFailure.error)
        XCTAssertFutureFails(future, context: TestContext.immediate) { error in
            XCTAssertEqualErrors(error, TestFailure.error)
        }
    }

    func testStartPollingRSSI_WhenConnectedAndNoErrorInAck_CompletesSuccessfully() {
        let mockPeripheral = CBPeripheralMock(state: .connected)
        let peripheral = Peripheral(cbPeripheral: mockPeripheral, centralManager: centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        mockPeripheral.bcPeripheral = peripheral
        let future = peripheral.startPollingRSSI(period: 0.25)
        XCTAssertFutureStreamSucceeds(future, timeout: 120, validations: [
            { rssi in
                XCTAssertEqual(rssi, mockPeripheral.RSSI)
                XCTAssertEqual(peripheral.RSSI, mockPeripheral.RSSI)
                XCTAssertEqual(mockPeripheral.readRSSICalledCount, 1)
            },
            { rssi in
                XCTAssertEqual(rssi, mockPeripheral.RSSI)
                XCTAssertEqual(peripheral.RSSI, mockPeripheral.RSSI)
                XCTAssertEqual(mockPeripheral.readRSSICalledCount, 2)
                peripheral.stopPollingRSSI()
            }
        ])
    }

    func testStartPollingRSSI_WhenDisconnected_CompletesWithPeripheralDisconnected() {
        let mockPeripheral = CBPeripheralMock(state: .disconnected)
        let peripheral = Peripheral(cbPeripheral: mockPeripheral, centralManager: centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        let future = peripheral.startPollingRSSI()
        XCTAssertFutureStreamFails(future, context: TestContext.immediate, validations: [
            { error in
                peripheral.stopPollingRSSI()
                XCTAssertEqualErrors(error, PeripheralError.disconnected)
            }
        ])
    }


   func testStartPollingRSSI_WhenDisconnectedAfterStart_CompletesWithPeripheralDisconnected() {
        let mockPeripheral = CBPeripheralMock(state: .connected)
        let peripheral = Peripheral(cbPeripheral: mockPeripheral, centralManager: centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        mockPeripheral.bcPeripheral = peripheral
        let expectation = self.expectation(description: "expectation fulfilled")
        var completed = false
        let future = peripheral.startPollingRSSI(period: 0.25)
        future.onSuccess { rssi in
            if (!completed) {
                completed = true
                XCTAssertEqual(rssi, mockPeripheral.RSSI)
                XCTAssertEqual(peripheral.RSSI, mockPeripheral.RSSI)
                XCTAssertEqual(mockPeripheral.readRSSICalledCount, 1)
                mockPeripheral.state = .disconnected
            } else {
                expectation.fulfill()
                XCTFail()
            }
        }
        future.onFailure { error in
            expectation.fulfill()
            peripheral.stopPollingRSSI()
            XCTAssertEqualErrors(error, PeripheralError.disconnected)
        }
        waitForExpectations(timeout: 120) { error in
            XCTAssertNil(error, "\(String(describing: error))")
        }
    }

    func testStartPollingRSSI_WhenConnectedAndErrorInResponse_CompletedWithResponceError() {
        let mockPeripheral = CBPeripheralMock(state: .connected)
        let peripheral = Peripheral(cbPeripheral: mockPeripheral, centralManager: centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        let future = peripheral.startPollingRSSI(period: 0.25)
        mockPeripheral.error = TestFailure.error
        mockPeripheral.bcPeripheral = peripheral
        XCTAssertFutureStreamFails(future, validations: [
            { error in
                peripheral.stopPollingRSSI()
                XCTAssertEqualErrors(error, TestFailure.error)
            }
        ])
    }

    func testStopPollingRSSI_WhenConnected_StopsRSSIUpdates() {
        let mockPeripheral = CBPeripheralMock(state: .connected)
        let peripheral = Peripheral(cbPeripheral: mockPeripheral, centralManager: centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        let future = peripheral.startPollingRSSI(period: 0.1)
        mockPeripheral.bcPeripheral = peripheral
        XCTAssertFutureStreamSucceeds(future, timeout: 120, validations: [
            { rssi in
                peripheral.stopPollingRSSI()
            },
        ])
        sleep(1)
    }

    func testStopPollingRSSI_WhenDisconnected_StopsRSSIUpdates() {
        let mockPeripheral = CBPeripheralMock(state: .disconnected)
        let peripheral = Peripheral(cbPeripheral: mockPeripheral, centralManager: centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        let future = peripheral.startPollingRSSI(period: 0.1)
        mockPeripheral.bcPeripheral = peripheral
        XCTAssertFutureStreamFails(future, validations: [
            { error in
                peripheral.stopPollingRSSI()
            }
        ])
        sleep(1)
   }
}
