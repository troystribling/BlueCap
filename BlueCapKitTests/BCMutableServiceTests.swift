//
//  BCMutableServiceTests.swift
//  BlueCapKit
//
//  Created by Troy Stribling on 1/2/16.
//  Copyright © 2016 Troy Stribling. All rights reserved.
//

import UIKit
import XCTest
import CoreBluetooth
import CoreLocation
@testable import BlueCapKit

// MARK: - BCMutableServiceTests -
class BCMutableServiceTests: XCTestCase {
    
    override func setUp() {
        GnosusProfiles.create()
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    

    // MARK: Add service
    func testAddServiceSuccess() {
        let (mock, peripheralManager) = createPeripheralManager(false, state: .PoweredOn)
        let services = createPeripheralManagerServices(peripheralManager)
        let expectation = expectationWithDescription("onSuccess fulfilled for future")
        let future = peripheralManager.addService(services[0])
        future.onSuccess {
            expectation.fulfill()
            let peripheralServices = peripheralManager.services
            XCTAssert(mock.addServiceCalled, "addService not called")
            XCTAssertEqual(peripheralServices.count, 1, "peripheralManager service count invalid")
            XCTAssertEqual(peripheralServices[0].UUID, services[0].UUID, "addedService has invalid UUID")
            if let addedService = mock.addedService {
                XCTAssertEqual(services[0].UUID, addedService.UUID, "addedService UUID invalid")
            } else {
                XCTAssert(false, "addService not found")
            }
        }
        future.onFailure {error in
            XCTAssert(false, "onFailure called")
        }
        peripheralManager.didAddService(services[0].cbMutableService, error: nil)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func testAddServicesSucccess() {
        let (mock, peripheralManager) = createPeripheralManager(false, state: .PoweredOn)
        let services = createPeripheralManagerServices(peripheralManager)
        let expectation = expectationWithDescription("onSuccess fulfilled for future")
        let future = peripheralManager.addServices(services)
        future.onSuccess {
            expectation.fulfill()
            let peripheralServices = peripheralManager.services.map{$0.UUID}
            XCTAssert(mock.addServiceCalled, "addService not called")
            XCTAssertEqual(peripheralServices.count, 2, "peripheralManager service count invalid")
            XCTAssert(peripheralServices.contains(services[0].UUID), "addedService has invalid UUID")
            XCTAssert(peripheralServices.contains(services[1].UUID), "addedService has invalid UUID")
        }
        future.onFailure {error in
            XCTAssert(false, "onFailure called")
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func testAddServicesFailure() {
        let (mock, peripheralManager) = createPeripheralManager(false, state: .PoweredOn)
        let services = createPeripheralManagerServices(peripheralManager)
        let expectation = expectationWithDescription("onSuccess fulfilled for future")
        let future = peripheralManager.addServices(services)
        peripheralManager.error = TestFailure.error
        future.onSuccess {
            XCTAssert(false, "onSuccess called")
        }
        future.onFailure {error in
            expectation.fulfill()
            let peripheralServices = peripheralManager.services
            XCTAssertEqual(TestFailure.error.code, error.code, "error code is invalid")
            XCTAssert(mock.addServiceCalled, "addService not called")
            XCTAssertEqual(peripheralServices.count, 0, "peripheralManager service count invalid")
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func testAddServiceFailure() {
        let (mock, peripheralManager) = createPeripheralManager(false, state: .PoweredOn)
        let services = createPeripheralManagerServices(peripheralManager)
        let expectation = expectationWithDescription("onSuccess fulfilled for future")
        let future = peripheralManager.addService(services[0])
        future.onSuccess {
            XCTAssert(false, "onSuccess called")
        }
        future.onFailure {error in
            expectation.fulfill()
            let peripheralServices = peripheralManager.services
            XCTAssertEqual(TestFailure.error.code, error.code, "error code is invalid")
            XCTAssert(mock.addServiceCalled, "addService not called")
            XCTAssertEqual(peripheralServices.count, 0, "peripheralManager service count invalid")
        }
        peripheralManager.didAddService(services[0].cbMutableService, error: TestFailure.error)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testAddServiceWhenAdvertising() {
        let (mock, peripheralManager) = createPeripheralManager(true, state: .PoweredOn)
        let services = createPeripheralManagerServices(peripheralManager)
        let expectation = expectationWithDescription("onFailure fulfilled for future")
        let future = peripheralManager.addService(services[0])
        future.onSuccess {
            XCTAssert(false, "onSuccess called")
        }
        future.onFailure {error in
            expectation.fulfill()
            let peripheralServices = peripheralManager.services
            XCTAssertEqual(error.code, BCPeripheralManagerErrorCode.IsAdvertising.rawValue, "error code is invalid")
            XCTAssertFalse(mock.addServiceCalled, "addService called")
            XCTAssertEqual(peripheralServices.count, 0, "peripheralManager service count invalid")
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    // MARK: Remove service
    func testRemoveServiceSuccess() {
        let (mock, peripheralManager) = createPeripheralManager(false, state: .PoweredOn)
        let services = createPeripheralManagerServices(peripheralManager)
        let expectation = expectationWithDescription("onSuccess fulfilled for future")
        let addServicesFuture = peripheralManager.addServices(services)
        let removeServiceFuture = addServicesFuture.flatmap {
            peripheralManager.removeService(services[0])
        }
        removeServiceFuture.onSuccess {
            expectation.fulfill()
            let peripheralServices = peripheralManager.services
            XCTAssert(mock.removeServiceCalled, "removeService not called")
            XCTAssertEqual(peripheralServices.count, 1, "peripheralManager service count invalid")
            XCTAssertEqual(peripheralServices[0].UUID, services[1].UUID, "addedService has invalid UUID")
            if let removedService = mock.removedService {
                XCTAssertEqual(removedService.UUID, services[0].UUID, "addedService has invalid UUID")
            } else {
                XCTAssert(false, "removedService not found")
            }
        }
        removeServiceFuture.onFailure {error in
            XCTAssert(false, "onFailure called")
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func testRemoveServiceWhenAdvertising() {
        let (mock, peripheralManager) = createPeripheralManager(false, state: .PoweredOn)
        let services = createPeripheralManagerServices(peripheralManager)
        let expectation = expectationWithDescription("onFailure fulfilled for future")
        let addServicesFuture = peripheralManager.addServices(services)
        let removeServiceFuture = addServicesFuture.flatmap { Void -> Future<Void> in
            mock.isAdvertising = true
            return peripheralManager.removeService(services[0])
        }
        removeServiceFuture.onSuccess {
            XCTAssert(false, "onSuccess called")
        }
        removeServiceFuture.onFailure {error in
            expectation.fulfill()
            let peripheralServices = peripheralManager.services
            XCTAssertFalse(mock.removeServiceCalled, "removeService called")
            XCTAssertEqual(peripheralServices.count, 2, "peripheralManager service count invalid")
            XCTAssertEqual(error.code, BCPeripheralManagerErrorCode.IsAdvertising.rawValue, "error code is invalid")
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func testRemoveAllServiceSuccess() {
        let (mock, peripheralManager) = createPeripheralManager(false, state: .PoweredOn)
        let services = createPeripheralManagerServices(peripheralManager)
        let expectation = expectationWithDescription("onSuccess fulfilled for future")
        let addServicesFuture = peripheralManager.addServices(services)
        let removeServiceFuture = addServicesFuture.flatmap {
            peripheralManager.removeAllServices()
        }
        removeServiceFuture.onSuccess {
            expectation.fulfill()
            let peripheralServices = peripheralManager.services
            XCTAssert(mock.removeAllServicesCalled, "removeAllServices not called")
            XCTAssertEqual(peripheralServices.count, 0, "peripheralManager service count invalid")
        }
        removeServiceFuture.onFailure {error in
            XCTAssert(false, "onFailure called")
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func testRemoveAllServicseWhenAdvertising() {
        let (mock, peripheralManager) = createPeripheralManager(false, state: .PoweredOn)
        let services = createPeripheralManagerServices(peripheralManager)
        let expectation = expectationWithDescription("onFailure fulfilled for future")
        let addServicesFuture = peripheralManager.addServices(services)
        let removeServiceFuture = addServicesFuture.flatmap { Void -> Future<Void> in
            mock.isAdvertising = true
            return peripheralManager.removeAllServices()
        }
        removeServiceFuture.onSuccess {
            XCTAssert(false, "onSuccess called")
        }
        removeServiceFuture.onFailure {error in
            expectation.fulfill()
            let peripheralServices = peripheralManager.services
            XCTAssertFalse(mock.removeServiceCalled, "removeService called")
            XCTAssertEqual(peripheralServices.count, 2, "peripheralManager service count invalid")
            XCTAssertEqual(error.code, BCPeripheralManagerErrorCode.IsAdvertising.rawValue, "error code is invalid")
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

}
