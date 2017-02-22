//
//  ServiceTests.swift
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

// MARK: - ServiceTests -
class ServiceTests: XCTestCase {
    
    var centralManager: CentralManager!
    var mockCharateristics = [
            CBCharacteristicMock(uuid: CBUUID(string:"2f0a0017-69aa-f316-3e78-4194989a6111"), properties:[.read, .write], isNotifying:false),
            CBCharacteristicMock(uuid: CBUUID(string:"2f0a0017-69aa-f316-3e78-4194989a6222"), properties:[.read, .write], isNotifying:false),
            CBCharacteristicMock(uuid: CBUUID(string:"2f0a0017-69aa-f316-3e78-4194989a6333"), properties:[.read, .write], isNotifying:false)].map { $0 as CBCharacteristicInjectable }

    var duplicateMockCharateristics = [
        CBCharacteristicMock(uuid: CBUUID(string:"2f0a0017-69aa-f316-3e78-4194989a6111"), properties:[.read, .write], isNotifying:false),
        CBCharacteristicMock(uuid: CBUUID(string:"2f0a0017-69aa-f316-3e78-4194989a6222"), properties:[.read, .write], isNotifying:false),
        CBCharacteristicMock(uuid: CBUUID(string:"2f0a0017-69aa-f316-3e78-4194989a6222"), properties:[.read, .write], isNotifying:false)]

    let mockService = CBServiceMock(uuid: CBUUID(string:"2f0a0017-69aa-f316-3e78-4194989a6ccc"))
    let immediateContext = ImmediateContext()
    let RSSI = -45

    func createService(withPeripheral peripheral: Peripheral) -> Service {
        return Service(cbService:self.mockService, peripheral: peripheral)
    }

    func peripheral(_ state: CBPeripheralState) -> Peripheral {
        return Peripheral(cbPeripheral: CBPeripheralMock(state: state), centralManager: self.centralManager,    advertisements: peripheralAdvertisements, RSSI: self.RSSI)
    }

    override func setUp() {
        self.centralManager = CentralManagerUT(centralManager:CBCentralManagerMock(state:.poweredOn))
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    // MARK: Discover characteristics
    func testDiscoverAllCharacteristics_WhenConnectedAndNoErrorInResponce_CompletesSuccessfully() {
        let service = createService(withPeripheral: peripheral(.connected))
        let future = service.discoverAllCharacteristics()
        service.didDiscoverCharacteristics(self.mockCharateristics, error: nil)
        XCTAssertFutureSucceeds(future, context: self.immediateContext) { _ in
            XCTAssert(service.characteristics.count == 3)
            XCTAssertEqual(Set(service.characteristics.map { $0.uuid }), Set(self.mockCharateristics.map { $0.uuid }))
        }
    }

    func testDiscoverAllCharacteristics_WhenConnectedAndErrorInResonce_CompeletesWithResponseError() {
        let service = createService(withPeripheral: peripheral(.connected))
        let future = service.discoverAllCharacteristics()
        service.didDiscoverCharacteristics(self.mockCharateristics, error: TestFailure.error)
        XCTAssertFutureFails(future, context: self.immediateContext) { error in
            XCTAssertEqualErrors(error, TestFailure.error)
        }
    }

    func testDiscoverAllCharacteristics_WhenDisconnected_CompeltesWithPeripheralDisconnected() {
        let service = createService(withPeripheral: peripheral(.disconnected))
        let future = service.discoverAllCharacteristics()
        XCTAssertFutureFails(future, context: self.immediateContext) { error in
            XCTAssertEqualErrors(error, PeripheralError.disconnected)
        }
    }

    func testDiscoverAllCharacteristics_WhenConnectedOnTimeout_CompletesServiceCharacteristicDiscoveryTimeout() {
        let service = createService(withPeripheral: peripheral(.connected))
        let future = service.discoverAllCharacteristics(timeout: 0.25)
        XCTAssertFutureFails(future, timeout: 5) { error in
            XCTAssertEqualErrors(error, ServiceError.characteristicDiscoveryTimeout)
        }
    }

    func testDiscoverAllCharacteristics_WithDuplicateUUIDs_CompletesSuccessfully() {
        let service = createService(withPeripheral: peripheral(.connected))
        let future = service.discoverAllCharacteristics()
        service.didDiscoverCharacteristics(duplicateMockCharateristics.map { $0 as CBCharacteristicInjectable }, error: nil)
        XCTAssertFutureSucceeds(future, context: self.immediateContext) { _ in
            XCTAssert(service.characteristics.count == 3)
            XCTAssertEqual(service.characteristics(withUUID: self.duplicateMockCharateristics[0].uuid)!.count, 1)
            XCTAssertEqual(service.characteristics(withUUID: self.duplicateMockCharateristics[1].uuid)!.count, 2)
        }
    }

}
