//
//  PertipheralTests.swift
//  BlueCapKit
//
//  Created by Troy Stribling on 1/7/15.
//  Copyright (c) 2015 gnos.us. All rights reserved.
//

import UIKit
import XCTest
import CoreBluetooth
import BlueCapKit

class PertipheralTests: XCTestCase {

    // PeripheralMock
    class PeripheralMock : PeripheralWrappable {
        
        let impl = PeripheralImpl<PeripheralMock>()

        var _state :CBPeripheralState

        let _services = [ServiceMock(uuid:CBUUID(string:"2f0a0017-69aa-f316-3e78-4194989a6ccc"), name:"Service Mock-1"),
                         ServiceMock(uuid:CBUUID(string:"2f0a0017-69aa-f316-3e78-4194989a6aaa"), name:"Service Mock-2")]
        
        var name : String {
            return "Mock Periphearl"
        }
        
        var state: CBPeripheralState {
            return self._state
        }
        
        var services : [ServiceMock] {
            return self._services
        }

        init(state:CBPeripheralState = .Disconnected) {
            self._state = state
        }

        func connect() {
        }
        
        func cancel() {
            if self.state == .Disconnected {
                CentralQueue.async {
                    self.impl.didDisconnectPeripheral(self)
                }
            }
        }
        
        func disconnect() {
        }
        
        func discoverServices(services:[CBUUID]!) {
        }
        
        func didDiscoverServices() {
        }

    }

    struct ServiceMockValues {
        static var error : NSError? = nil
    }

    struct ServiceMock : ServiceWrappable {
        
        let uuid:CBUUID!
        let name:String
        
        let _state :CBPeripheralState = .Connected
        let impl = ServiceImpl<ServiceMock>()
        
        init(uuid:CBUUID, name:String) {
            self.uuid = uuid
            self.name = name
        }
        
        var state: CBPeripheralState {
            return self._state
        }
        
        func discoverCharacteristics(characteristics:[CBUUID]!) {
        }
        
        func didDiscoverCharacteristics(error:NSError!) {
            CentralQueue.async {
                self.impl.didDiscoverCharacteristics(self, error:ServiceMockValues.error)
            }
        }
        
        func createCharacteristics() {
        }
        
