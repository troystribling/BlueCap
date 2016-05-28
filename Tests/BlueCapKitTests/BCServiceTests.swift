//
//  BCServiceTests.swift
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

// MARK: - BCServiceTests -
class BCServiceTests: XCTestCase {
    
    var centralManager: BCCentralManager!
    var mockCharateristics = [
            CBCharacteristicMock(UUID:CBUUID(string:"2f0a0017-69aa-f316-3e78-4194989a6111"), properties:[.Read, .Write], isNotifying:false),
            CBCharacteristicMock(UUID:CBUUID(string:"2f0a0017-69aa-f316-3e78-4194989a6222"), properties:[.Read, .Write], isNotifying:false),
            CBCharacteristicMock(UUID:CBUUID(string:"2f0a0017-69aa-f316-3e78-4194989a6333"), properties:[.Read, .Write], isNotifying:false)].map { $0 as CBCharacteristicInjectable }

    let mockService = CBServiceMock(UUID:CBUUID(string:"2f0a0017-69aa-f316-3e78-4194989a6ccc"))
    let immediateContext = ImmediateContext()
    let RSSI = -45

    func service(peripheral: BCPeripheral) -> BCService {
        return BCService(cbService:self.mockService, peripheral: peripheral)
    }

    func peripheral(state: CBPeripheralState) -> BCPeripheral {
        return BCPeripheral(cbPeripheral: CBPeripheralMock(state: state), centralManager: self.centralManager,    advertisements: peripheralAdvertisements, RSSI: self.RSSI)
    }

    override func setUp() {
        self.centralManager = CentralManagerUT(centralManager:CBCentralManagerMock(state:.PoweredOn))
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    // MARK: Discover characteristics
    func testDiscoverAllCharacteristics_WhenConnectedAndNoErrorInResponce_CompletesSuccessfully() {
        let service = self.service(self.peripheral(.Connected))
        let future = service.discoverAllCharacteristics()
        service.didDiscoverCharacteristics(self.mockCharateristics, error: nil)
        XCTAssertFutureSucceeds(future, context: self.immediateContext) { _ in
            XCTAssert(service.characteristics.count == 3, "Characteristic count invalid")
            XCTAssertEqual(Set(service.characteristics.map { $0.UUID }), Set(self.mockCharateristics.map { $0.UUID }), "Invalid characteristic UUIDs")
        }
    }

    func testDiscoverAllCharacteristics_WhenConnectedAndErrorInResonce_CompeletesWithResponseError() {
        let service = self.service(self.peripheral(.Connected))
        let future = service.discoverAllCharacteristics()
        service.didDiscoverCharacteristics(self.mockCharateristics, error: TestFailure.error)
        XCTAssertFutureFails(future, context: self.immediateContext) { error in
            XCTAssertEqual(error.code, TestFailure.error.code, "Error code invalid")
        }
    }

    func testDiscoverAllCharacteristics_WhenDisconnected_CompeltesWithPeripheralDisconnected() {
        let service = self.service(self.peripheral(.Disconnected))
        let future = service.discoverAllCharacteristics()
        XCTAssertFutureFails(future, context: self.immediateContext) { error in
            XCTAssert(error.code == BCError.peripheralDisconnected.code, "Error code invalid \(error.code)")
        }
    }

    func testDiscoverAllCharacteristics_WhenConnectedOnTimeout_CompletesServiceCharacteristicDiscoveryTimeout() {
        let service = self.service(self.peripheral(.Connected))
        let future = service.discoverAllCharacteristics(0.25)
        XCTAssertFutureFails(future, timeout: 5) { error in
            XCTAssert(error.code == BCError.serviceCharacteristicDiscoveryTimeout.code, "Error code invalid \(error.code)")
        }
    }

    func testDiscoverAllCharacteristics_WhenDiscoveryInProgress_CompletesServiceCharacteristicDiscoveryInProgress() {
        let service = self.service(self.peripheral(.Connected))
        service.discoverAllCharacteristics()
        let future = service.discoverAllCharacteristics()
        XCTAssertFutureFails(future, context: self.immediateContext) { error in
            XCTAssert(error.code == BCError.serviceCharacteristicDiscoveryInProgress.code, "Error code invalid \(error.code)")
        }
    }

}
