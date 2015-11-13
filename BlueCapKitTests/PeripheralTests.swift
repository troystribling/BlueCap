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
import BlueCapKit

class PeripheralTests: XCTestCase {

    var centralManager : CentralManager!
    var centralManagerMock : CBCentralManagerMock!
    
    var services = [CBServiceWrappable]()
    var charateristics = [CBCharacteristicWrappable]()
    
    override func setUp() {
        self.centralManagerMock = CBCentralManagerMock(state:.PoweredOn)
        self.centralManager = CentralManagerUT(centralManager:self.centralManagerMock)
        self.services.append(CBServiceMock(UUID:CBUUID(string:"2f0a0017-69aa-f316-3e78-4194989a6ccc")))
        self.services.append(CBServiceMock(UUID:CBUUID(string:"2f0a0017-69aa-f316-3e78-4194989a6fff")))
        self.charateristics.append(CBCharacteristicMock(properties:[.Read, .Write], UUID:CBUUID(string:"2f0a0017-69aa-f316-3e78-4194989a6111"), isNotifying:false))
        self.charateristics.append(CBCharacteristicMock(properties:[.Read, .Write], UUID:CBUUID(string:"2f0a0017-69aa-f316-3e78-4194989a6222"), isNotifying:false))
        self.charateristics.append(CBCharacteristicMock(properties:[.Read, .Write], UUID:CBUUID(string:"2f0a0017-69aa-f316-3e78-4194989a6333"), isNotifying:false))
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testDiscoverServicesSuccess() {
        let mockPeripheral = CBPeripheralMock(state:.Connected)
        let peripheral = Peripheral(cbPeripheral:mockPeripheral, centralManager:self.centralManager, advertisements:peripheralAdvertisements, rssi:-45)
        let onSuccessExpectation = expectationWithDescription("onSuccess fulfilled for future")
        let future = peripheral.discoverAllServices()
        future.onSuccess {_ in
            onSuccessExpectation.fulfill()
            let discoveredServices = peripheral.services
            XCTAssert(discoveredServices.count == 2, "Peripheral service count invalid")
            XCTAssert(mockPeripheral.discoverServicesCalledCount == 1, "CBPeripheral#discoverServices called more than once")
            XCTAssert(mockPeripheral.discoverServicesCalled, "CBPeripheral#discoverServices not called")
            XCTAssertFalse(mockPeripheral.discoverCharacteristicsCalled, "CBPeripheral#discoverChracteristics called")
        }
        future.onFailure {error in
            XCTAssert(false, "onFailure called")
        }
        peripheral.didDiscoverServices(self.services, error:nil)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testDiscoverServicesCoreBluetoothFailure() {
        let mockPeripheral = CBPeripheralMock(state:.Connected)
        let peripheral = Peripheral(cbPeripheral:mockPeripheral, centralManager:self.centralManager, advertisements:peripheralAdvertisements, rssi:-45)
        let onFailureExpectation = expectationWithDescription("onFailure fulfilled for future")
        let future = peripheral.discoverAllServices()
        future.onSuccess {_ in
            XCTAssert(false, "onSuccess called")
        }
        future.onFailure {error in
            onFailureExpectation.fulfill()
            XCTAssert(error.code == TestFailure.error.code, "Error code invalid")
            XCTAssert(mockPeripheral.discoverServicesCalled, "CBPeripheral#discoverServices not called")
            XCTAssert(mockPeripheral.discoverServicesCalledCount == 1, "CBPeripheral#discoverServices called more than once")
            XCTAssertFalse(mockPeripheral.discoverCharacteristicsCalled, "CBPeripheral#discoverChracteristics called")
        }
        peripheral.didDiscoverServices([], error:TestFailure.error)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testDiscoverServicesDisconnectedFailure() {
        let mockPeripheral = CBPeripheralMock(state:.Disconnected)
        let peripheral = Peripheral(cbPeripheral:mockPeripheral, centralManager:self.centralManager, advertisements:peripheralAdvertisements, rssi:-45)
        let onFailureExpectation = expectationWithDescription("onFailure fulfilled for future")
        let future = peripheral.discoverAllServices()
        future.onSuccess {_ in
            XCTAssert(false, "onSuccess called")
        }
        future.onFailure {error in
            onFailureExpectation.fulfill()
            XCTAssert(error.code == BCError.peripheralDisconnected.code, "Error code invalid")
            XCTAssertFalse(mockPeripheral.discoverServicesCalled, "CBPeripheral#discoverServices called")
            XCTAssert(mockPeripheral.discoverServicesCalledCount == 0, "CBPeripheral#discoverServices called more than once")
            XCTAssertFalse(mockPeripheral.discoverCharacteristicsCalled, "CBPeripheral#discoverChracteristics called")
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

//    func testDiscoverPeripheralServicesSuccess() {
//        let mockPeripheral = CBPeripheralMock(state:.Connected)
//        let peripheral = Peripheral(cbPeripheral:mockPeripheral, centralManager:self.centralManager, advertisements:peripheralAdvertisements, rssi:-45)
//        let onSuccessExpectation = expectationWithDescription("onSuccess fulfilled for future")
//        let future = peripheral.discoverAllPeripheralServices()
//        future.onSuccess {_ in
//            onSuccessExpectation.fulfill()
//            let discoveredServices = peripheral.services
//            XCTAssert(discoveredServices.count == 2, "Peripheral service count invalid")
//            XCTAssert(mockPeripheral.discoverServicesCalled, "CBPeripheral#discoverServices not called")
//            XCTAssert(mockPeripheral.discoverCharacteristicsCalled, "CBPeripheral#discoverChracteristics called")
//        }
//        future.onFailure {error in
//            XCTAssert(false, "onFailure called")
//        }
//        peripheral.didDiscoverServices(self.services, error:nil)
//        let discoveredServices = peripheral.services
//        peripheral.didDiscoverCharacteristicsForService([self.charateristics[0], self.charateristics[1]], service:discoveredServices[0], error:nil)
//        peripheral.didDiscoverCharacteristicsForService([self.charateristics[2]], service:discoveredServices[1], error:nil)
//        waitForExpectationsWithTimeout(20) {error in
//            XCTAssertNil(error, "\(error)")
//        }
//    }
//
//    func testDiscoverPeripheralServicesPeripheralFailure() {
//        let mock = PeripheralMock(state:.Connected)
//        let onFailureExpectation = expectationWithDescription("onFailure fulfilled for future")
//        let future = mock.impl.discoverPeripheralServices(mock, services:nil)
//        future.onSuccess {_ in
//            XCTAssert(false, "onSuccess called")
//        }
//        future.onFailure {error in
//            onFailureExpectation.fulfill()
//        }
//        CentralQueue.sync {
//            mock.impl.didDiscoverServices(mock, error:TestFailure.error)
//        }
//        waitForExpectationsWithTimeout(20) {error in
//            XCTAssertNil(error, "\(error)")
//        }
//    }
//
//    func testDiscoverPeripheralServicesServiceFailure() {
//        let mock = PeripheralMock(state:.Connected)
//        ServiceMockValues.error = TestFailure.error
//        let onFailureExpectation = expectationWithDescription("onFailure fulfilled for future")
//        let future = mock.impl.discoverPeripheralServices(mock, services:nil)
//        future.onSuccess {_ in
//            XCTAssert(false, "onSuccess called")
//        }
//        future.onFailure {error in
//            onFailureExpectation.fulfill()
//        }
//        CentralQueue.sync {
//            mock.impl.didDiscoverServices(mock, error:nil)
//        }
//        waitForExpectationsWithTimeout(20) {error in
//            XCTAssertNil(error, "\(error)")
//        }
//        ServiceMockValues.error = nil
//    }
//
//    func testDiscoverPeripheralServicesNoServicesFoundFailure() {
//        let mock = PeripheralMock(state:.Connected, services:[ServiceMock]())
//        let onFailureExpectation = expectationWithDescription("onFailure fulfilled for future")
//        let future = mock.impl.discoverPeripheralServices(mock, services:nil)
//        future.onSuccess {_ in
//            XCTAssert(false, "onSuccess called")
//        }
//        future.onFailure {error in
//            onFailureExpectation.fulfill()
//            XCTAssert(error.domain == BCError.domain, "message domain invalid")
//            XCTAssert(error.code == PeripheralError.NoServices.rawValue, "message code invalid")
//        }
//        CentralQueue.sync {
//            mock.impl.didDiscoverServices(mock, error:nil)
//        }
//        waitForExpectationsWithTimeout(20) {error in
//            XCTAssertNil(error, "\(error)")
//        }
//        ServiceMockValues.error = nil
//    }
//
    func testConnect() {
        let mockPeripheral = CBPeripheralMock(state:.Disconnected)
        let peripheral = Peripheral(cbPeripheral:mockPeripheral, centralManager:self.centralManager, advertisements:peripheralAdvertisements, rssi:-45)
        let onConnectionExpectation = expectationWithDescription("onSuccess fulfilled for future")
        let future = peripheral.connect(connectionTimeout:100.0)
        future.onSuccess{(peripheral, connectionEvent) in
            switch connectionEvent {
            case .Connect:
                onConnectionExpectation.fulfill()
            case .Timeout:
                XCTAssert(false, "onSuccess Timeout invalid")
            case .Disconnect:
                XCTAssert(false, "onSuccess Disconnect invalid")
            case .ForceDisconnect:
                XCTAssert(false, "onSuccess ForceDisconnect invalid")
            case .Failed:
                XCTAssert(false, "onSuccess Failed invalid")
            case .GiveUp:
                XCTAssert(false, "onSuccess GiveUp invalid")
            }
        }
        future.onFailure {error in
            XCTAssert(false, "onFailure called")
        }
        peripheral.didConnectPeripheral()
        waitForExpectationsWithTimeout(120) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func testFailedConnect() {
        let mockPeripheral = CBPeripheralMock(state:.Disconnected)
        let peripheral = Peripheral(cbPeripheral:mockPeripheral, centralManager:self.centralManager, advertisements:peripheralAdvertisements, rssi:-45)
        let onFailureExpectation = expectationWithDescription("onFailure fulfilled for future")
        let future = peripheral.connect(connectionTimeout:100.0)
        future.onSuccess{(peripheral, connectionEvent) in
            switch connectionEvent {
            case .Connect:
                XCTAssert(false, "onSuccess Connect invalid")
            case .Timeout:
                XCTAssert(false, "onSuccess Timeout invalid")
            case .Disconnect:
                XCTAssert(false, "onSuccess Disconnect invalid")
            case .ForceDisconnect:
                XCTAssert(false, "onSuccess ForceDisconnect invalid")
            case .Failed:
                onFailureExpectation.fulfill()
            case .GiveUp:
                XCTAssert(false, "onSuccess GiveUp invalid")
            }
        }
        future.onFailure {error in
            XCTAssert(false, "onFailure called")
        }
        peripheral.didFailToConnectPeripheral(nil)
        waitForExpectationsWithTimeout(120) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testFailedConnectWithError() {
        let mockPeripheral = CBPeripheralMock(state:.Disconnected)
        let peripheral = Peripheral(cbPeripheral:mockPeripheral, centralManager:self.centralManager, advertisements:peripheralAdvertisements, rssi:-45)
        let onFailureExpectation = expectationWithDescription("onFailure fulfilled for future")
        let future = peripheral.connect()
        future.onSuccess{(peripheral, connectionEvent) in
            switch connectionEvent {
            case .Connect:
                XCTAssert(false, "onSuccess Connect invalid")
            case .Timeout:
                XCTAssert(false, "onSuccess Timeout invalid")
            case .Disconnect:
                XCTAssert(false, "onSuccess Disconnect invalid")
            case .ForceDisconnect:
                XCTAssert(false, "onSuccess ForceDisconnect invalid")
            case .Failed:
                XCTAssert(false, "onSuccess Failed invalid")
            case .GiveUp:
                XCTAssert(false, "onSuccess GiveUp invalid")
            }
        }
        future.onFailure {error in
            onFailureExpectation.fulfill()
            XCTAssert(error.code == TestFailure.error.code, "Error code invalid")
        }
        peripheral.didFailToConnectPeripheral(TestFailure.error)
        waitForExpectationsWithTimeout(20) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testForcedDisconnectWhenDisconnected() {
        let mockPeripheral = CBPeripheralMock(state:.Disconnected)
        let peripheral = Peripheral(cbPeripheral:mockPeripheral, centralManager:self.centralManager, advertisements:peripheralAdvertisements, rssi:-45)
        let onFailureExpectation = expectationWithDescription("onFailure fulfilled for future")
        let future = peripheral.connect(connectionTimeout:100.0)
        future.onSuccess{(peripheral, connectionEvent) in
            switch connectionEvent {
            case .Connect:
                XCTAssert(false, "onSuccess Connect invalid")
            case .Timeout:
                XCTAssert(false, "onSuccess Timeout invalid")
            case .Disconnect:
                XCTAssert(false, "onSuccess Disconnect invalid")
            case .ForceDisconnect:
                onFailureExpectation.fulfill()
            case .Failed:
                XCTAssert(false, "onSuccess Failed invalid")
            case .GiveUp:
                XCTAssert(false, "onSuccess GiveUp invalid")
            }
        }
        future.onFailure {error in
            XCTAssert(false, "onFailure called")
        }
        peripheral.disconnect()
        waitForExpectationsWithTimeout(120) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
//    func testForcedDisconnectWhenConnected() {
//        let mockPeripheral = CBPeripheralMock(state:.Connected)
//        let peripheral = Peripheral(cbPeripheral:mockPeripheral, centralManager:self.centralManager, advertisements:peripheralAdvertisements, rssi:-45)
//        let onFailureExpectation = expectationWithDescription("onFailure fulfilled for future")
//        let future = peripheral.connect()
//        future.onSuccess{(peripheral, connectionEvent) in
//            switch connectionEvent {
//            case .Connect:
//                XCTAssert(false, "onSuccess Connect invalid")
//            case .Timeout:
//                XCTAssert(false, "onSuccess Timeout invalid")
//            case .Disconnect:
//                XCTAssert(false, "onSuccess Disconnect invalid")
//            case .ForceDisconnect:
//                onFailureExpectation.fulfill()
//            case .Failed:
//                XCTAssert(false, "onSuccess Failed invalid")
//            case .GiveUp:
//                XCTAssert(false, "onSuccess GiveUp invalid")
//            }
//        }
//        future.onFailure {error in
//            XCTAssert(false, "onFailure called")
//        }
//        peripheral.disconnect()
//        peripheral.didDisconnectPeripheral()
//        waitForExpectationsWithTimeout(20) {error in
//            XCTAssertNil(error, "\(error)")
//        }
//    }

    func testDisconnect() {
        let mockPeripheral = CBPeripheralMock(state:.Connected)
        let peripheral = Peripheral(cbPeripheral:mockPeripheral, centralManager:self.centralManager, advertisements:peripheralAdvertisements, rssi:-45)
        let onFailureExpectation = expectationWithDescription("onFailure fulfilled for future")
        let future = peripheral.connect(connectionTimeout:100.0)
        future.onSuccess{(peripheral, connectionEvent) in
            switch connectionEvent {
            case .Connect:
                XCTAssert(false, "onSuccess Connect invalid")
            case .Timeout:
                XCTAssert(false, "onSuccess Timeout invalid")
            case .Disconnect:
                onFailureExpectation.fulfill()
            case .ForceDisconnect:
                XCTAssert(false, "onSuccess ForceDisconnect invalid")
            case .Failed:
                XCTAssert(false, "onSuccess Failed invalid")
            case .GiveUp:
                XCTAssert(false, "onSuccess GiveUp invalid")
            }
        }
        future.onFailure {error in
            XCTAssert(false, "onFailure called")
        }
        peripheral.didDisconnectPeripheral()
        waitForExpectationsWithTimeout(120) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func testTimeout() {
        let mockPeripheral = CBPeripheralMock(state:.Disconnected)
        let peripheral = Peripheral(cbPeripheral:mockPeripheral, centralManager:self.centralManager, advertisements:peripheralAdvertisements, rssi:-45)
        let onFailureExpectation = expectationWithDescription("onFailure fulfilled for future")
        let future = peripheral.connect(connectionTimeout:1.0)
        future.onSuccess{(peripheral, connectionEvent) in
            switch connectionEvent {
            case .Connect:
                XCTAssert(false, "onSuccess Connect invalid")
            case .Timeout:
                onFailureExpectation.fulfill()
            case .Disconnect:
                XCTAssert(false, "onSuccess Disconnect invalid")
            case .ForceDisconnect:
                XCTAssert(false, "onSuccess ForceDisconnect invalid")
            case .Failed:
                XCTAssert(false, "onSuccess Failed invalid")
            case .GiveUp:
                XCTAssert(false, "onSuccess GiveUp invalid")
            }
        }
        future.onFailure {error in
            XCTAssert(false, "onFailure called")
        }
        waitForExpectationsWithTimeout(20) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
//    func testGiveUp() {
//        let mockPeripheral = CBPeripheralMock(state:.Disconnected)
//        let peripheral = Peripheral(cbPeripheral:mockPeripheral, centralManager:self.centralManager, advertisements:peripheralAdvertisements, rssi:-45)
//        let timeoutExpectation = expectationWithDescription("onFailure fulfilled for Timeout")
//        let giveUpExpectation = expectationWithDescription("onFailure fulfilled for GiveUp")
//        let future = peripheral.connect(connectionTimeout:1.0, timeoutRetries:1)
//        future.onSuccess{(peripheral, connectionEvent) in
//            switch connectionEvent {
//            case .Connect:
//                XCTAssert(false, "onSuccess Connect invalid")
//            case .Timeout:
//                timeoutExpectation.fulfill()
//                peripheral.reconnect()
//            case .Disconnect:
//                XCTAssert(false, "onSuccess Disconnect invalid")
//            case .ForceDisconnect:
//                XCTAssert(false, "onSuccess ForceDisconnect invalid")
//            case .Failed:
//                XCTAssert(false, "onSuccess Failed invalid")
//            case .GiveUp:
//                giveUpExpectation.fulfill()
//            }
//        }
//        future.onFailure {error in
//            XCTAssert(false, "onFailure called")
//        }
//        waitForExpectationsWithTimeout(20) {error in
//            XCTAssertNil(error, "\(error)")
//        }
//    }

    func testReconectOnTimeout() {
        let mockPeripheral = CBPeripheralMock(state:.Disconnected)
        let peripheral = Peripheral(cbPeripheral:mockPeripheral, centralManager:self.centralManager, advertisements:peripheralAdvertisements, rssi:-45)
        let timeoutExpectation = expectationWithDescription("onFailure fulfilled for Timeout")
        let onConnectionExpectation = expectationWithDescription("onSuccess fulfilled for future")
        let future = peripheral.connect(connectionTimeout:45.0, timeoutRetries:2)
        future.onSuccess{(peripheral, connectionEvent) in
            switch connectionEvent {
            case .Connect:
                onConnectionExpectation.fulfill()
            case .Timeout:
                timeoutExpectation.fulfill()
                peripheral.reconnect()
                peripheral.didConnectPeripheral()
            case .Disconnect:
                XCTAssert(false, "onSuccess Disconnect invalid")
            case .ForceDisconnect:
                XCTAssert(false, "onSuccess ForceDisconnect invalid")
            case .Failed:
                XCTAssert(false, "onSuccess Failed invalid")
            case .GiveUp:
                XCTAssert(false, "onFailure GiveUp invalid")
            }
        }
        future.onFailure {error in
            XCTAssert(false, "onFailure called")
        }
        waitForExpectationsWithTimeout(120) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func testReconnectOnDisconnect() {
        let mockPeripheral = CBPeripheralMock(state:.Disconnected)
        let peripheral = Peripheral(cbPeripheral:mockPeripheral, centralManager:self.centralManager, advertisements:peripheralAdvertisements, rssi:-45)
        let disconnectExpectation = expectationWithDescription("onFailure fulfilled for Disconnect")
        let onConnectionExpectation = expectationWithDescription("onSuccess fulfilled for future")
        let future = peripheral.connect(connectionTimeout:100.0)
        future.onSuccess{(peripheral, connectionEvent) in
            switch connectionEvent {
            case .Connect:
                onConnectionExpectation.fulfill()
            case .Timeout:
                XCTAssert(false, "onSuccess Timeout invalid")
            case .Disconnect:
                disconnectExpectation.fulfill()
                peripheral.reconnect()
                peripheral.didConnectPeripheral()
            case .ForceDisconnect:
                XCTAssert(false, "onSuccess ForceDisconnect invalid")
            case .Failed:
                XCTAssert(false, "onSuccess Failed invalid")
            case .GiveUp:
                XCTAssert(false, "onFailure GiveUp invalid")
            }
        }
        future.onFailure {error in
            XCTAssert(false, "onFailure called")
        }
            
        peripheral.didDisconnectPeripheral()
        waitForExpectationsWithTimeout(120) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
}
