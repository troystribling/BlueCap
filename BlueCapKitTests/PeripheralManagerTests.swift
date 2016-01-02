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

    let peripheralName  = "Test Peripheral"
    let advertisedUUIDs = CBUUID(string:Gnosus.HelloWorldService.Greeting.uuid)
  
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
        GnosusProfiles.create()
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }

    func createPeripheral(isAdvertising: Bool, state: CBPeripheralManagerState) -> (CBPeripheralManagerMock, PeripheralManagerUT) {
        let mock = CBPeripheralManagerMock(isAdvertising: isAdvertising, state: state)
        return (mock, PeripheralManagerUT(peripheralManager:mock))
    }
    
    func createServices(peripheral: PeripheralManager) -> [MutableService] {
        let profileManager = ProfileManager.sharedInstance
        return [MutableService(profile: profileManager.service[CBUUID(string: Gnosus.HelloWorldService.uuid)]!, peripheralManager: peripheral), MutableService(profile: profileManager.service[CBUUID(string: Gnosus.LocationService.uuid)]!, peripheralManager: peripheral)]
    }
    
    func testPowerOnWhenPoweredOn() {
        let (_, peripheralManager) = self.createPeripheral(false, state: .PoweredOn)
        let expectation = expectationWithDescription("onSuccess fulfilled for future")
        let future = peripheralManager.powerOn()
        future.onSuccess {
            expectation.fulfill()
        }
        future.onFailure {error in
            XCTAssert(false, "onFailure called")
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testPowerOnWhenPoweredOff() {
        let (mock, peripheralManager) = self.createPeripheral(false, state: .PoweredOff)
        let expectation = expectationWithDescription("onSuccess fulfilled for future")
        let future = peripheralManager.powerOn()
        future.onSuccess {
            expectation.fulfill()
        }
        future.onFailure {error in
            XCTAssert(false, "onFailure called")
        }
        mock.state = .PoweredOn
        peripheralManager.didUpdateState()
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testPowerOffWhenPoweredOn() {
        let (mock, peripheralManager) = self.createPeripheral(false, state: .PoweredOn)
        let expectation = expectationWithDescription("onSuccess fulfilled for future")
        let future = peripheralManager.powerOff()
        future.onSuccess {
            expectation.fulfill()
        }
        future.onFailure {error in
            XCTAssert(false, "onFailure called")
        }
        mock.state = .PoweredOff
        peripheralManager.didUpdateState()
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testPowerOffWhenPoweredOff() {
        let (_, peripheralManager) = self.createPeripheral(false, state: .PoweredOff)
        let expectation = expectationWithDescription("onSuccess fulfilled for future")
        let future = peripheralManager.powerOff()
        future.onSuccess {
            expectation.fulfill()
        }
        future.onFailure {error in
            XCTAssert(false, "onFailure called")
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testStartAdvertisingSuccess() {
        let (mock, peripheralManager) = self.createPeripheral(false, state: .PoweredOn)
        let expectation = expectationWithDescription("onSuccess fulfilled for future")
        let future = peripheralManager.startAdvertising(self.peripheralName, uuids:[self.advertisedUUIDs])
        future.onSuccess {
            expectation.fulfill()
            XCTAssert(mock.startAdvertisingCalled, "startAdvertising not called")
            if let advertisedData = mock.advertisementData,
                   name = advertisedData[CBAdvertisementDataLocalNameKey] as? String,
                   uuids = advertisedData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID] {
                XCTAssertEqual(name, self.peripheralName, "peripheralName invalid")
                XCTAssertEqual(uuids[0], self.advertisedUUIDs, "advertised UUIDs invalid")
            } else {
                XCTAssert(false, "advertisementData not found")
            }
        }
        future.onFailure {error in
            XCTAssert(false, "onFailure called")
        }
        peripheralManager.didStartAdvertising(nil)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testStartAdvertisingFailure() {
        let (mock, peripheralManager) = self.createPeripheral(false, state: .PoweredOn)
        let expectation = expectationWithDescription("onFailure fulfilled for future")
        let future = peripheralManager.startAdvertising(self.peripheralName, uuids:[self.advertisedUUIDs])
        future.onSuccess {
            XCTAssert(false, "onSuccess called")
        }
        future.onFailure {error in
            expectation.fulfill()
            XCTAssertEqual(error.code, TestFailure.error.code, "error code invalid")
            XCTAssert(mock.startAdvertisingCalled, "startAdvertising not called")
            if let advertisedData = mock.advertisementData,
                name = advertisedData[CBAdvertisementDataLocalNameKey] as? String,
                uuids = advertisedData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID] {
                    XCTAssertEqual(name, self.peripheralName, "peripheralName invalid")
                    XCTAssertEqual(uuids[0], self.advertisedUUIDs, "advertised UUIDs invalid")
            } else {
                XCTAssert(false, "advertisementData not found")
            }
        }
        peripheralManager.didStartAdvertising(TestFailure.error)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testStartAdvertisingWhenAdvertising() {
        let (mock, peripheralManager) = self.createPeripheral(true, state: .PoweredOn)
        let expectation = expectationWithDescription("onFailure fulfilled for future")
        let future = peripheralManager.startAdvertising(self.peripheralName, uuids:[self.advertisedUUIDs])
        future.onSuccess {
            XCTAssert(false, "onSuccess called")
        }
        future.onFailure {error in
            expectation.fulfill()
            XCTAssertEqual(error.code, PeripheralManagerError.IsAdvertising.rawValue, "Error code is invalid")
            XCTAssert(mock.advertisementData == nil, "advertisementData found")
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
//    func testStartAdvertisingBeaconSuccess() {
//        let mock = PeripheralManagerMock(isAdvertising:false, state:.PoweredOn)
//        let expectation = expectationWithDescription("onSuccess fulfilled for future")
//        let future = mock.impl.startAdvertising(mock, region:BeaconRegionMock())
//        future.onSuccess {
//            expectation.fulfill()
//        }
//        future.onFailure {error in
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
//        future.onFailure {error in
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
//        future.onFailure {error in
//            XCTAssert(error.code == PeripheralManagerError.IsAdvertising.rawValue, "Error code is invalid \(error.code)")
//            expectation.fulfill()
//        }
//        waitForExpectationsWithTimeout(2) {error in
//            XCTAssertNil(error, "\(error)")
//        }
//    }

    func testStopAdvertising() {
        let (mock, peripheralManager) = self.createPeripheral(true, state: .PoweredOn)
        let expectation = expectationWithDescription("onSuccess fulfilled for future")
        let future = peripheralManager.stopAdvertising()
        future.onSuccess {
            expectation.fulfill()
            XCTAssert(mock.stopAdvertisingCalled, "stopAdvertisingCalled not called")
        }
        future.onFailure {error in
            XCTAssert(false, "onFailure called")
        }
        mock.isAdvertising = false
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testStopAdvertisingWhenNotAdvertsing() {
        let (mock, peripheralManager) = self.createPeripheral(false, state: .PoweredOn)
        let expectation = expectationWithDescription("onFailure fulfilled for future")
        let future = peripheralManager.stopAdvertising()
        future.onSuccess {
            XCTAssert(false, "onSuccess called")
        }
        future.onFailure {error in
            XCTAssertEqual(error.code, PeripheralManagerError.IsNotAdvertising.rawValue, "Error code is invalid")
            XCTAssertFalse(mock.stopAdvertisingCalled, "stopAdvertisingCalled called")
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func testAddServiceSuccess() {
        let (mock, peripheralManager) = self.createPeripheral(false, state: .PoweredOn)
        let services = self.createServices(peripheralManager)
        let expectation = expectationWithDescription("onSuccess fulfilled for future")
        let future = peripheralManager.addService(services[0])
        future.onSuccess {
            expectation.fulfill()
            let peripheralServices = peripheralManager.services
            XCTAssert(mock.addServiceCalled, "addService not called")
            XCTAssertEqual(peripheralServices.count, 1, "peripheralManager service count invalid")
            XCTAssertEqual(peripheralServices[0].uuid, services[0].uuid, "addedService has invalid UUID")
            if let addedService = mock.addedService {
                XCTAssertEqual(services[0].uuid, addedService.UUID, "addedService UUID invalid")
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
        let (mock, peripheralManager) = self.createPeripheral(false, state: .PoweredOn)
        let services = self.createServices(peripheralManager)
        let expectation = expectationWithDescription("onSuccess fulfilled for future")
        let future = peripheralManager.addServices(services)
        future.onSuccess {
            expectation.fulfill()
            let peripheralServices = peripheralManager.services
            XCTAssert(mock.addServiceCalled, "addService not called")
            XCTAssertEqual(peripheralServices.count, 2, "peripheralManager service count invalid")
            XCTAssertEqual(peripheralServices[0].uuid, services[0].uuid, "addedService has invalid UUID")
            XCTAssertEqual(peripheralServices[1].uuid, services[1].uuid, "addedService has invalid UUID")
        }
        future.onFailure {error in
            XCTAssert(false, "onFailure called")
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testAddServicesFailure() {
        let (mock, peripheralManager) = self.createPeripheral(false, state: .PoweredOn)
        let services = self.createServices(peripheralManager)
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
        let (mock, peripheralManager) = self.createPeripheral(false, state: .PoweredOn)
        let services = self.createServices(peripheralManager)
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
        let (mock, peripheralManager) = self.createPeripheral(true, state: .PoweredOn)
        let services = self.createServices(peripheralManager)
        let expectation = expectationWithDescription("onFailure fulfilled for future")
        let future = peripheralManager.addService(services[0])
        future.onSuccess {
            XCTAssert(false, "onSuccess called")
        }
        future.onFailure {error in
            expectation.fulfill()
            let peripheralServices = peripheralManager.services
            XCTAssertEqual(error.code, PeripheralManagerError.IsAdvertising.rawValue, "error code is invalid")
            XCTAssertFalse(mock.addServiceCalled, "addService called")
            XCTAssertEqual(peripheralServices.count, 0, "peripheralManager service count invalid")
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testRemoveServiceSuccess() {
        let (mock, peripheralManager) = self.createPeripheral(false, state: .PoweredOn)
        let services = self.createServices(peripheralManager)
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
            XCTAssertEqual(peripheralServices[0].uuid, services[1].uuid, "addedService has invalid UUID")
            if let removedService = mock.removedService {
                XCTAssertEqual(removedService.UUID, services[0].uuid, "addedService has invalid UUID")
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
        let (mock, peripheralManager) = self.createPeripheral(false, state: .PoweredOn)
        let services = self.createServices(peripheralManager)
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
            XCTAssertEqual(error.code, PeripheralManagerError.IsAdvertising.rawValue, "error code is invalid")
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testRemoveAllServiceSuccess() {
        let (mock, peripheralManager) = self.createPeripheral(false, state: .PoweredOn)
        let services = self.createServices(peripheralManager)
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
        let (mock, peripheralManager) = self.createPeripheral(false, state: .PoweredOn)
        let services = self.createServices(peripheralManager)
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
            XCTAssertEqual(error.code, PeripheralManagerError.IsAdvertising.rawValue, "error code is invalid")
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

}
