//
//  BCPeripheralTests.swift
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

// MARK - BCPeripheralTests -
class BCPeripheralTests: XCTestCase {

    let RSSI = -45
    let updatedRSSI1 = -50
    let updatedRSSI2 = -75

    var centralManagerMock = CBCentralManagerMock(state: .PoweredOn)
    var centralManager: BCCentralManager!
    let immediateContext = ImmediateContext()

    let mockServices = [
        CBServiceMock(UUID:CBUUID(string:"2f0a0017-69aa-f316-3e78-4194989a6ccc")),
        CBServiceMock(UUID:CBUUID(string:"2f0a0017-69aa-f316-3e78-4194989a6fff"))
    ]

    var mockCharateristics = [
        CBCharacteristicMock(UUID: CBUUID(string:"2f0a0017-69aa-f316-3e78-4194989a6111"), properties: [.Read, .Write], isNotifying: false),
        CBCharacteristicMock(UUID: CBUUID(string:"2f0a0017-69aa-f316-3e78-4194989a6222"), properties: [.Read, .Write], isNotifying: false),
        CBCharacteristicMock(UUID: CBUUID(string:"2f0a0017-69aa-f316-3e78-4194989a6333"), properties: [.Read, .Write], isNotifying: false)
    ]
    
    override func setUp() {
        super.setUp()
        self.centralManager = CentralManagerUT(centralManager: self.centralManagerMock)
    }
    
    override func tearDown() {
        super.tearDown()
    }

