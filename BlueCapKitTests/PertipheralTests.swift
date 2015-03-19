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
        static var state :CBPeripheralState = .Connected
        static var connectorator : Connectorator? = nil
    }
    
    struct PeripheralMock : PeripheralWrappable {
        
        let _services = [ServiceMock(uuid:CBUUID(string:"2f0a0017-69aa-f316-3e78-4194989a6ccc"), name:"Service Mock-1"),
                         ServiceMock(uuid:CBUUID(string:"2f0a0017-69aa-f316-3e78-4194989a6aaa"), name:"Service Mock-2")]
        var name : String {
            return "Mock Periphearl"
        }
        
        var state: CBPeripheralState {
            return MockValues.state
        }
        
        var connectorator : Connectorator? {
            return MockValues.connectorator
        }
        
        var services : [ServiceMock] {
            return self._services
        }
        
        init() {            
        }
        
        func connect() {
        }
        
        func cancel() {
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
            return self.impl.discoverIfConnected(self, characteristics:nil)
        }
        
    }
    // PeripheralMock
    let mock = PeripheralMock()
    let impl = PeripheralImpl<PeripheralMock>()

    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testDiscoverServicesSuccess() {
        let onSuccessExpectation = expectationWithDescription("onSuccess fulfilled for future")
        let future = self.impl.discoverServices(self.mock, services:nil)
        future.onSuccess {_ in
            onSuccessExpectation.fulfill()
        }
        future.onFailure {error in
            XCTAssert(false, "onFailure called")
        }
        self.impl.didDiscoverServices(self.mock, error:nil)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testDiscoverServicesFailure() {
        let onFailureExpectation = expectationWithDescription("onFailure fulfilled for future")
        let future = self.impl.discoverServices(self.mock, services:nil)
        future.onSuccess {_ in
            XCTAssert(false, "onSuccess called")
        }
        future.onFailure {error in
            onFailureExpectation.fulfill()
        }
        self.impl.didDiscoverServices(self.mock, error:TestFailure.error)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testDiscoverPeripheralServicesSuccess() {
        let onSuccessExpectation = expectationWithDescription("onSuccess fulfilled for future")
        let future = self.impl.discoverPeripheralServices(self.mock, services:nil)
        future.onSuccess {_ in
            onSuccessExpectation.fulfill()
        }
        future.onFailure {error in
            XCTAssert(false, "onFailure called")
        }
        self.impl.didDiscoverServices(self.mock, error:nil)
        self.impl._servicesDiscoveredFuture.onSuccess {_ in
            self.mock.services[0].didDiscoverCharacteristics(nil)
        }
        waitForExpectationsWithTimeout(10) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func testDiscoverPeripheralServicesFailure() {
    }

    func testPeripheralConnect() {
    }
    
    func testPeripheralFailedConnect() {
    }
    
    func testPeripheralForcedConnect() {
    }
    
    func testPeripheralDisconnect() {
    }
    
    func testPeripheralTimeout() {
    }
}