        func discoverAllCharacteristics() -> Future<ServiceMock> {
            let future = self.impl.discoverIfConnected(self, characteristics:nil)
            self.didDiscoverCharacteristics(ServiceMockValues.error)
            return future
        }
        
    }
    // PeripheralMock
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testDiscoverServicesSuccess() {
        let mock = PeripheralMock(state:.Connected)
        let onSuccessExpectation = expectationWithDescription("onSuccess fulfilled for future")
        let future = mock.impl.discoverServices(mock, services:nil)
        future.onSuccess {_ in
            onSuccessExpectation.fulfill()
        }
        future.onFailure {error in
            XCTAssert(false, "onFailure called")
        }
        CentralQueue.sync {
            mock.impl.didDiscoverServices(mock, error:nil)
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testDiscoverServicesFailure() {
        let mock = PeripheralMock(state:.Connected)
        let onFailureExpectation = expectationWithDescription("onFailure fulfilled for future")
        let future = mock.impl.discoverServices(mock, services:nil)
        future.onSuccess {_ in
            XCTAssert(false, "onSuccess called")
        }
        future.onFailure {error in
            onFailureExpectation.fulfill()
        }
        CentralQueue.sync {
            mock.impl.didDiscoverServices(mock, error:TestFailure.error)
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testDiscoverPeripheralServicesSuccess() {
        let mock = PeripheralMock(state:.Connected)
        let onSuccessExpectation = expectationWithDescription("onSuccess fulfilled for future")
        let future = mock.impl.discoverPeripheralServices(mock, services:nil)
        future.onSuccess {_ in
            onSuccessExpectation.fulfill()
        }
        future.onFailure {error in
            XCTAssert(false, "onFailure called")
        }
        CentralQueue.sync {
            mock.impl.didDiscoverServices(mock, error:nil)
        }
        waitForExpectationsWithTimeout(10) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func testDiscoverPeripheralServicesPeripheralFailure() {
        let mock = PeripheralMock(state:.Connected)
        let onFailureExpectation = expectationWithDescription("onFailure fulfilled for future")
        let future = mock.impl.discoverPeripheralServices(mock, services:nil)
        future.onSuccess {_ in
            XCTAssert(false, "onSuccess called")
        }
        future.onFailure {error in
            onFailureExpectation.fulfill()
        }
        CentralQueue.sync {
            mock.impl.didDiscoverServices(mock, error:TestFailure.error)
        }
        waitForExpectationsWithTimeout(10) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testDiscoverPeripheralServicesServiceFailure() {
        let mock = PeripheralMock(state:.Connected)
        ServiceMockValues.error = TestFailure.error
        let onFailureExpectation = expectationWithDescription("onFailure fulfilled for future")
        let future = mock.impl.discoverPeripheralServices(mock, services:nil)
        future.onSuccess {_ in
            XCTAssert(false, "onSuccess called")
        }
        future.onFailure {error in
            onFailureExpectation.fulfill()
        }
        CentralQueue.sync {
            mock.impl.didDiscoverServices(mock, error:nil)
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
        ServiceMockValues.error = nil
    }

    func testConnect() {
        let mock = PeripheralMock()
        let onSuccessExpectation = expectationWithDescription("onSuccess fulfilled for future")
        let connectorator = Connectorator() {config in
        }
        let future = connectorator.onConnect()
        future.onSuccess {_ in
            onSuccessExpectation.fulfill()
        }
        future.onFailure {error in
            XCTAssert(false, "onFailure called")
        }
        mock.impl.connect(mock, connectorator:connectorator)
        CentralQueue.sync {
            mock.impl.didConnectPeripheral(mock)
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func testFailedConnect() {
        let mock = PeripheralMock()
        let onFailureExpectation = expectationWithDescription("onFailure fulfilled for future")
        let connectorator = Connectorator() {config in
        }
        let future = connectorator.onConnect()
        future.onSuccess {_ in
            XCTAssert(false, "onSuccess called")
        }
        future.onFailure {error in
            if error.domain == BCError.domain {
                if let connectoratorError = ConnectoratorError(rawValue:error.code) {
                    switch connectoratorError {
                    case .Timeout:
                        XCTAssert(false, "onFailure Timeout invalid")
                    case .Disconnect:
                        XCTAssert(false, "onFailure Disconnect invalid")
                    case .ForceDisconnect:
                        XCTAssert(false, "onFailure ForceDisconnect invalid")
                    case .Failed:
                        onFailureExpectation.fulfill()
                    case .GiveUp:
                        XCTAssert(false, "onFailure GiveUp invalid")
                    }
                } else {
                    XCTAssert(false, "onFailure error code invalid")
                }
            } else {
                XCTAssert(false, "onFailure error invalid")
            }
        }
        mock.impl.connect(mock, connectorator:connectorator)
        CentralQueue.sync {
            mock.impl.didFailToConnectPeripheral(mock, error:nil)
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testFailedConnectWithError() {
        let mock = PeripheralMock()
        let onFailureExpectation = expectationWithDescription("onFailure fulfilled for future")
        let connectorator = Connectorator() {config in
        }
        let future = connectorator.onConnect()
        future.onSuccess {_ in
            XCTAssert(false, "onSuccess called")
        }
        future.onFailure {error in
            if error.domain == BCError.domain {
                XCTAssert(false, "onFailure error invalid")
            } else {
                onFailureExpectation.fulfill()
            }
        }
        mock.impl.connect(mock, connectorator:connectorator)
        mock._state = .Connected
        CentralQueue.sync {
            mock.impl.didFailToConnectPeripheral(mock, error:TestFailure.error)
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
        mock._state = .Disconnected
    }

    func testForcedDisconnectWhenDisconnected() {
        let mock = PeripheralMock(state:.Disconnected)
        let onFailureExpectation = expectationWithDescription("onFailure fulfilled for future")
        let connectorator = Connectorator() {config in
        }
        let future = connectorator.onConnect()
        future.onSuccess {_ in
            XCTAssert(false, "onSuccess called")
        }
        future.onFailure {error in
            if error.domain == BCError.domain {
                if let connectoratorError = ConnectoratorError(rawValue:error.code) {
                    switch connectoratorError {
                    case .Timeout:
                        XCTAssert(false, "onFailure Timeout invalid")
                    case .Disconnect:
                        XCTAssert(false, "onFailure Disconnect invalid")
                    case .ForceDisconnect:
                        onFailureExpectation.fulfill()
                    case .Failed:
                        XCTAssert(false, "onFailure Failed invalid")
                    case .GiveUp:
                        XCTAssert(false, "onFailure GiveUp invalid")
                    }
                } else {
                    XCTAssert(false, "onFailure error code invalid")
                }
            } else {
                XCTAssert(false, "onFailure error invalid")
            }
        }
        mock.impl.connect(mock, connectorator:connectorator)
        mock.impl.disconnect(mock)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func testForcedDisconnectWhenConnected() {
        let mock = PeripheralMock()
        let onFailureExpectation = expectationWithDescription("onFailure fulfilled for future")
        let connectorator = Connectorator() {config in
        }
        let future = connectorator.onConnect()
        future.onSuccess {_ in
            XCTAssert(false, "onSuccess called")
        }
        future.onFailure {error in
            if error.domain == BCError.domain {
                if let connectoratorError = ConnectoratorError(rawValue:error.code) {
                    switch connectoratorError {
                    case .Timeout:
                        XCTAssert(false, "onFailure Timeout invalid")
                    case .Disconnect:
                        XCTAssert(false, "onFailure Disconnect invalid")
                    case .ForceDisconnect:
                        onFailureExpectation.fulfill()
                    case .Failed:
                        XCTAssert(false, "onFailure Failed invalid")
                    case .GiveUp:
                        XCTAssert(false, "onFailure GiveUp invalid")
                    }
                } else {
                    XCTAssert(false, "onFailure error code invalid")
                }
            } else {
                XCTAssert(false, "onFailure error invalid")
            }
        }
        mock.impl.connect(mock, connectorator:connectorator)
        mock._state = .Connected
        mock.impl.disconnect(mock)
        CentralQueue.sync {
            mock.impl.didDisconnectPeripheral(mock)
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testDisconnect() {
        let mock = PeripheralMock()
        let onFailureExpectation = expectationWithDescription("onFailure fulfilled for future")
        let connectorator = Connectorator() {config in
        }
        let future = connectorator.onConnect()
        future.onSuccess {_ in
            XCTAssert(false, "onSuccess called")
        }
        future.onFailure {error in
            if error.domain == BCError.domain {
                if let connectoratorError = ConnectoratorError(rawValue:error.code) {
                    switch connectoratorError {
                    case .Timeout:
                        XCTAssert(false, "onFailure Timeout invalid")
                    case .Disconnect:
                        onFailureExpectation.fulfill()
                    case .ForceDisconnect:
                        XCTAssert(false, "onFailure ForceDisconnect invalid")
                    case .Failed:
                        XCTAssert(false, "onFailure Failed invalid")
                    case .GiveUp:
                        XCTAssert(false, "onFailure GiveUp invalid")
                    }
                } else {
                    XCTAssert(false, "onFailure error code invalid")
                }
            } else {
                XCTAssert(false, "onFailure error invalid")
            }
        }
        mock.impl.connect(mock, connectorator:connectorator)
        CentralQueue.sync {
            mock.impl.didDisconnectPeripheral(mock)
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func testTimeout() {
        let mock = PeripheralMock(state:.Disconnected)
        let onFailureExpectation = expectationWithDescription("onFailure fulfilled for future")
        let connectorator = Connectorator() {config in
            config.connectionTimeout = 1.0
        }
        let future = connectorator.onConnect()
        future.onSuccess {_ in
            XCTAssert(false, "onSuccess called")
        }
        future.onFailure {error in
            if error.domain == BCError.domain {
                if let connectoratorError = ConnectoratorError(rawValue:error.code) {
                    switch connectoratorError {
                    case .Timeout:
                        onFailureExpectation.fulfill()
                    case .Disconnect:
                        XCTAssert(false, "onFailure Disconnect invalid")
                    case .ForceDisconnect:
                        XCTAssert(false, "onFailure ForceDisconnect invalid")
                    case .Failed:
                        XCTAssert(false, "onFailure Failed invalid")
                    case .GiveUp:
                        XCTAssert(false, "onFailure GiveUp invalid")
                    }
                } else {
                    XCTAssert(false, "onFailure error code invalid")
                }
            } else {
                XCTAssert(false, "onFailure error invalid")
            }
        }
        mock.impl.connect(mock, connectorator:connectorator)
        waitForExpectationsWithTimeout(10) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func testGiveUp() {
        let mock = PeripheralMock(state:.Disconnected)
        let timeoutExpectation = expectationWithDescription("onFailure fulfilled for Timeout")
        let giveUpExpectation = expectationWithDescription("onFailure fulfilled for GiveUp")
        let connectorator = Connectorator() {config in
            config.connectionTimeout = 1.0
            config.timeoutRetries = 1
        }
        let future = connectorator.onConnect()
        future.onSuccess {_ in
            XCTAssert(false, "onSuccess called")
        }
        future.onFailure {error in
            if error.domain == BCError.domain {
                if let connectoratorError = ConnectoratorError(rawValue:error.code) {
                    switch connectoratorError {
                    case .Timeout:
                        timeoutExpectation.fulfill()
                        mock.impl.reconnect(mock)
                    case .Disconnect:
                        XCTAssert(false, "onFailure Disconnect invalid")
                    case .ForceDisconnect:
                        XCTAssert(false, "onFailure ForceDisconnect invalid")
                    case .Failed:
                        XCTAssert(false, "onFailure Failed invalid")
                    case .GiveUp:
                        giveUpExpectation.fulfill()
                    }
                } else {
                    XCTAssert(false, "onFailure error code invalid")
                }
            } else {
                XCTAssert(false, "onFailure error invalid")
            }
        }
        mock.impl.connect(mock, connectorator:connectorator)
        waitForExpectationsWithTimeout(10) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testReconectOnTimeout() {
        let mock = PeripheralMock(state:.Disconnected)
        let timeoutExpectation = expectationWithDescription("onFailure fulfilled for Timeout")
        let onSuccessExpectation = expectationWithDescription("onSuccess fulfilled for future")
        let connectorator = Connectorator() {config in
            config.connectionTimeout = 2.0
            config.timeoutRetries = 2
        }
        let future = connectorator.onConnect()
        future.onSuccess {_ in
           onSuccessExpectation.fulfill()
        }
        future.onFailure {error in
            if error.domain == BCError.domain {
                if let connectoratorError = ConnectoratorError(rawValue:error.code) {
                    switch connectoratorError {
                    case .Timeout:
                        timeoutExpectation.fulfill()
                        mock.impl.reconnect(mock)
                        CentralQueue.async {
                            mock.impl.didConnectPeripheral(mock)
                        }
                    case .Disconnect:
                        XCTAssert(false, "onFailure Disconnect invalid")
                    case .ForceDisconnect:
                        XCTAssert(false, "onFailure ForceDisconnect invalid")
                    case .Failed:
                        XCTAssert(false, "onFailure Failed invalid")
                    case .GiveUp:
                        XCTAssert(false, "onFailure GiveUp invalid")
                    }
                } else {
                    XCTAssert(false, "onFailure error code invalid")
                }
            } else {
                XCTAssert(false, "onFailure error invalid")
            }
        }
        mock.impl.connect(mock, connectorator:connectorator)
        waitForExpectationsWithTimeout(10) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func testReconnectOnDisconnect() {
        let mock = PeripheralMock()
        let disconnectExpectation = expectationWithDescription("onFailure fulfilled for Disconnect")
        let onSuccessExpectation = expectationWithDescription("onSuccess fulfilled for future")
        let connectorator = Connectorator() {config in
        }
        let future = connectorator.onConnect()
        future.onSuccess {_ in
            onSuccessExpectation.fulfill()
        }
        future.onFailure {error in
            if error.domain == BCError.domain {
                if let connectoratorError = ConnectoratorError(rawValue:error.code) {
                    switch connectoratorError {
                    case .Timeout:
                        XCTAssert(false, "onFailure Timeout invalid")
                    case .Disconnect:
                        disconnectExpectation.fulfill()
                        mock.impl.reconnect(mock)
                        mock.impl.didConnectPeripheral(mock)
                    case .ForceDisconnect:
                        XCTAssert(false, "onFailure ForceDisconnect invalid")
                    case .Failed:
                        XCTAssert(false, "onFailure Failed invalid")
                    case .GiveUp:
                        XCTAssert(false, "onFailure GiveUp invalid")
                    }
                } else {
                    XCTAssert(false, "onFailure error code invalid")
                }
            } else {
                XCTAssert(false, "onFailure error invalid")
            }
        }
        mock.impl.connect(mock, connectorator:connectorator)
        CentralQueue.sync {
            mock.impl.didDisconnectPeripheral(mock)
        }
        waitForExpectationsWithTimeout(10) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
}