    // MARK: discoverAllServices
    func testDiscoverAllServices_WhenConnectedAndNoErrorInResponse_CompletesSuccessfully() {
        let mockPeripheral = CBPeripheralMock(state: .Connected)
        let peripheral = BCPeripheral(cbPeripheral: mockPeripheral, centralManager: self.centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        let future = peripheral.discoverAllServices()
        peripheral.didDiscoverServices(self.mockServices.map { $0 as CBServiceInjectable }, error:nil)
        XCTAssertFutureSucceeds(future, context: self.immediateContext) { _ in
            let discoveredServices = peripheral.services
            XCTAssertEqual(discoveredServices.count, 2, "Peripheral service count invalid")
            XCTAssertEqual(mockPeripheral.discoverServicesCalledCount, 1, "CBPeripheral#discoverServices called more than once")
            XCTAssert(mockPeripheral.discoverServicesCalled, "BC#discoverServices not called")
            XCTAssertFalse(mockPeripheral.discoverCharacteristicsCalled, "CBPeripheral#discoverChracteristics called")
        }
    }

    func testDiscoverAllServices_WhenConnectedAndErrorInResponse_CompletesWithResponseError() {
        let mockPeripheral = CBPeripheralMock(state: .Connected)
        let peripheral = BCPeripheral(cbPeripheral: mockPeripheral, centralManager: self.centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        let future = peripheral.discoverAllServices()
        peripheral.didDiscoverServices(self.mockServices.map { $0 as CBServiceInjectable }, error: TestFailure.error)
        XCTAssertFutureFails(future, context: self.immediateContext) { error in
            let discoveredServices = peripheral.services
            XCTAssertEqual(discoveredServices.count, 0, "Peripheral service count invalid")
            XCTAssertEqual(error.code, TestFailure.error.code, "Error code invalid")
            XCTAssertEqual(mockPeripheral.discoverServicesCalledCount, 1, "CBPeripheral#discoverServices called more than once")
            XCTAssert(mockPeripheral.discoverServicesCalled, "CBPeripheral#discoverServices not called")
            XCTAssertFalse(mockPeripheral.discoverCharacteristicsCalled, "CBPeripheral#discoverChracteristics called")
        }
    }

    func testDiscoverAllServices_WhenDisconnected_CompletesWithPeripheralDisconnected() {
        let mockPeripheral = CBPeripheralMock(state: .Disconnected)
        let peripheral = BCPeripheral(cbPeripheral: mockPeripheral, centralManager: self.centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        let future = peripheral.discoverAllServices()
        XCTAssertFutureFails(future, context: self.immediateContext) { error in
            let discoveredServices = peripheral.services
            XCTAssertEqual(discoveredServices.count, 0, "Peripheral service count invalid")
            XCTAssertEqual(error.code, BCError.peripheralDisconnected.code, "Error code invalid")
            XCTAssertEqual(mockPeripheral.discoverServicesCalledCount, 0, "CBPeripheral#discoverServices called more than once")
            XCTAssertFalse(mockPeripheral.discoverServicesCalled, "CBPeripheral#discoverServices called")
            XCTAssertFalse(mockPeripheral.discoverCharacteristicsCalled, "CBPeripheral#discoverChracteristics called")
        }

    }

    func testDiscoverAllServices_WhenConnectedOnTimeout_CompletesWithServiceDiscoveryTimeout() {
        let mockPeripheral = CBPeripheralMock(state: .Connected)
        let peripheral = BCPeripheral(cbPeripheral: mockPeripheral, centralManager: self.centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        let future = peripheral.discoverAllServices(0.25)
        XCTAssertFutureFails(future, timeout: 5.0) { error in
            let discoveredServices = peripheral.services
            XCTAssertEqual(discoveredServices.count, 0, "Peripheral service count invalid")
            XCTAssertEqual(error.code, BCError.peripheralServiceDiscoveryTimeout.code, "Error code invalid")
            XCTAssertEqual(mockPeripheral.discoverServicesCalledCount, 1, "CBPeripheral#discoverServices called more than once")
            XCTAssert(mockPeripheral.discoverServicesCalled, "CBPeripheral#discoverServices not called")
            XCTAssertFalse(mockPeripheral.discoverCharacteristicsCalled, "CBPeripheral#discoverChracteristics called")
        }
    }

    // MARK: discoverAllPeripheralServices
    func testDiscoverAllPeripheralServices_WhenConnectedAndNoErrorInResponse_CompletesSuccessfully() {
        let mockPeripheral = CBPeripheralMock(state:.Connected)
        let peripheral = PeripheralUT(cbPeripheral:mockPeripheral, centralManager:self.centralManager, advertisements:peripheralAdvertisements, rssi: self.RSSI, error:nil)
        let future = peripheral.discoverAllPeripheralServices()
        peripheral.didDiscoverServices(self.mockServices.map { $0 as CBServiceInjectable }, error:nil)
        XCTAssertFutureSucceeds(future, timeout: 5.0) { _ in
            let discoveredServices = peripheral.services
            XCTAssertEqual(discoveredServices.count, 2, "Peripheral service count invalid")
            XCTAssert(mockPeripheral.discoverServicesCalled, "CBPeripheral#discoverServices not called")
        }
    }

    func testDiscoverAllPeripheralServices_WhenConnectedAndErrorInServiceDiscoveryResponse_CompletesWithResponseError() {
        let mockPeripheral = CBPeripheralMock(state: .Connected)
        let peripheral = PeripheralUT(cbPeripheral:mockPeripheral, centralManager:self.centralManager, advertisements:peripheralAdvertisements, rssi: self.RSSI, error:TestFailure.error)
        let future = peripheral.discoverAllPeripheralServices()
        peripheral.didDiscoverServices(self.mockServices.map { $0 as CBServiceInjectable }, error:nil)
        XCTAssertFutureFails(future, timeout: 5.0) { error in
            XCTAssertEqual(error.code, TestFailure.error.code, "Error code invalid")
            XCTAssert(mockPeripheral.discoverServicesCalled, "CBPeripheral#discoverServices not called")
        }
    }

    func testDiscoverAllPeripheralServices_WhenConnectedAndNoServicesDiscovered_CompletesWithPeripheralNoServices() {
        let mockPeripheral = CBPeripheralMock(state: .Connected)
        let peripheral = BCPeripheral(cbPeripheral: mockPeripheral, centralManager: self.centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        let future = peripheral.discoverAllPeripheralServices()
        peripheral.didDiscoverServices([], error:nil)
        XCTAssertFutureFails(future, timeout: 5.0) { error in
            XCTAssertEqual(error.domain, BCError.domain, "message domain invalid")
            XCTAssertEqual(error.code, BCError.peripheralNoServices.code, "message code invalid")
        }
    }

    // MARK: connect
    func testConnect_WhenDisconnected_CompletesSuccesfullyWithEventConnect() {
        let mockPeripheral = CBPeripheralMock(state:.Disconnected)
        let peripheral = BCPeripheral(cbPeripheral: mockPeripheral, centralManager: self.centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        let future = peripheral.connect(connectionTimeout: 120.0)
        peripheral.didConnectPeripheral()
        XCTAssertFutureStreamSucceeds(future, context: self.immediateContext, validations: [
            { (peripheral, connectionEvent) in
                XCTAssert(self.centralManagerMock.connectPeripheralCalled, "CentralManager#connectPeripheralCalled not called")
                XCTAssertEqual(connectionEvent, BCConnectionEvent.Connect, "Invalid connection event")
            }
        ])
    }

    func testConnect_WhenConnected_DoesNotConnect() {
        let mockPeripheral = CBPeripheralMock(state:.Connected)
        let peripheral = BCPeripheral(cbPeripheral: mockPeripheral, centralManager: self.centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        peripheral.connect()
        XCTAssertFalse(self.centralManagerMock.connectPeripheralCalled, "CentralManager#connectPeripheralCalled called")
    }

    func testConnect_WhenDisconnectedWithConnectionError_CompletesWithConnectionError() {
        let mockPeripheral = CBPeripheralMock(state: .Disconnected)
        let peripheral = BCPeripheral(cbPeripheral: mockPeripheral, centralManager: self.centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        let future = peripheral.connect(connectionTimeout: 120.0)
        peripheral.didFailToConnectPeripheral(TestFailure.error)
        XCTAssert(self.centralManagerMock.connectPeripheralCalled, "CentralManager#connectPeripheralCalled not called")
        XCTAssertFutureStreamFails(future, context: self.immediateContext, validations: [
            { error in
                XCTAssert(error.code == TestFailure.error.code, "Error code invalid")
            }
        ])
    }

    func testConnect_WhenDisconnectedAndForcedDisconnect_CompletesWithPeripheralDisconnected() {
        let mockPeripheral = CBPeripheralMock(state: .Disconnected)
        let peripheral = BCPeripheral(cbPeripheral: mockPeripheral, centralManager: self.centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        let future = peripheral.connect()
        peripheral.disconnect()
        XCTAssertFutureStreamFails(future, context: self.immediateContext, validations: [
            { error in
                XCTAssertEqual(error.code, BCError.peripheralDisconnected.code, "Error code invalid")
            }
        ])
    }
    
    func testConnect_WhenConnectedAndForcedDisconnect_CompletesSuccessfullyWithEventForceDisconnect() {
        let mockPeripheral = CBPeripheralMock(state: .Connected)
        let peripheral = BCPeripheral(cbPeripheral: mockPeripheral, centralManager: self.centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        let future = peripheral.connect()
        peripheral.disconnect()
        XCTAssertFutureStreamSucceeds(future, context: self.immediateContext, validations: [
            { (_, connectionEvent) in
                XCTAssertEqual(connectionEvent, BCConnectionEvent.ForceDisconnect, "Invalid connection event")
            }
        ])
    }

    func testConnect_WhenConnectedAndPeripheralDisconnectsWithoutError_CompletesSuccessfullyWithEventDisconnect() {
        let mockPeripheral = CBPeripheralMock(state: .Connected)
        let peripheral = BCPeripheral(cbPeripheral: mockPeripheral, centralManager: self.centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        let future = peripheral.connect()
        peripheral.didDisconnectPeripheral(nil)
        XCTAssertFutureStreamSucceeds(future, context: self.immediateContext, validations: [
            { (_, connectionEvent) in
                XCTAssertEqual(connectionEvent, BCConnectionEvent.Disconnect, "Invalid connection event")
            }
        ])
    }

    func testConnect_WhenConnectedAndPeripheralDisconnectsWithError_CompletesDisconnectError() {
        let mockPeripheral = CBPeripheralMock(state: .Connected)
        let peripheral = BCPeripheral(cbPeripheral: mockPeripheral, centralManager: self.centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        let future = peripheral.connect()
        peripheral.didDisconnectPeripheral(TestFailure.error)
        XCTAssertFutureStreamFails(future, context: self.immediateContext, validations: [
            { error in
                XCTAssertEqual(error.code, TestFailure.error.code, "Error code invalid")
            }
        ])
    }


    func testConnect_WhenDisconnetedAndConnectionTimeout_CompletesSuccessfullyWithEventTimeout() {
        let mockPeripheral = CBPeripheralMock(state: .Disconnected)
        let peripheral = BCPeripheral(cbPeripheral: mockPeripheral, centralManager: self.centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        let future = peripheral.connect(connectionTimeout: 0.25)
        XCTAssertFutureStreamSucceeds(future, timeout: 5.0, validations: [
            { (_, connectionEvent) in
                XCTAssertEqual(connectionEvent, BCConnectionEvent.Timeout, "Invalid connection event")
            }
        ])
    }
    
    func testConnect_WhenDisconnetedAndExceedsTimeoutRetries_CompletesSuccessfullyWithEventGiveUp() {
        let mockPeripheral = CBPeripheralMock(state: .Disconnected)
        let peripheral = BCPeripheral(cbPeripheral: mockPeripheral, centralManager: self.centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        let future = peripheral.connect(connectionTimeout: 0.25, timeoutRetries: 1)
        XCTAssertFutureStreamSucceeds(future, timeout: 5.0, validations: [
            { (peripheral, connectionEvent) in
                peripheral.reconnect()
                XCTAssertEqual(connectionEvent, BCConnectionEvent.Timeout, "Invalid connection event")
            },
            { (peripheral, connectionEvent) in
                XCTAssertEqual(connectionEvent, BCConnectionEvent.GiveUp, "Invalid connection event")
            }
        ])
    }

    func testConnect_WhenDisconnectedWithNoErrorAndExceedsDisconnectRetries_CompletesSuccessfullyWithEventGiveUp() {
        let mockPeripheral = CBPeripheralMock(state:.Connected)
        let peripheral = BCPeripheral(cbPeripheral: mockPeripheral, centralManager: self.centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        let future = peripheral.connect(disconnectRetries: 1)
        peripheral.didConnectPeripheral()
        XCTAssertFutureStreamSucceeds(future, timeout: 5.0, validations: [
            { (peripheral, connectionEvent) in
                XCTAssertEqual(connectionEvent, BCConnectionEvent.Connect, "Invalid connection event")
                peripheral.didDisconnectPeripheral(nil)
            },
            { (peripheral, connectionEvent) in
                XCTAssertEqual(connectionEvent, BCConnectionEvent.Disconnect, "Invalid connection event")
                peripheral.reconnect()
                peripheral.didConnectPeripheral()
            },
            { (peripheral, connectionEvent) in
                XCTAssertEqual(connectionEvent, BCConnectionEvent.Connect, "Invalid connection event")
                peripheral.didDisconnectPeripheral(nil)
            },
            { (peripheral, connectionEvent) in
                XCTAssertEqual(connectionEvent, BCConnectionEvent.GiveUp, "Invalid connection event")
            }
        ])
    }

    
    func testConnect_WhenDisconnectedWithErrorAndExceedsDisconnectRetries_CompletesSuccessfullyWithEventGiveUp() {
        let mockPeripheral = CBPeripheralMock(state:.Connected)
        let peripheral = BCPeripheral(cbPeripheral: mockPeripheral, centralManager: self.centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        let expectation = expectationWithDescription("expectation fulfilled for future")
        let future = peripheral.connect(disconnectRetries: 1)
        future.onSuccess { (peripheral, connectionEvent) in
            switch connectionEvent {
            case .Connect:
                peripheral.didDisconnectPeripheral(TestFailure.error)
            case .Timeout:
                XCTFail("onSuccess Timeout invalid")
            case .Disconnect:
                XCTFail("onSuccess Disconnect invalid")
            case .ForceDisconnect:
                XCTFail("onSuccess ForceDisconnect invalid")
            case .GiveUp:
                expectation.fulfill()
            }
        }
        peripheral.didDisconnectPeripheral(TestFailure.error)
        future.onFailure { _ in
            peripheral.reconnect()
            peripheral.didConnectPeripheral()
        }
        waitForExpectationsWithTimeout(20) { error in
            XCTAssertNil(error, "\(error)")
        }
    }

    // MARK: Read RSSI
    func testReadRSSI_WhenConnected_CompletesSuccessfully() {
        let mockPeripheral = CBPeripheralMock(state: .Connected)
        let peripheral = BCPeripheral(cbPeripheral: mockPeripheral, centralManager: self.centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        let future = peripheral.readRSSI()
        peripheral.didReadRSSI(NSNumber(int: Int32(self.updatedRSSI1)), error: nil)
        XCTAssertFutureSucceeds(future, context: self.immediateContext) { rssi in
            XCTAssertEqual(rssi, self.updatedRSSI1, "RSSI invalid")
            XCTAssertEqual(peripheral.RSSI, self.updatedRSSI1, "RSSI invalid")
        }
    }

    func testReadRSSI_WhenDisconnected_CompletesWithPeripheralDisconnected() {
        let mockPeripheral = CBPeripheralMock(state: .Disconnected)
        let peripheral = BCPeripheral(cbPeripheral: mockPeripheral, centralManager: self.centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        let future = peripheral.readRSSI()
        XCTAssertFutureFails(future, context: self.immediateContext) { error in
            XCTAssertEqual(error.code, BCError.peripheralDisconnected.code, "Error code invalid")
        }
    }

    func testReadRSSI_WhenConnectedAndErrorInResponse_CompletesWithResponseError() {
        let mockPeripheral = CBPeripheralMock(state: .Connected)
        let peripheral = BCPeripheral(cbPeripheral: mockPeripheral, centralManager: self.centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        let future = peripheral.readRSSI()
        peripheral.didReadRSSI(NSNumber(int: Int32(self.updatedRSSI1)), error: TestFailure.error)
        XCTAssertFutureFails(future, context: self.immediateContext) { error in
            XCTAssertEqual(error.code, TestFailure.error.code, "Error code invalid")
        }
    }

    func testStartPollingRSSI_WhenConnectedAndNoErrorInAck_CompletesSuccessfully() {
        let mockPeripheral = CBPeripheralMock(state: .Connected)
        let peripheral = BCPeripheral(cbPeripheral: mockPeripheral, centralManager: self.centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        mockPeripheral.bcPeripheral = peripheral
        let future = peripheral.startPollingRSSI(0.25)
        XCTAssertFutureStreamSucceeds(future, timeout: 120, validations: [
            { rssi in
                XCTAssertEqual(rssi, mockPeripheral.RSSI, "Recieved RSSI invalid")
                XCTAssertEqual(peripheral.RSSI, mockPeripheral.RSSI, "Peripheral RSSI invalid")
                XCTAssertEqual(mockPeripheral.readRSSICalledCount, 1, "readRSSICalled count invalid")
            },
            { rssi in
                XCTAssertEqual(rssi, mockPeripheral.RSSI, "Recieved RSSI invalid")
                XCTAssertEqual(peripheral.RSSI, mockPeripheral.RSSI, "Peripheral RSSI invalid")
                XCTAssertEqual(mockPeripheral.readRSSICalledCount, 2, "readRSSICalled count invalid")
                peripheral.stopPollingRSSI()
            }
        ])
    }

    func testStartPollingRSSI_WhenDisconnected_CompletesWithPeripheralDisconnected() {
        let mockPeripheral = CBPeripheralMock(state: .Disconnected)
        let peripheral = BCPeripheral(cbPeripheral: mockPeripheral, centralManager: self.centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        let future = peripheral.startPollingRSSI()
        XCTAssertFutureStreamFails(future, context:self.immediateContext, validations: [
            { error in
                peripheral.stopPollingRSSI()
                XCTAssertEqual(error.code, BCError.peripheralDisconnected.code, "Error code invalid")
            }
        ])
    }


   func testStartPollingRSSI_WhenDisconnectedAfterStart_CompletesWithPeripheralDisconnected() {
        let mockPeripheral = CBPeripheralMock(state: .Connected)
        let peripheral = BCPeripheral(cbPeripheral: mockPeripheral, centralManager: self.centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        mockPeripheral.bcPeripheral = peripheral
        let expectation = expectationWithDescription("expectation fulfilled for future")
        var completed = false
        let future = peripheral.startPollingRSSI(0.25)
        future.onSuccess { rssi in
            if (!completed) {
                completed = true
                XCTAssertEqual(rssi, mockPeripheral.RSSI, "Recieved RSSI invalid")
                XCTAssertEqual(peripheral.RSSI, mockPeripheral.RSSI, "Peripheral RSSI invalid")
                XCTAssertEqual(mockPeripheral.readRSSICalledCount, 1, "readRSSICalled count invalid")
                peripheral.state = .Disconnected
            } else {
                expectation.fulfill()
                XCTFail("onSuccess called")
            }
        }
        future.onFailure { error in
            expectation.fulfill()
            peripheral.stopPollingRSSI()
            XCTAssertEqual(error.code, BCError.peripheralDisconnected.code, "Error code invalid")
        }
        waitForExpectationsWithTimeout(120) { error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testStartPollingRSSI_WhenConnectedAndErrorInResponse_CompletedWithResponceError() {
        let mockPeripheral = CBPeripheralMock(state: .Connected)
        let peripheral = BCPeripheral(cbPeripheral: mockPeripheral, centralManager: self.centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        let expectation = expectationWithDescription("expectation fulfilled for future")
        let future = peripheral.startPollingRSSI(0.25)
        mockPeripheral.error = TestFailure.error
        mockPeripheral.bcPeripheral = peripheral
        XCTAssertFutureStreamFails(future, validations: [
            { error in
                peripheral.stopPollingRSSI()
                expectation.fulfill()
                XCTAssertEqual(error.code, TestFailure.error.code, "Error code invalid")
            }
        ])
    }

    func testStopPollingRSSI_WhenConnected_StopsRSSIUpdates() {
        let mockPeripheral = CBPeripheralMock(state: .Connected)
        let peripheral = BCPeripheral(cbPeripheral: mockPeripheral, centralManager: self.centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        var count = 0
        let future = peripheral.startPollingRSSI(0.25)
        mockPeripheral.bcPeripheral = peripheral
        future.onSuccess(QueueContext.global) { _ in
            count += 1
            peripheral.stopPollingRSSI()
        }
        future.onFailure(QueueContext.global) { error in
            XCTFail("onFailure called")
        }
        sleep(1)
        XCTAssertEqual(count, 1, "stopPollingRSSI failed")
    }

    func testStopPollingRSSI_WhenDisconnected_StopsRSSIUpdates() {
        let mockPeripheral = CBPeripheralMock(state: .Disconnected)
        let peripheral = BCPeripheral(cbPeripheral: mockPeripheral, centralManager: self.centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        var count = 0
        let future = peripheral.startPollingRSSI(0.25)
        mockPeripheral.bcPeripheral = peripheral
        future.onSuccess(QueueContext.global) { _ in
            XCTFail("onSuccess called")
        }
        future.onFailure(QueueContext.global) { error in
            count += 1
            peripheral.stopPollingRSSI()
        }
        sleep(1)
        XCTAssertEqual(count, 1, "stopPollingRSSI failed")
   }
}
