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

    var centralManager = CentralManagerUT(centralManager: CBCentralManagerMock(state: .PoweredOn))
    let mockServices = [CBServiceMock(UUID:CBUUID(string:"2f0a0017-69aa-f316-3e78-4194989a6ccc")),
                               CBServiceMock(UUID:CBUUID(string:"2f0a0017-69aa-f316-3e78-4194989a6fff"))]

    var mockCharateristics = [CBCharacteristicMock(UUID:CBUUID(string:"2f0a0017-69aa-f316-3e78-4194989a6111"), properties:[.Read, .Write],
                                                   permissions:[.Readable, .Writeable], isNotifying:false),
                              CBCharacteristicMock(UUID:CBUUID(string:"2f0a0017-69aa-f316-3e78-4194989a6222"), properties:[.Read, .Write],
                                                   permissions:[.Readable, .Writeable], isNotifying:false),
                              CBCharacteristicMock(UUID:CBUUID(string:"2f0a0017-69aa-f316-3e78-4194989a6333"), properties:[.Read, .Write],
                                                   permissions:[.Readable, .Writeable], isNotifying:false)
    ]
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }

    // MARK: Discover Services
    func testDiscoverServicesSuccess() {
        let mockPeripheral = CBPeripheralMock(state: .Connected)
        let peripheral = BCPeripheral(cbPeripheral: mockPeripheral, centralManager: self.centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        let onSuccessExpectation = expectationWithDescription("onSuccess fulfilled for future")
        let future = peripheral.discoverAllServices()
        future.onSuccess { _ in
            onSuccessExpectation.fulfill()
            let discoveredServices = peripheral.services
            XCTAssertEqual(discoveredServices.count, 2, "Peripheral service count invalid")
            XCTAssertEqual(mockPeripheral.discoverServicesCalledCount, 1, "CBPeripheral#discoverServices called more than once")
            XCTAssert(mockPeripheral.discoverServicesCalled, "CBPeripheral#discoverServices not called")
            XCTAssertFalse(mockPeripheral.discoverCharacteristicsCalled, "CBPeripheral#discoverChracteristics called")
        }
        future.onFailure { error in
            XCTAssert(false, "onFailure called")
        }
        peripheral.didDiscoverServices(self.mockServices, error:nil)
        waitForExpectationsWithTimeout(2) { error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testDiscoverServicesCoreBluetoothFailure() {
        let mockPeripheral = CBPeripheralMock(state: .Connected)
        let peripheral = BCPeripheral(cbPeripheral: mockPeripheral, centralManager: self.centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        let onFailureExpectation = expectationWithDescription("onFailure fulfilled for future")
        let future = peripheral.discoverAllServices()
        future.onSuccess { _ in
            XCTAssert(false, "onSuccess called")
        }
        future.onFailure { error in
            onFailureExpectation.fulfill()
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

    func testDiscoverServicesDisconnectedFailure() {
        let mockPeripheral = CBPeripheralMock(state: .Disconnected)
        let peripheral = BCPeripheral(cbPeripheral: mockPeripheral, centralManager: self.centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        let onFailureExpectation = expectationWithDescription("onFailure fulfilled for future")
        let future = peripheral.discoverAllServices()
        future.onSuccess { _ in
            XCTAssert(false, "onSuccess called")
        }
        future.onFailure { error in
            onFailureExpectation.fulfill()
            XCTAssertEqual(error.code, BCError.peripheralDisconnected.code, "Error code invalid")
            XCTAssertEqual(mockPeripheral.discoverServicesCalledCount, 0, "CBPeripheral#discoverServices called more than once")
            XCTAssertFalse(mockPeripheral.discoverServicesCalled, "CBPeripheral#discoverServices called")
            XCTAssertFalse(mockPeripheral.discoverCharacteristicsCalled, "CBPeripheral#discoverChracteristics called")
        }
        waitForExpectationsWithTimeout(2) { error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testDiscoverPeripheralServicesSuccess() {
        let mockPeripheral = CBPeripheralMock(state:.Connected)
        let peripheral = PeripheralUT(cbPeripheral:mockPeripheral, centralManager:self.centralManager, advertisements:peripheralAdvertisements, rssi: self.RSSI, error:nil)
        let onSuccessExpectation = expectationWithDescription("onSuccess fulfilled for future")
        let future = peripheral.discoverAllPeripheralServices()
        future.onSuccess { _ in
            onSuccessExpectation.fulfill()
            let discoveredServices = peripheral.services
            XCTAssertEqual(discoveredServices.count, 2, "Peripheral service count invalid")
            XCTAssert(mockPeripheral.discoverServicesCalled, "CBPeripheral#discoverServices not called")
        }
        future.onFailure { error in
            XCTAssert(false, "onFailure called")
        }
        peripheral.didDiscoverServices(self.mockServices, error:nil)
        waitForExpectationsWithTimeout(20) { error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testDiscoverPeripheralServicesPeripheralFailure() {
        let mockPeripheral = CBPeripheralMock(state:.Connected)
        let peripheral = PeripheralUT(cbPeripheral:mockPeripheral, centralManager:self.centralManager, advertisements:peripheralAdvertisements, rssi: self.RSSI, error:TestFailure.error)
        let onFailureExpectation = expectationWithDescription("onFailure fulfilled for future")
        let future = peripheral.discoverAllPeripheralServices()
        future.onSuccess { _ in
            XCTAssert(false, "onSuccess called")
        }
        future.onFailure { error in
            onFailureExpectation.fulfill()
            XCTAssertEqual(error.code, TestFailure.error.code, "Error code invalid")
            XCTAssert(mockPeripheral.discoverServicesCalled, "CBPeripheral#discoverServices not called")
        }
        peripheral.didDiscoverServices(self.mockServices, error: TestFailure.error)
        waitForExpectationsWithTimeout(20) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testDiscoverPeripheralServicesServiceFailure() {
        let mockPeripheral = CBPeripheralMock(state: .Connected)
        let peripheral = PeripheralUT(cbPeripheral:mockPeripheral, centralManager:self.centralManager, advertisements:peripheralAdvertisements, rssi: self.RSSI, error:TestFailure.error)
        let onFailureExpectation = expectationWithDescription("onFailure fulfilled for future")
        let future = peripheral.discoverAllPeripheralServices()
        future.onSuccess { _ in
            XCTAssert(false, "onSuccess called")
        }
        future.onFailure {error in
            onFailureExpectation.fulfill()
            XCTAssertEqual(error.code, TestFailure.error.code, "Error code invalid")
            XCTAssert(mockPeripheral.discoverServicesCalled, "CBPeripheral#discoverServices not called")
        }
        peripheral.didDiscoverServices(self.mockServices, error:nil)
        waitForExpectationsWithTimeout(20) { error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testDiscoverPeripheralServicesNoServicesFoundFailure() {
        let mockPeripheral = CBPeripheralMock(state: .Connected)
        let peripheral = BCPeripheral(cbPeripheral: mockPeripheral, centralManager: self.centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        let onFailureExpectation = expectationWithDescription("onFailure fulfilled for future")
        let future = peripheral.discoverAllPeripheralServices()
        future.onSuccess { _ in
            XCTAssert(false, "onSuccess called")
        }
        future.onFailure {error in
            onFailureExpectation.fulfill()
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
        let onSuccessExpectation = expectationWithDescription("onSuccess fulfilled for future")
        let bcServices = [ServiceUT(cbService: self.mockServices[0], peripheral: peripheral, mockCharacteristics: [self.mockCharateristics[0]], error: nil),
                          ServiceUT(cbService: self.mockServices[1], peripheral: peripheral, mockCharacteristics: [self.mockCharateristics[1], self.mockCharateristics[2]], error: nil)]
        let promise = Promise<BCPeripheral>()
        promise.future.onSuccess { _ in
            onSuccessExpectation.fulfill()
        }
        promise.future.onFailure { error in
            XCTAssert(false, "onFailure called")
        }
        peripheral.discoverService(bcServices[0], tail:[bcServices[1]], promise:promise)
        waitForExpectationsWithTimeout(20) { error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func testDiscoverServiceFailure() {
        let mockPeripheral = CBPeripheralMock(state:.Connected)
        let peripheral = BCPeripheral(cbPeripheral: mockPeripheral, centralManager: self.centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        let onFailureExpectation = expectationWithDescription("onFailure fulfilled for future")
        let bcServices = [ServiceUT(cbService: self.mockServices[0], peripheral: peripheral, mockCharacteristics: [self.mockCharateristics[0]], error: TestFailure.error),
                          ServiceUT(cbService: self.mockServices[1], peripheral: peripheral, mockCharacteristics: [self.mockCharateristics[1], self.mockCharateristics[2]], error: nil)]
        let promise = Promise<BCPeripheral>()
        promise.future.onSuccess { _ in
            XCTAssert(false, "onSuccess called")
        }
        promise.future.onFailure { error in
            onFailureExpectation.fulfill()
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
        let connectionExpectation = expectationWithDescription("onSuccess fulfilled for Connect")
        let future = peripheral.connect(connectionTimeout: 20.0)
        future.onSuccess { (peripheral, connectionEvent) in
            switch connectionEvent {
            case .Connect:
                connectionExpectation.fulfill()
            case .Timeout:
                XCTAssert(false, "onSuccess Timeout invalid")
            case .Disconnect:
                XCTAssert(false, "onSuccess Disconnect invalid")
            case .ForceDisconnect:
                XCTAssert(false, "onSuccess ForceDisconnect invalid")
            case .GiveUp:
                XCTAssert(false, "onSuccess GiveUp invalid")
            }
            XCTAssert(self.centralManager.connectPeripheralCalled, "CentralManager#connectPeripheralCalled not called")
        }
        future.onFailure { error in
            XCTAssert(false, "onFailure called")
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
        let onFailureExpectation = expectationWithDescription("onFailure fulfilled for future")
        let future = peripheral.connect(connectionTimeout: 20.0)
        future.onSuccess { (peripheral, connectionEvent) in
            switch connectionEvent {
            case .Connect:
                XCTAssert(false, "onSuccess Connect invalid")
            case .Timeout:
                XCTAssert(false, "onSuccess Timeout invalid")
            case .Disconnect:
                XCTAssert(false, "onSuccess Disconnect invalid")
            case .ForceDisconnect:
                XCTAssert(false, "onSuccess ForceDisconnect invalid")
            case .GiveUp:
                XCTAssert(false, "onSuccess GiveUp invalid")
            }
            XCTAssert(self.centralManager.connectPeripheralCalled, "CentralManager#connectPeripheralCalled not called")
        }
        future.onFailure { error in
            onFailureExpectation.fulfill()
            XCTAssert(error.code == TestFailure.error.code, "Error code invalid")
        }
        peripheral.didFailToConnectPeripheral(TestFailure.error)
        waitForExpectationsWithTimeout(20) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testForcedDisconnectWhenDisconnected() {
        let mockPeripheral = CBPeripheralMock(state: .Disconnected)
        let peripheral = BCPeripheral(cbPeripheral: mockPeripheral, centralManager: self.centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        NSLog("testForcedDisconnectWhenDisconnected : %@", peripheral.identifier.UUIDString)
        let forcedDisconnectExpectation = expectationWithDescription("onSuccess fulfilled for ForceDisconnect")
        let future = peripheral.connect(connectionTimeout: 50.0)
        future.onSuccess { (peripheral, connectionEvent) in
            switch connectionEvent {
            case .Connect:
                XCTAssert(false, "onSuccess Connect invalid")
            case .Timeout:
                XCTAssert(false, "onSuccess Timeout invalid")
            case .Disconnect:
                XCTAssert(false, "onSuccess Disconnect invalid")
            case .ForceDisconnect:
                XCTAssert(false, "onSuccess ForceDisconnect invalid")
            case .GiveUp:
                XCTAssert(false, "onSuccess GiveUp invalid")
            }
            XCTAssert(self.centralManager.connectPeripheralCalled, "CentralManager#connectPeripheralCalled not called")
        }
        future.onFailure { error in
            XCTAssertEqual(error.code, BCError.peripheralDisconnected.code, "Error code invalid")
            forcedDisconnectExpectation.fulfill()
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
        let forcedDisconnectExpectation = expectationWithDescription("onSuccess fulfilled for ForceDisconnect")
        let future = peripheral.connect(connectionTimeout:50.0)
        future.onSuccess { (peripheral, connectionEvent) in
            switch connectionEvent {
            case .Connect:
                XCTAssert(false, "onSuccess Connect invalid")
            case .Timeout:
                XCTAssert(false, "onSuccess Timeout invalid")
            case .Disconnect:
                XCTAssert(false, "onSuccess Disconnect invalid")
            case .ForceDisconnect:
                forcedDisconnectExpectation.fulfill()
            case .GiveUp:
                XCTAssert(false, "onSuccess GiveUp invalid")
            }
            XCTAssertFalse(self.centralManager.connectPeripheralCalled, "CentralManager#connectPeripheralCalled not called")
        }
        future.onFailure { error in
            XCTAssert(false, "onFailure called")
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
        let disconnectExpectation = expectationWithDescription("onSuccess fulfilled for Disconnect")
        let future = peripheral.connect(connectionTimeout: 1.0)
        future.onSuccess { (peripheral, connectionEvent) in
            switch connectionEvent {
            case .Connect:
                XCTAssert(false, "onSuccess Connect invalid")
            case .Timeout:
                XCTAssert(false, "onSuccess Timeout invalid")
            case .Disconnect:
                disconnectExpectation.fulfill()
            case .ForceDisconnect:
                XCTAssert(false, "onSuccess ForceDisconnect invalid")
            case .GiveUp:
                XCTAssert(false, "onSuccess GiveUp invalid")
            }
            XCTAssertFalse(self.centralManager.connectPeripheralCalled, "CentralManager#connectPeripheralCalled not called")
        }
        future.onFailure { error in
            XCTAssert(false, "onFailure called")
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
        let timeoutExpectation = expectationWithDescription("onSuccess fulfilled for Timeout")
        let future = peripheral.connect(connectionTimeout: 1.0)
        future.onSuccess { (peripheral, connectionEvent) in
            switch connectionEvent {
            case .Connect:
                XCTAssert(false, "onSuccess Connect invalid")
            case .Timeout:
                timeoutExpectation.fulfill()
            case .Disconnect:
                XCTAssert(false, "onSuccess Disconnect invalid")
            case .ForceDisconnect:
                XCTAssert(false, "onSuccess ForceDisconnect invalid")
            case .GiveUp:
                XCTAssert(false, "onSuccess GiveUp invalid")
            }
            XCTAssert(self.centralManager.connectPeripheralCalled, "CentralManager#connectPeripheralCalled not called")
        }
        future.onFailure { error in
            XCTAssert(false, "onFailure called")
        }
        waitForExpectationsWithTimeout(20) { error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func testGiveUp() {
        let mockPeripheral = CBPeripheralMock(state:.Disconnected)
        let peripheral = BCPeripheral(cbPeripheral: mockPeripheral, centralManager: self.centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        NSLog("testGiveUp : %@", peripheral.identifier.UUIDString)
        let timeoutExpectation = expectationWithDescription("onSuccess fulfilled for Timeout")
        let giveUpExpectation = expectationWithDescription("onSuccess fulfilled for GiveUp")
        let future = peripheral.connect(connectionTimeout: 1.0, timeoutRetries: 1)
        future.onSuccess { (peripheral, connectionEvent) in
            switch connectionEvent {
            case .Connect:
                XCTAssert(false, "onSuccess Connect invalid")
            case .Timeout:
                timeoutExpectation.fulfill()
                peripheral.reconnect()
            case .Disconnect:
                XCTAssert(false, "onSuccess Disconnect invalid")
            case .ForceDisconnect:
                XCTAssert(false, "onSuccess ForceDisconnect invalid")
            case .GiveUp:
                giveUpExpectation.fulfill()
            }
            XCTAssert(self.centralManager.connectPeripheralCalled, "CentralManager#connectPeripheralCalled not called")
        }
        future.onFailure { error in
            XCTAssert(false, "onFailure called")
        }
        waitForExpectationsWithTimeout(20) { error in
            XCTAssertNil(error, "\(error)")
        }
    }

    // MARK: Read RSSI
    func testConnectedReadRSSISuccess() {
        let mockPeripheral = CBPeripheralMock(state: .Connected)
        let peripheral = BCPeripheral(cbPeripheral: mockPeripheral, centralManager: self.centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        let expectation = expectationWithDescription("onSuccess fulfilled")
        let future = peripheral.readRSSI()
        future.onSuccess { rssi in
            XCTAssertEqual(rssi, self.updatedRSSI1, "RSSI invalid")
            XCTAssertEqual(peripheral.RSSI, self.updatedRSSI1, "RSSI invalid")
            expectation.fulfill()
        }
        future.onFailure { error in
            XCTAssert(false, "onFailure called")
        }
        peripheral.didReadRSSI(NSNumber(int: Int32(self.updatedRSSI1)), error: nil)
        waitForExpectationsWithTimeout(20) { error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testDisconnectedReadRSSIFailure() {
        let mockPeripheral = CBPeripheralMock(state: .Disconnected)
        let peripheral = BCPeripheral(cbPeripheral: mockPeripheral, centralManager: self.centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        let expectation = expectationWithDescription("onFailure fullfilled")
        let future = peripheral.readRSSI()
        future.onSuccess { rssi in
            XCTAssert(false, "onSuccess called")
        }
        future.onFailure { error in
            XCTAssertEqual(error.code, BCError.peripheralDisconnected.code, "Error code invalid")
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(20) { error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testConnectedReadRSSIFailure() {
        let mockPeripheral = CBPeripheralMock(state: .Connected)
        let peripheral = BCPeripheral(cbPeripheral: mockPeripheral, centralManager: self.centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        let expectation = expectationWithDescription("onFailure fullfilled")
        let future = peripheral.readRSSI()
        future.onSuccess { rssi in
            XCTAssert(false, "onSuccess called")
        }
        future.onFailure { error in
            XCTAssertEqual(error.code, TestFailure.error.code, "Error code invalid")
            expectation.fulfill()
        }
        peripheral.didReadRSSI(NSNumber(int: Int32(self.updatedRSSI1)), error: TestFailure.error)
        waitForExpectationsWithTimeout(20) { error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testDisconnectedPollRSSISuccess() {
        let mockPeripheral = CBPeripheralMock(state: .Disconnected)
        let peripheral = BCPeripheral(cbPeripheral: mockPeripheral, centralManager: self.centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        let expectation1 = expectationWithDescription("First onSuccess fulfilled")
        let expectation2 = expectationWithDescription("Second onSuccess fulfilled")
        var count = 0
        let future = peripheral.startPollingRSSI()
        future.onSuccess { rssi in
            switch count {
            case 0:
                XCTAssertEqual(rssi, self.updatedRSSI1, "RSSI invalid")
                XCTAssertEqual(peripheral.RSSI, self.updatedRSSI1, "RSSI invalid")
                expectation1.fulfill()
                peripheral.didReadRSSI(NSNumber(int: Int32(self.updatedRSSI2)), error: nil)
            case 1:
                XCTAssertEqual(rssi, self.updatedRSSI2, "RSSI invalid")
                XCTAssertEqual(peripheral.RSSI, self.updatedRSSI2, "RSSI invalid")
                expectation2.fulfill()
            default:
                XCTAssert(false, "onSuccess called too many times")
            }
            count += 1
        }
        future.onFailure { error in
            XCTAssert(false, "onFailure called")
        }
        peripheral.didReadRSSI(NSNumber(int: Int32(self.updatedRSSI1)), error: nil)
        waitForExpectationsWithTimeout(20) { error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testConnectedPollRSSISuccess() {
        let mockPeripheral = CBPeripheralMock(state: .Connected)
        let peripheral = BCPeripheral(cbPeripheral: mockPeripheral, centralManager: self.centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        let expectation1 = expectationWithDescription("First onSuccess fulfilled")
        let expectation2 = expectationWithDescription("Second onSuccess fulfilled")
        var count = 0
        let future = peripheral.startPollingRSSI()
        future.onSuccess { rssi in
            switch count {
            case 0:
                XCTAssertEqual(rssi, self.updatedRSSI1, "RSSI invalid")
                XCTAssertEqual(peripheral.RSSI, self.updatedRSSI1, "RSSI invalid")
                expectation1.fulfill()
                peripheral.didReadRSSI(NSNumber(int: Int32(self.updatedRSSI2)), error: nil)
            case 1:
                XCTAssertEqual(rssi, self.updatedRSSI2, "RSSI invalid")
                XCTAssertEqual(peripheral.RSSI, self.updatedRSSI2, "RSSI invalid")
                expectation2.fulfill()
            default:
                XCTAssert(false, "onSuccess called too many times")
            }
            count += 1
        }
        future.onFailure { error in
            XCTAssert(false, "onFailure called")
        }
        peripheral.didReadRSSI(NSNumber(int: Int32(self.updatedRSSI1)), error: nil)
        waitForExpectationsWithTimeout(20) { error in
            XCTAssertNil(error, "\(error)")
        }
    }

   func testDisconnectedPollRSSIFailure() {
        let mockPeripheral = CBPeripheralMock(state: .Disconnected)
        let peripheral = BCPeripheral(cbPeripheral: mockPeripheral, centralManager: self.centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        let onSuccessExpectation = expectationWithDescription("onSuccess fulfilled")
        let onFailureExpectation = expectationWithDescription("onFailure fulfilled")
        var count = 0
        let future = peripheral.startPollingRSSI()
        future.onSuccess { rssi in
            XCTAssertEqual(0, count, "onSuccess called too many times")
            XCTAssertEqual(rssi, self.updatedRSSI1, "RSSI invalid")
            XCTAssertEqual(peripheral.RSSI, self.updatedRSSI1, "RSSI invalid")
            onSuccessExpectation.fulfill()
            peripheral.didReadRSSI(NSNumber(int: Int32(self.updatedRSSI2)), error: TestFailure.error)
            count += 1
        }
        future.onFailure { error in
            XCTAssertEqual(error.code, TestFailure.error.code, "Error code invalid")
            XCTAssertEqual(1, count, "onFailure called too many times")
            onFailureExpectation.fulfill()
        }
        peripheral.didReadRSSI(NSNumber(int: Int32(self.updatedRSSI1)), error: nil)
        waitForExpectationsWithTimeout(20) { error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testConnectedPollRSSIFailure() {
        let mockPeripheral = CBPeripheralMock(state: .Connected)
        let peripheral = BCPeripheral(cbPeripheral: mockPeripheral, centralManager: self.centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        let onSuccessExpectation = expectationWithDescription("onSuccess fulfilled")
        let onFailureExpectation = expectationWithDescription("onFailure fulfilled")
        var count = 0
        let future = peripheral.startPollingRSSI()
        future.onSuccess { rssi in
            XCTAssertEqual(0, count, "onSuccess called too many times")
            XCTAssertEqual(rssi, self.updatedRSSI1, "RSSI invalid")
            XCTAssertEqual(peripheral.RSSI, self.updatedRSSI1, "RSSI invalid")
            onSuccessExpectation.fulfill()
            peripheral.didReadRSSI(NSNumber(int: Int32(self.updatedRSSI2)), error: TestFailure.error)
            count += 1
        }
        future.onFailure { error in
            XCTAssertEqual(error.code, TestFailure.error.code, "Error code invalid")
            XCTAssertEqual(1, count, "onFailure called too many times")
            onFailureExpectation.fulfill()
        }
        peripheral.didReadRSSI(NSNumber(int: Int32(self.updatedRSSI1)), error: nil)
        waitForExpectationsWithTimeout(20) { error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testStopPollingRSSI() {
        let mockPeripheral = CBPeripheralMock(state: .Connected)
        let peripheral = BCPeripheral(cbPeripheral: mockPeripheral, centralManager: self.centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        let expectation1 = expectationWithDescription("First onSuccess fulfilled")
        var count = 0
        let future = peripheral.startPollingRSSI()
        future.onSuccess { rssi in
            XCTAssertEqual(0, count, "onSuccess called too many times")
            XCTAssertEqual(rssi, self.updatedRSSI1, "RSSI invalid")
            XCTAssertEqual(peripheral.RSSI, self.updatedRSSI1, "RSSI invalid")
            expectation1.fulfill()
            peripheral.stopPollingRSSI()
            peripheral.didReadRSSI(NSNumber(int: Int32(self.updatedRSSI2)), error: nil)
            count += 1
        }
        future.onFailure { error in
            XCTAssert(false, "onFailure called")
        }
        peripheral.didReadRSSI(NSNumber(int: Int32(self.updatedRSSI1)), error: nil)
        waitForExpectationsWithTimeout(20) { error in
            XCTAssertNil(error, "\(error)")
        }
    }

}
