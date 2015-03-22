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
    struct MockValues {
        static var state            :CBPeripheralState  = .Connected
        static var error            : NSError?          = nil
    }
    
    struct PeripheralMock : PeripheralWrappable {
        
        let impl = PeripheralImpl<PeripheralMock>()

        let _services = [ServiceMock(uuid:CBUUID(string:"2f0a0017-69aa-f316-3e78-4194989a6ccc"), name:"Service Mock-1"),
                         ServiceMock(uuid:CBUUID(string:"2f0a0017-69aa-f316-3e78-4194989a6aaa"), name:"Service Mock-2")]
        var name : String {
            return "Mock Periphearl"
        }
        
        var state: CBPeripheralState {
            return MockValues.state
        }
        
        var services : [ServiceMock] {
            return self._services
        }
        
        init() {            
        }
        
        func connect() {
        }
        
        func cancel() {
            if MockValues.state == .Disconnected {
                self.impl.didDisconnectPeripheral(self)
            }
        }
        
        func disconnect() {
        }
        
        func discoverServices(services:[CBUUID]!) {
        }
        
        func didDiscoverServices() {
        }

    }

    struct ServiceMock : ServiceWrappable {
        
        let uuid:CBUUID!
        let name:String
        
        let impl = ServiceImpl<ServiceMock>()
        
        init(uuid:CBUUID, name:String) {
            self.uuid = uuid
            self.name = name
        }
        
        var state: CBPeripheralState {
            return MockValues.state
        }
        
        func discoverCharacteristics(characteristics:[CBUUID]!) {
        }
        
        func didDiscoverCharacteristics(error:NSError!) {
            self.impl.didDiscoverCharacteristics(self, error:error)
        }
        
        func createCharacteristics() {
        }
        
        func discoverAllCharacteristics() -> Future<ServiceMock> {
            let future = self.impl.discoverIfConnected(self, characteristics:nil)
            self.didDiscoverCharacteristics(MockValues.error)
            return future
        }
        
    }
    
    // PeripheralMock
    let mock = PeripheralMock()

    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testDiscoverServicesSuccess() {
        let onSuccessExpectation = expectationWithDescription("onSuccess fulfilled for future")
        let future = self.mock.impl.discoverServices(self.mock, services:nil)
        future.onSuccess {_ in
            onSuccessExpectation.fulfill()
        }
        future.onFailure {error in
            XCTAssert(false, "onFailure called")
        }
        self.mock.impl.didDiscoverServices(self.mock, error:nil)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testDiscoverServicesFailure() {
        let onFailureExpectation = expectationWithDescription("onFailure fulfilled for future")
        let future = self.mock.impl.discoverServices(self.mock, services:nil)
        future.onSuccess {_ in
            XCTAssert(false, "onSuccess called")
        }
        future.onFailure {error in
            onFailureExpectation.fulfill()
        }
        self.mock.impl.didDiscoverServices(self.mock, error:TestFailure.error)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testDiscoverPeripheralServicesSuccess() {
        let onSuccessExpectation = expectationWithDescription("onSuccess fulfilled for future")
        let future = self.mock.impl.discoverPeripheralServices(self.mock, services:nil)
        future.onSuccess {_ in
            onSuccessExpectation.fulfill()
        }
        future.onFailure {error in
            XCTAssert(false, "onFailure called")
        }
        self.mock.impl.didDiscoverServices(self.mock, error:nil)
        waitForExpectationsWithTimeout(10) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func testDiscoverPeripheralServicesPeripheralFailure() {
        let onFailureExpectation = expectationWithDescription("onFailure fulfilled for future")
        let future = self.mock.impl.discoverPeripheralServices(self.mock, services:nil)
        future.onSuccess {_ in
            XCTAssert(false, "onSuccess called")
        }
        future.onFailure {error in
            onFailureExpectation.fulfill()
        }
        self.mock.impl.didDiscoverServices(self.mock, error:TestFailure.error)
        waitForExpectationsWithTimeout(10) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testDiscoverPeripheralServicesSErviceFailure() {
        MockValues.error = TestFailure.error
        let onFailureExpectation = expectationWithDescription("onFailure fulfilled for future")
        let future = self.mock.impl.discoverPeripheralServices(self.mock, services:nil)
        future.onSuccess {_ in
            XCTAssert(false, "onSuccess called")
        }
        future.onFailure {error in
            onFailureExpectation.fulfill()
        }
        self.mock.impl.didDiscoverServices(self.mock, error:nil)
        waitForExpectationsWithTimeout(10) {error in
            XCTAssertNil(error, "\(error)")
        }
        MockValues.error = nil
    }

    func testConnect() {
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
        self.mock.impl.connect(self.mock, connectorator:connectorator)
        self.mock.impl.didConnectPeripheral(self.mock)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func testFailedConnect() {
        MockValues.state = .Disconnected
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
        self.mock.impl.connect(self.mock, connectorator:connectorator)
        MockValues.state = .Connected
        self.mock.impl.didFailToConnectPeripheral(self.mock, error:nil)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testFailedConnectWithError() {
        MockValues.state = .Disconnected
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
        self.mock.impl.connect(self.mock, connectorator:connectorator)
        MockValues.state = .Connected
        self.mock.impl.didFailToConnectPeripheral(self.mock, error:TestFailure.error)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testForcedDisconnectWhenDisconnected() {
        MockValues.state = .Disconnected
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
        self.mock.impl.connect(self.mock, connectorator:connectorator)
        self.mock.impl.disconnect(self.mock)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
        MockValues.state = .Connected
    }
    
    func testForcedDisconnectWhenConnected() {
        MockValues.state = .Disconnected
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
        self.mock.impl.connect(self.mock, connectorator:connectorator)
        MockValues.state = .Connected
        self.mock.impl.disconnect(self.mock)
        self.mock.impl.didDisconnectPeripheral(self.mock)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testDisconnect() {
        MockValues.state = .Disconnected
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
        self.mock.impl.connect(self.mock, connectorator:connectorator)
        self.mock.impl.didDisconnectPeripheral(self.mock)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
        MockValues.state = .Connected
    }
    
    func testTimeout() {
        MockValues.state = .Disconnected
        let onFailureExpectation = expectationWithDescription("onFailure fulfilled for future")
        let connectorator = Connectorator() {config in
            config.connectionTimeout = 2.0
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
        self.mock.impl.connect(self.mock, connectorator:connectorator)
        waitForExpectationsWithTimeout(4) {error in
            XCTAssertNil(error, "\(error)")
        }
        MockValues.state = .Connected
    }
    
    func testGiveUp() {
    }

    func testReconectOnTimeout() {
    }
    
    func testReconnectOnDisconnect() {
    }
}
