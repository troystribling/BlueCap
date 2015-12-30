//
//  PeripheralManagerTests.swift
//  BlueCapKit
//
//  Created by Troy Stribling on 3/25/15.
//  Copyright (c) 2015 Troy Stribling. The MIT License (MIT).
//

import UIKit
import XCTest
import CoreBluetooth
import CoreLocation
import BlueCapKit

class PeripheralManagerTests: XCTestCase {

    
//
//    class BeaconRegionMock : BeaconRegionWrappable {
//        
//        let promise = StreamPromise<[BeaconMock]>()
//        
//        var identifier : String {
//            return "ID"
//        }
//        
//        var beaconPromise  : StreamPromise<[BeaconMock]> {
//            return self.promise
//        }
//        
//        func peripheralDataWithMeasuredPower(measuredPower:Int?) -> [String:AnyObject] {
//            return [:]
//        }
//    }
//    
//    class BeaconMock : BeaconWrappable {
//        
//    }
//
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }

    
    func testPowerOnWhenPoweredOn() {
        let mock = CBPeripheralManagerMock(isAdvertising:false, state:.PoweredOn)
        let peripheralManager = PeripheralManager(peripheralManager:mock)
        let expectation = expectationWithDescription("onSuccess fulfilled for future")
        let future = peripheralManager.powerOn()
        future.onSuccess {
            expectation.fulfill()
        }
        future.onFailure{error in
            XCTAssert(false, "onFailure called")
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testPowerOnWhenPoweredOff() {
        let mock = CBPeripheralManagerMock(isAdvertising:false, state:.PoweredOff)
        let peripheralManager = PeripheralManager(peripheralManager:mock)
        let expectation = expectationWithDescription("onSuccess fulfilled for future")
        let future = peripheralManager.powerOn()
        future.onSuccess {
            expectation.fulfill()
        }
        future.onFailure{error in
            XCTAssert(false, "onFailure called")
        }
        mock.state = .PoweredOn
        peripheralManager.didUpdateState()
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testPowerOffWhenPoweredOn() {
        let mock = CBPeripheralManagerMock(isAdvertising:false, state:.PoweredOn)
        let peripheralManager = PeripheralManager(peripheralManager:mock)
        let expectation = expectationWithDescription("onSuccess fulfilled for future")
        let future = peripheralManager.powerOff()
        future.onSuccess {
            expectation.fulfill()
        }
        future.onFailure{error in
            XCTAssert(false, "onFailure called")
        }
        mock.state = .PoweredOff
        peripheralManager.didUpdateState()
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testPowerOffWhenPoweredOff() {
        let mock = CBPeripheralManagerMock(isAdvertising:false, state:.PoweredOff)
        let peripheralManager = PeripheralManager(peripheralManager:mock)
        let expectation = expectationWithDescription("onSuccess fulfilled for future")
        let future = peripheralManager.powerOff()
        future.onSuccess {
            expectation.fulfill()
        }
        future.onFailure{error in
            XCTAssert(false, "onFailure called")
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

//    func testStartAdvertisingSuccess() {
//        let mock = PeripheralManagerMock(isAdvertising:false, state:.PoweredOn)
//        let expectation = expectationWithDescription("onSuccess fulfilled for future")
//        let future = mock.impl.startAdvertising(mock, name:"Peripheral")
//        future.onSuccess {
//            expectation.fulfill()
//        }
//        future.onFailure{error in
//            XCTAssert(false, "onFailure called")
//        }
//        PeripheralQueue.sync {
//            mock.impl.didStartAdvertising(nil)
//        }
//        waitForExpectationsWithTimeout(2) {error in
//            XCTAssertNil(error, "\(error)")
//        }
//    }
//
//    func testStartAdvertisingFailure() {
//        let mock = PeripheralManagerMock(isAdvertising:false, state:.PoweredOn)
//        let expectation = expectationWithDescription("onFailure fulfilled for future")
//        let future = mock.impl.startAdvertising(mock, name:"Peripheral")
//        future.onSuccess {
//            XCTAssert(false, "onSuccess called")
//        }
//        future.onFailure{error in
//            expectation.fulfill()
//        }
//        PeripheralQueue.sync {
//            mock.impl.didStartAdvertising(TestFailure.error)
//        }
//        waitForExpectationsWithTimeout(2) {error in
//            XCTAssertNil(error, "\(error)")
//        }
//    }
//
//    func testStartAdvertisingWhenAdvertising() {
//        let mock = PeripheralManagerMock(isAdvertising:true, state:.PoweredOn)
//        let expectation = expectationWithDescription("onFailure fulfilled for future")
//        let future = mock.impl.startAdvertising(mock, name:"Peripheral")
//        future.onSuccess {
//            XCTAssert(false, "onSuccess called")
//        }
//        future.onFailure{error in
//            XCTAssert(error.code == PeripheralManagerError.IsAdvertising.rawValue, "Error code is invalid \(error.code)")
//            expectation.fulfill()
//        }
//        waitForExpectationsWithTimeout(2) {error in
//            XCTAssertNil(error, "\(error)")
//        }
//    }
//    
//    func testStartAdvertisingBeaconSuccess() {
//        let mock = PeripheralManagerMock(isAdvertising:false, state:.PoweredOn)
//        let expectation = expectationWithDescription("onSuccess fulfilled for future")
//        let future = mock.impl.startAdvertising(mock, region:BeaconRegionMock())
//        future.onSuccess {
//            expectation.fulfill()
//        }
//        future.onFailure{error in
//            XCTAssert(false, "onFailure called")
//        }
//        PeripheralQueue.sync {
//            mock.impl.didStartAdvertising(nil)
//        }
//        waitForExpectationsWithTimeout(2) {error in
//            XCTAssertNil(error, "\(error)")
//        }
//    }
//
//    func testStartAdvertisingBeaconFailure() {
//        let mock = PeripheralManagerMock(isAdvertising:false, state:.PoweredOn)
//        let expectation = expectationWithDescription("onFailure fulfilled for future")
//        let future = mock.impl.startAdvertising(mock, region:BeaconRegionMock())
//        future.onSuccess {
//            XCTAssert(false, "onSuccess called")
//        }
//        future.onFailure{error in
//            expectation.fulfill()
//        }
//        PeripheralQueue.sync {
//            mock.impl.didStartAdvertising(TestFailure.error)
//        }
//        waitForExpectationsWithTimeout(2) {error in
//            XCTAssertNil(error, "\(error)")
//        }
//    }
//
//    func testStartAdvertisingBeaconWhenAdvertising() {
//        let mock = PeripheralManagerMock(isAdvertising:true, state:.PoweredOn)
//        let expectation = expectationWithDescription("onFailure fulfilled for future")
//        let future = mock.impl.startAdvertising(mock, region:BeaconRegionMock())
//        future.onSuccess {
//            XCTAssert(false, "onSuccess called")
//        }
//        future.onFailure{error in
//            XCTAssert(error.code == PeripheralManagerError.IsAdvertising.rawValue, "Error code is invalid \(error.code)")
//            expectation.fulfill()
//        }
//        waitForExpectationsWithTimeout(2) {error in
//            XCTAssertNil(error, "\(error)")
//        }
//    }
//
//    func testStopAdvertising() {
//        let mock = PeripheralManagerMock(isAdvertising:true, state:.PoweredOn)
//        let expectation = expectationWithDescription("onSuccess fulfilled for future")
//        let future = mock.impl.stopAdvertising(mock)
//        future.onSuccess {
//            expectation.fulfill()
//        }
//        future.onFailure{error in
//            XCTAssert(false, "onFailure called")
//        }
//        mock._isAdvertising = false
//        waitForExpectationsWithTimeout(2) {error in
//            XCTAssertNil(error, "\(error)")
//        }
//    }
//
//    func testStopAdvertisingWhenNotAdvertsing() {
//        let mock = PeripheralManagerMock(isAdvertising:false, state:.PoweredOn)
//        let expectation = expectationWithDescription("onFailure fulfilled for future")
//        let future = mock.impl.stopAdvertising(mock)
//        future.onSuccess {
//            XCTAssert(false, "onSuccess called")
//        }
//        future.onFailure{error in
//            XCTAssert(error.code == PeripheralManagerError.IsNotAdvertising.rawValue, "Error code is invalid \(error.code)")
//            expectation.fulfill()
//        }
//        waitForExpectationsWithTimeout(2) {error in
//            XCTAssertNil(error, "\(error)")
//        }
//    }
//    
//    func testAddServiceSuccess() {
//        let mock = PeripheralManagerMock(isAdvertising:false, state:.PoweredOn)
//        let expectation = expectationWithDescription("onSuccess fulfilled for future")
//        let future = mock.impl.addService(mock, service:MutableServiceMock())
//        future.onSuccess {
//            expectation.fulfill()
//        }
//        future.onFailure{error in
//            XCTAssert(false, "onFailure called")
//        }
//        waitForExpectationsWithTimeout(2) {error in
//            XCTAssertNil(error, "\(error)")
//        }
//    }
//    
//    func testAddServicesSucccess() {
//        let mock = PeripheralManagerMock(isAdvertising:false, state:.PoweredOn)
//        let expectation = expectationWithDescription("onSuccess fulfilled for future")
//        let future = mock.impl.addServices(mock, services:[MutableServiceMock(name:"Service-1"), MutableServiceMock(name:"Service-2")])
//        future.onSuccess {
//            expectation.fulfill()
//        }
//        future.onFailure{error in
//            XCTAssert(false, "onFailure called")
//        }
//        waitForExpectationsWithTimeout(2) {error in
//            XCTAssertNil(error, "\(error)")
//        }
//    }
//
//    func testAddServicesFailure() {
//        let mock = PeripheralManagerMock(isAdvertising:false, state:.PoweredOn)
//        let expectation = expectationWithDescription("onFailure fulfilled for future")
//        let future = mock.impl.addServices(mock, services:[MutableServiceMock(name:"Service-1"),
//                                                           MutableServiceMock(name:"Service-2", error:TestFailure.error)])
//        future.onSuccess {
//            XCTAssert(false, "onSuccess called")
//        }
//        future.onFailure{error in
//            expectation.fulfill()
//        }
//        waitForExpectationsWithTimeout(2) {error in
//            XCTAssertNil(error, "\(error)")
//        }
//    }
//
//    func testAddServiceFailure() {
//        let mock = PeripheralManagerMock(isAdvertising:false, state:.PoweredOn)
//        let expectation = expectationWithDescription("onFailure fulfilled for future")
//        let future = mock.impl.addService(mock, service:MutableServiceMock(name:"Service-1", error:TestFailure.error))
//        future.onSuccess {
//            XCTAssert(false, "onSuccess called")
//        }
//        future.onFailure{error in
//            expectation.fulfill()
//        }
//        waitForExpectationsWithTimeout(2) {error in
//            XCTAssertNil(error, "\(error)")
//        }
//    }
//
//    func testAddServiceWhenAdvertising() {
//        let mock = PeripheralManagerMock(isAdvertising:true, state:.PoweredOn)
//        let expectation = expectationWithDescription("onFailure fulfilled for future")
//        let future = mock.impl.addService(mock, service:MutableServiceMock())
//        future.onSuccess {
//            XCTAssert(false, "onSuccess called")
//        }
//        future.onFailure{error in
//            XCTAssert(error.code == PeripheralManagerError.IsAdvertising.rawValue, "Error code is invalid \(error.code)")
//            expectation.fulfill()
//        }
//        waitForExpectationsWithTimeout(2) {error in
//            XCTAssertNil(error, "\(error)")
//        }
//    }
//
//    func testRemoveServiceSuccess() {
//        let mock = PeripheralManagerMock(isAdvertising:false, state:.PoweredOn)
//        mock._services = [MutableServiceMock()]
//        let expectation = expectationWithDescription("onSuccess fulfilled for future")
//        let future = mock.impl.removeService(mock, service:MutableServiceMock())
//        future.onSuccess {
//            expectation.fulfill()
//        }
//        future.onFailure{error in
//            XCTAssert(false, "onFailure called")
//        }
//        waitForExpectationsWithTimeout(2) {error in
//            XCTAssertNil(error, "\(error)")
//        }
//    }
//    
//    func testRemoveServiceWhenAdvertising() {
//        let mock = PeripheralManagerMock(isAdvertising:true, state:.PoweredOn)
//        mock._services = [MutableServiceMock()]
//        let expectation = expectationWithDescription("onFailure fulfilled for future")
//        let future = mock.impl.removeService(mock, service:MutableServiceMock())
//        future.onSuccess {
//            XCTAssert(false, "onSuccess called")
//        }
//        future.onFailure{error in
//            XCTAssert(error.code == PeripheralManagerError.IsAdvertising.rawValue, "Error code is invalid \(error.code)")
//            expectation.fulfill()
//        }
//        waitForExpectationsWithTimeout(2) {error in
//            XCTAssertNil(error, "\(error)")
//        }
//    }
//
//    func testRemoveAllServiceSuccess() {
//        let mock = PeripheralManagerMock(isAdvertising:false, state:.PoweredOn)
//        mock._services = [MutableServiceMock(), MutableServiceMock()]
//        let expectation = expectationWithDescription("onSuccess fulfilled for future")
//        let future = mock.impl.removeAllServices(mock)
//        future.onSuccess {
//            expectation.fulfill()
//        }
//        future.onFailure{error in
//            XCTAssert(false, "onFailure called")
//        }
//        waitForExpectationsWithTimeout(2) {error in
//            XCTAssertNil(error, "\(error)")
//        }
//    }
//    
//    func testRemoveAllServicseWhenAdvertising() {
//        let mock = PeripheralManagerMock(isAdvertising:true, state:.PoweredOn)
//        mock._services = [MutableServiceMock(), MutableServiceMock()]
//        let expectation = expectationWithDescription("onFailure fulfilled for future")
//        let future = mock.impl.removeAllServices(mock)
//        future.onSuccess {
//            XCTAssert(false, "onSuccess called")
//        }
//        future.onFailure{error in
//            XCTAssert(error.code == PeripheralManagerError.IsAdvertising.rawValue, "Error code is invalid \(error.code)")
//            expectation.fulfill()
//        }
//        waitForExpectationsWithTimeout(2) {error in
//            XCTAssertNil(error, "\(error)")
//        }
//    }

}
