//
//  TimedScanneratorTests.swift
//  BlueCapKit
//
//  Created by Troy Stribling on 1/7/15.
//  Copyright (c) 2015 gnos.us. All rights reserved.
//

import UIKit
import XCTest
import CoreBluetooth
import BlueCapKit

class TimedScanneratorTests: XCTestCase {

    // TimedScanneratorMock
    class TimedScanneratorMock : TimedScanneratorWrappable {
        
        let impl = TimedScanneratorImpl<TimedScanneratorMock>()
        
        var promise     = StreamPromise<PeripheralMock>()
        var _perpherals : [PeripheralMock]
        
        var peripherals : [PeripheralMock] {
            return self._perpherals
        }
        
        init(peripherals:[PeripheralMock] = [PeripheralMock]()) {
            self._perpherals = peripherals
        }
        
        func startScanning(capacity:Int?) -> FutureStream<PeripheralMock> {
            return self.startScanningForServiceUUIDs(nil, capacity:capacity)
        }
        
        func startScanningForServiceUUIDs(uuids:[CBUUID]!, capacity:Int?) -> FutureStream<PeripheralMock> {
            return self.promise.future
        }
        
        func wrappedStopScanning() {
        }
        
        func timeout() {
            self.promise.failure(BCError.peripheralDiscoveryTimeout)
        }
        
        func didDiscoverPeripheral(peripheral:PeripheralMock) {
            self._perpherals.append(peripheral)
            self.promise.success(peripheral)
        }

    }
    
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
        
        func reconnect() {
        }
        
        func terminate() {
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
    // TimedScanneratorMock

    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }

    func testScanSuccessful() {
        let mock = TimedScanneratorMock()
        let onSuccessExpectation = expectationWithDescription("onSuccess fulfilled for future")
        let future = mock.impl.startScanning(mock, timeoutSeconds:2)
        future.onSuccess {_ in
            onSuccessExpectation.fulfill()
        }
        future.onFailure {error in
            XCTAssert(false, "onFailure called")
        }
        mock.didDiscoverPeripheral(PeripheralMock())
        waitForExpectationsWithTimeout(5) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func testScanTimeout() {
        let mock = TimedScanneratorMock()
        let onFailureExpectation = expectationWithDescription("onFailure fulfilled for future")
        let future = mock.impl.startScanning(mock, timeoutSeconds:1)
        future.onSuccess {_ in
            XCTAssert(false, "onSuccess called")
        }
        future.onFailure {error in
            XCTAssert(PeripheralError.DiscoveryTimeout.rawValue == error.code, "onFailure error invalid \(error.code)")
            onFailureExpectation.fulfill()
        }
        waitForExpectationsWithTimeout(10) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

}
