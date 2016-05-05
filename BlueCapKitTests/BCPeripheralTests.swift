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

    // MARK: Discover Services
    func testDiscoverAllServices_WhenConnectedAndNoErrorInResponse_CompletesSuccessfully() {
        let mockPeripheral = CBPeripheralMock(state: .Connected)
        let peripheral = BCPeripheral(cbPeripheral: mockPeripheral, centralManager: self.centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        let expectation = expectationWithDescription("expectation fulfilled for future")
        let future = peripheral.discoverAllServices()
        future.onSuccess { _ in
            expectation.fulfill()
            let discoveredServices = peripheral.services
            XCTAssertEqual(discoveredServices.count, 2, "Peripheral service count invalid")
            XCTAssertEqual(mockPeripheral.discoverServicesCalledCount, 1, "CBPeripheral#discoverServices called more than once")
            XCTAssert(mockPeripheral.discoverServicesCalled, "CBPeripheral#discoverServices not called")
            XCTAssertFalse(mockPeripheral.discoverCharacteristicsCalled, "CBPeripheral#discoverChracteristics called")
        }
        future.onFailure { error in
            XCTFail("onFailure called")
        }
        peripheral.didDiscoverServices(self.mockServices.map { $0 as CBServiceInjectable }, error:nil)
        waitForExpectationsWithTimeout(2) { error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testDiscoverAllServices_WhenConnectedAndErrorInResponse_CompletesWithResponseError() {
        let mockPeripheral = CBPeripheralMock(state: .Connected)
        let peripheral = BCPeripheral(cbPeripheral: mockPeripheral, centralManager: self.centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        let expectation = expectationWithDescription("expectation fulfilled for future")
        let future = peripheral.discoverAllServices()
        future.onSuccess { _ in
            XCTFail("onSuccess called")
        }
        future.onFailure { error in
            expectation.fulfill()
            XCTAssertEqual(error.code, TestFailure.error.code, "Error code invalid")
            XCTAssertEqual(mockPeripheral.discoverServicesCalledCount, 1, "CBPeripheral#discoverServices called more than once")
            XCTAssert(mockPeripheral.discoverServicesCalled, "CBPeripheral#discoverServices not called")
            XCTAssertFalse(mockPeripheral.discoverCharacteristicsCalled, "CBPeripheral#discoverChracteristics called")
        }
        peripheral.didDiscoverServices([], error: TestFailure.error)
        waitForExpectationsWithTimeout(2) { error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testDiscoverAllServices_WhenDisconnected_CompletesWithPeripheralDisconnected() {
        let mockPeripheral = CBPeripheralMock(state: .Disconnected)
        let peripheral = BCPeripheral(cbPeripheral: mockPeripheral, centralManager: self.centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        let expectation = expectationWithDescription("expectation fulfilled for future")
        let future = peripheral.discoverAllServices()
        future.onSuccess { _ in
            XCTFail("onSuccess called")
        }
        future.onFailure { error in
            expectation.fulfill()
            XCTAssertEqual(error.code, BCError.peripheralDisconnected.code, "Error code invalid")
            XCTAssertEqual(mockPeripheral.discoverServicesCalledCount, 0, "CBPeripheral#discoverServices called more than once")
            XCTAssertFalse(mockPeripheral.discoverServicesCalled, "CBPeripheral#discoverServices called")
            XCTAssertFalse(mockPeripheral.discoverCharacteristicsCalled, "CBPeripheral#discoverChracteristics called")
        }
        waitForExpectationsWithTimeout(2) { error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testDiscoverAllServices_OnTimeout_CompletesWithPeripheralDisconnected() {
    }

    func testDiscoverPeripheralServicesSuccess() {
        let mockPeripheral = CBPeripheralMock(state:.Connected)
        let peripheral = PeripheralUT(cbPeripheral:mockPeripheral, centralManager:self.centralManager, advertisements:peripheralAdvertisements, rssi: self.RSSI, error:nil)
        let expectation = expectationWithDescription("expectation fulfilled for future")
        let future = peripheral.discoverAllPeripheralServices()
        future.onSuccess { _ in
            expectation.fulfill()
            let discoveredServices = peripheral.services
            XCTAssertEqual(discoveredServices.count, 2, "Peripheral service count invalid")
            XCTAssert(mockPeripheral.discoverServicesCalled, "CBPeripheral#discoverServices not called")
        }
        future.onFailure { error in
            XCTFail("onFailure called")
        }
        peripheral.didDiscoverServices(self.mockServices.map { $0 as CBServiceInjectable }, error:nil)
        waitForExpectationsWithTimeout(20) { error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testDiscoverPeripheralServicesPeripheralFailure() {
        let mockPeripheral = CBPeripheralMock(state:.Connected)
        let peripheral = PeripheralUT(cbPeripheral:mockPeripheral, centralManager:self.centralManager, advertisements:peripheralAdvertisements, rssi: self.RSSI, error:TestFailure.error)
        let expectation = expectationWithDescription("expectation fulfilled for future")
        let future = peripheral.discoverAllPeripheralServices()
        future.onSuccess { _ in
            XCTFail("onSuccess called")
        }
        future.onFailure { error in
            expectation.fulfill()
            XCTAssertEqual(error.code, TestFailure.error.code, "Error code invalid")
            XCTAssert(mockPeripheral.discoverServicesCalled, "CBPeripheral#discoverServices not called")
        }
        peripheral.didDiscoverServices(self.mockServices.map { $0 as CBServiceInjectable }, error: TestFailure.error)
        waitForExpectationsWithTimeout(20) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testDiscoverPeripheralServicesServiceFailure() {
        let mockPeripheral = CBPeripheralMock(state: .Connected)
        let peripheral = PeripheralUT(cbPeripheral:mockPeripheral, centralManager:self.centralManager, advertisements:peripheralAdvertisements, rssi: self.RSSI, error:TestFailure.error)
        let expectation = expectationWithDescription("expectation fulfilled for future")
        let future = peripheral.discoverAllPeripheralServices()
        future.onSuccess { _ in
            XCTFail("onSuccess called")
        }
        future.onFailure {error in
            expectation.fulfill()
            XCTAssertEqual(error.code, TestFailure.error.code, "Error code invalid")
            XCTAssert(mockPeripheral.discoverServicesCalled, "CBPeripheral#discoverServices not called")
        }
        peripheral.didDiscoverServices(self.mockServices.map { $0 as CBServiceInjectable }, error:nil)
        waitForExpectationsWithTimeout(20) { error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testDiscoverPeripheralServicesNoServicesFoundFailure() {
        let mockPeripheral = CBPeripheralMock(state: .Connected)
        let peripheral = BCPeripheral(cbPeripheral: mockPeripheral, centralManager: self.centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        let expectation = expectationWithDescription("expectation fulfilled for future")
        let future = peripheral.discoverAllPeripheralServices()
        future.onSuccess { _ in
            XCTFail("onSuccess called")
        }
        future.onFailure {error in
            expectation.fulfill()
            XCTAssertEqual(error.domain, BCError.domain, "message domain invalid")
            XCTAssertEqual(error.code, BCPeripheralErrorCode.NoServices.rawValue, "message code invalid")
        }
        peripheral.didDiscoverServices([], error:nil)
        waitForExpectationsWithTimeout(20) { error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testDiscoverServiceSuccess() {
        let mockPeripheral = CBPeripheralMock(state:.Connected)
        let peripheral = BCPeripheral(cbPeripheral: mockPeripheral, centralManager: self.centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        let expectation = expectationWithDescription("expectation fulfilled for future")
        let bcServices = [ServiceUT(cbService: self.mockServices[0], peripheral: peripheral, mockCharacteristics: [self.mockCharateristics[0]], error: nil),
                          ServiceUT(cbService: self.mockServices[1], peripheral: peripheral, mockCharacteristics: [self.mockCharateristics[1], self.mockCharateristics[2]], error: nil)]
        let promise = Promise<BCPeripheral>()
        promise.future.onSuccess { _ in
            expectation.fulfill()
        }
        promise.future.onFailure { error in
            XCTFail("onFailure called")
        }
        peripheral.discoverService(bcServices[0], tail:[bcServices[1]], promise:promise)
        waitForExpectationsWithTimeout(20) { error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func testDiscoverServiceFailure() {
        let mockPeripheral = CBPeripheralMock(state:.Connected)
        let peripheral = BCPeripheral(cbPeripheral: mockPeripheral, centralManager: self.centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        let expectation = expectationWithDescription("expectation fulfilled for future")
        let bcServices = [ServiceUT(cbService: self.mockServices[0], peripheral: peripheral, mockCharacteristics: [self.mockCharateristics[0]], error: TestFailure.error),
                          ServiceUT(cbService: self.mockServices[1], peripheral: peripheral, mockCharacteristics: [self.mockCharateristics[1], self.mockCharateristics[2]], error: nil)]
        let promise = Promise<BCPeripheral>()
        promise.future.onSuccess { _ in
            XCTFail("onSuccess called")
        }
        promise.future.onFailure { error in
            expectation.fulfill()
        }
        peripheral.discoverService(bcServices[0], tail: [bcServices[1]], promise: promise)
        waitForExpectationsWithTimeout(20) { error in
            XCTAssertNil(error, "\(error)")
        }
    }

    // MARK: Connection
    func testConnect() {
        let mockPeripheral = CBPeripheralMock(state:.Disconnected)
        let peripheral = BCPeripheral(cbPeripheral: mockPeripheral, centralManager: self.centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        NSLog("testConnect : %@", peripheral.identifier.UUIDString)
        let expectation = expectationWithDescription("expectation fulfilled for future")
        let future = peripheral.connect(connectionTimeout: 60.0)
        future.onSuccess { (peripheral, connectionEvent) in
            switch connectionEvent {
            case .Connect:
                expectation.fulfill()
            case .Timeout:
                XCTFail("onSuccess Timeout invalid")
            case .Disconnect:
                XCTFail("onSuccess Disconnect invalid")
            case .ForceDisconnect:
                XCTFail("onSuccess ForceDisconnect invalid")
            case .GiveUp:
                XCTFail("onSuccess GiveUp invalid")
            }
            XCTAssert(self.centralManagerMock.connectPeripheralCalled, "CentralManager#connectPeripheralCalled not called")
        }
        future.onFailure { error in
            XCTFail("onFailure called")
        }
        peripheral.didConnectPeripheral()
        waitForExpectationsWithTimeout(120) { error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func testFailedConnectWithError() {
        let mockPeripheral = CBPeripheralMock(state: .Disconnected)
        let peripheral = BCPeripheral(cbPeripheral: mockPeripheral, centralManager: self.centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        NSLog("testFailedConnectWithError : %@", peripheral.identifier.UUIDString)
        let expectation = expectationWithDescription("expectation fulfilled for future")
        let future = peripheral.connect(connectionTimeout: 60.0)
        future.onSuccess { (peripheral, connectionEvent) in
            switch connectionEvent {
            case .Connect:
                XCTFail("onSuccess Connect invalid")
            case .Timeout:
                XCTFail("onSuccess Timeout invalid")
            case .Disconnect:
                XCTFail("onSuccess Disconnect invalid")
            case .ForceDisconnect:
                XCTFail("onSuccess ForceDisconnect invalid")
            case .GiveUp:
                XCTFail("onSuccess GiveUp invalid")
            }
            XCTAssert(self.centralManagerMock.connectPeripheralCalled, "CentralManager#connectPeripheralCalled not called")
        }
        future.onFailure { error in
            expectation.fulfill()
            XCTAssert(error.code == TestFailure.error.code, "Error code invalid")
        }
        peripheral.didFailToConnectPeripheral(TestFailure.error)
        waitForExpectationsWithTimeout(120) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testForcedDisconnectWhenDisconnected() {
        let mockPeripheral = CBPeripheralMock(state: .Disconnected)
        let peripheral = BCPeripheral(cbPeripheral: mockPeripheral, centralManager: self.centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        NSLog("testForcedDisconnectWhenDisconnected : %@", peripheral.identifier.UUIDString)
        let expectation = expectationWithDescription("expectation fulfilled for future")
        let future = peripheral.connect(connectionTimeout: 50.0)
        future.onSuccess { (peripheral, connectionEvent) in
            switch connectionEvent {
            case .Connect:
                XCTFail("onSuccess Connect invalid")
            case .Timeout:
                XCTFail("onSuccess Timeout invalid")
            case .Disconnect:
                XCTFail("onSuccess Disconnect invalid")
            case .ForceDisconnect:
                XCTFail("onSuccess ForceDisconnect invalid")
            case .GiveUp:
                XCTFail("onSuccess GiveUp invalid")
            }
            XCTAssert(self.centralManagerMock.connectPeripheralCalled, "CentralManager#connectPeripheralCalled not called")
        }
        future.onFailure { error in
            XCTAssertEqual(error.code, BCError.peripheralDisconnected.code, "Error code invalid")
            expectation.fulfill()
        }
        peripheral.disconnect()
        waitForExpectationsWithTimeout(120) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func testForcedDisconnectWhenConnected() {
        let mockPeripheral = CBPeripheralMock(state:.Connected)
        let peripheral = BCPeripheral(cbPeripheral: mockPeripheral, centralManager: self.centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        NSLog("testForcedDisconnectWhenConnected : %@", peripheral.identifier.UUIDString)
        let expectation = expectationWithDescription("expectation fulfilled for future")
        let future = peripheral.connect(connectionTimeout:50.0)
        future.onSuccess { (peripheral, connectionEvent) in
            switch connectionEvent {
            case .Connect:
                XCTFail("onSuccess Connect invalid")
            case .Timeout:
                XCTFail("onSuccess Timeout invalid")
            case .Disconnect:
                XCTFail("onSuccess Disconnect invalid")
            case .ForceDisconnect:
                expectation.fulfill()
            case .GiveUp:
                XCTFail("onSuccess GiveUp invalid")
            }
            XCTAssertFalse(self.centralManagerMock.connectPeripheralCalled, "CentralManager#connectPeripheralCalled not called")
        }
        future.onFailure { error in
            XCTFail("onFailure called")
        }
        peripheral.disconnect()
        waitForExpectationsWithTimeout(120) { error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testDisconnect() {
        let mockPeripheral = CBPeripheralMock(state: .Connected)
        let peripheral = BCPeripheral(cbPeripheral: mockPeripheral, centralManager: self.centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        NSLog("testDisconnect : %@", peripheral.identifier.UUIDString)
        let expectation = expectationWithDescription("expectation fulfilled for future")
        let future = peripheral.connect(connectionTimeout: 1.0)
        future.onSuccess { (peripheral, connectionEvent) in
            switch connectionEvent {
            case .Connect:
                XCTFail("onSuccess Connect invalid")
            case .Timeout:
                XCTFail("onSuccess Timeout invalid")
            case .Disconnect:
                expectation.fulfill()
            case .ForceDisconnect:
                XCTFail("onSuccess ForceDisconnect invalid")
            case .GiveUp:
                XCTFail("onSuccess GiveUp invalid")
            }
            XCTAssertFalse(self.centralManagerMock.connectPeripheralCalled, "CentralManager#connectPeripheralCalled not called")
        }
        future.onFailure { error in
            XCTFail("onFailure called")
        }
        peripheral.didDisconnectPeripheral(nil)
        waitForExpectationsWithTimeout(120) { error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func testTimeout() {
        let mockPeripheral = CBPeripheralMock(state:.Disconnected)
        let peripheral = BCPeripheral(cbPeripheral: mockPeripheral, centralManager: self.centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        NSLog("testTimeout : %@", peripheral.identifier.UUIDString)
        let expectation = expectationWithDescription("expectation fulfilled for future")
        let future = peripheral.connect(connectionTimeout: 1.0)
        future.onSuccess { (peripheral, connectionEvent) in
            switch connectionEvent {
            case .Connect:
                XCTFail("onSuccess Connect invalid")
            case .Timeout:
                expectation.fulfill()
            case .Disconnect:
                XCTFail("onSuccess Disconnect invalid")
            case .ForceDisconnect:
                XCTFail("onSuccess ForceDisconnect invalid")
            case .GiveUp:
                XCTFail("onSuccess GiveUp invalid")
            }
            XCTAssert(self.centralManagerMock.connectPeripheralCalled, "CentralManager#connectPeripheralCalled not called")
        }
        future.onFailure { error in
            XCTFail("onFailure called")
        }
        waitForExpectationsWithTimeout(20) { error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func testGiveUp() {
        let mockPeripheral = CBPeripheralMock(state:.Disconnected)
        let peripheral = BCPeripheral(cbPeripheral: mockPeripheral, centralManager: self.centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        NSLog("testGiveUp : %@", peripheral.identifier.UUIDString)
        let expectation1 = expectationWithDescription("expectation fulfilled for future")
        let expectation2 = expectationWithDescription("expectation fulfilled for future")
        let future = peripheral.connect(connectionTimeout: 1.0, timeoutRetries: 1)
        future.onSuccess { (peripheral, connectionEvent) in
            switch connectionEvent {
            case .Connect:
                XCTFail("onSuccess Connect invalid")
            case .Timeout:
                expectation1.fulfill()
                peripheral.reconnect()
            case .Disconnect:
                XCTFail("onSuccess Disconnect invalid")
            case .ForceDisconnect:
                XCTFail("onSuccess ForceDisconnect invalid")
            case .GiveUp:
                expectation2.fulfill()
            }
            XCTAssert(self.centralManagerMock.connectPeripheralCalled, "CentralManager#connectPeripheralCalled not called")
        }
        future.onFailure { error in
            XCTFail("onFailure called")
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
        future.onSuccess(self.immediateContext) { rssi in
            XCTAssertEqual(rssi, self.updatedRSSI1, "RSSI invalid")
            XCTAssertEqual(peripheral.RSSI, self.updatedRSSI1, "RSSI invalid")
        }
        future.onFailure(self.immediateContext) { error in
            XCTFail("onFailure called")
        }
        peripheral.didReadRSSI(NSNumber(int: Int32(self.updatedRSSI1)), error: nil)
    }

    func testReadRSSI_WhenDisconnected_CompletesWithPeripheralDisconnected() {
        let mockPeripheral = CBPeripheralMock(state: .Disconnected)
        let peripheral = BCPeripheral(cbPeripheral: mockPeripheral, centralManager: self.centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        let future = peripheral.readRSSI()
        future.onSuccess(self.immediateContext) { rssi in
            XCTFail("onSuccess called")
        }
        future.onFailure(self.immediateContext) { error in
            XCTAssertEqual(error.code, BCError.peripheralDisconnected.code, "Error code invalid")
        }
    }

    func testReadRSSI_WhenConnectedAndErrorInResponse_CompletesWithResponseError() {
        let mockPeripheral = CBPeripheralMock(state: .Connected)
        let peripheral = BCPeripheral(cbPeripheral: mockPeripheral, centralManager: self.centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        let future = peripheral.readRSSI()
        future.onSuccess(self.immediateContext) { rssi in
            XCTFail("onSuccess called")
        }
        future.onFailure(self.immediateContext) { error in
            XCTAssertEqual(error.code, TestFailure.error.code, "Error code invalid")
        }
        peripheral.didReadRSSI(NSNumber(int: Int32(self.updatedRSSI1)), error: TestFailure.error)
    }

    func testStartPollingRSSI_WhenConnectedAndNoErrorInAck_CompletesSuccessfully() {
        let mockPeripheral = CBPeripheralMock(state: .Connected)
        let peripheral = BCPeripheral(cbPeripheral: mockPeripheral, centralManager: self.centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        mockPeripheral.bcPeripheral = peripheral
        let expectation = expectationWithDescription("expectation fulfilled for future")
        var count = 0
        let future = peripheral.startPollingRSSI(1.0)
        future.onSuccess { rssi in
            switch count {
            case 0:
                XCTAssertEqual(rssi, mockPeripheral.RSSI, "Recieved RSSI invalid")
                XCTAssertEqual(peripheral.RSSI, mockPeripheral.RSSI, "Peripheral RSSI invalid")
                XCTAssertEqual(mockPeripheral.readRSSICalledCount, 1, "readRSSICalled count invalid")
            case 1:
                XCTAssertEqual(rssi, mockPeripheral.RSSI, "Recieved RSSI invalid")
                XCTAssertEqual(peripheral.RSSI, mockPeripheral.RSSI, "Peripheral RSSI invalid")
                XCTAssertEqual(mockPeripheral.readRSSICalledCount, 2, "readRSSICalled count invalid")
                peripheral.stopPollingRSSI()
                expectation.fulfill()
            default:
                XCTFail("onSuccess called too many times")
            }
            count += 1
        }
        future.onFailure { error in
            expectation.fulfill()
            XCTFail("onFailure called")
        }
        waitForExpectationsWithTimeout(120) { error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testStartPollingRSSI_WhenDisconnected_CompletesWithPeripheralDisconnected() {
        let mockPeripheral = CBPeripheralMock(state: .Disconnected)
        let peripheral = BCPeripheral(cbPeripheral: mockPeripheral, centralManager: self.centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        let future = peripheral.startPollingRSSI()
        future.onSuccess(self.immediateContext) { rssi in
            XCTFail("onSuccess called")
        }
        future.onFailure(self.immediateContext) { error in
            peripheral.stopPollingRSSI()
            XCTAssertEqual(error.code, BCError.peripheralDisconnected.code, "Error code invalid")
        }
    }


   func testStartPollingRSSI_WhenDisconnectedAfterStart_CompletesSuccessfully() {
        let mockPeripheral = CBPeripheralMock(state: .Connected)
        let peripheral = BCPeripheral(cbPeripheral: mockPeripheral, centralManager: self.centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        mockPeripheral.bcPeripheral = peripheral
        let expectation = expectationWithDescription("expectation fulfilled for future")
        var completed = false
        let future = peripheral.startPollingRSSI(1.0)
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

    func testConnectedPollRSSIFailure() {
        let mockPeripheral = CBPeripheralMock(state: .Connected)
        let peripheral = BCPeripheral(cbPeripheral: mockPeripheral, centralManager: self.centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        let expectation = expectationWithDescription("expectation fulfilled for future")
        let future = peripheral.startPollingRSSI()
        future.onSuccess { rssi in
            expectation.fulfill()
            XCTFail("onSuccess called")
        }
        future.onFailure { error in
            expectation.fulfill()
            XCTAssertEqual(error.code, TestFailure.error.code, "Error code invalid")
        }
        peripheral.didReadRSSI(NSNumber(int: Int32(self.updatedRSSI2)), error: TestFailure.error)
        waitForExpectationsWithTimeout(20) { error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testStopPollingRSSI() {
        let mockPeripheral = CBPeripheralMock(state: .Connected)
        let peripheral = BCPeripheral(cbPeripheral: mockPeripheral, centralManager: self.centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        let expectation = expectationWithDescription("expectation fulfilled for future")
        var count = 0
        let future = peripheral.startPollingRSSI()
        future.onSuccess { rssi in
            XCTAssertEqual(0, count, "onSuccess called too many times")
            XCTAssertEqual(rssi, self.updatedRSSI1, "RSSI invalid")
            XCTAssertEqual(peripheral.RSSI, self.updatedRSSI1, "RSSI invalid")
            expectation.fulfill()
            peripheral.stopPollingRSSI()
            peripheral.didReadRSSI(NSNumber(int: Int32(self.updatedRSSI2)), error: nil)
            count += 1
        }
        future.onFailure { error in
            XCTFail("onFailure called")
        }
        peripheral.didReadRSSI(NSNumber(int: Int32(self.updatedRSSI1)), error: nil)
        waitForExpectationsWithTimeout(20) { error in
            XCTAssertNil(error, "\(error)")
        }
    }

}
