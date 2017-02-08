//
//  CentralManagerTests.swift
//  BlueCapKit
//
//  Created by Troy Stribling on 1/7/15.
//  Copyright (c) 2015 Troy Stribling. The MIT License (MIT).
//

import UIKit
import XCTest
import CoreBluetooth
@testable import BlueCapKit

// MARK - CentralManagerTests -

class CentralManagerTests: XCTestCase {

    let RSSI = -45

    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }

    // MARK: whenStateChanges

    func testWhenStateChangesOnStateChange_CompletesSuccessfully() {
        let mock = CBCentralManagerMock(state: .poweredOff)
        let centralManager = CentralManager(centralManager: mock)
        let stream = centralManager.whenStateChanges()
        mock.state = .poweredOn
        centralManager.didUpdateState(mock)
        XCTAssertFutureStreamSucceeds(stream, context: TestContext.immediate, validations: [
            { state in
                XCTAssertEqual(state, .poweredOff)
            },
            { state in
                XCTAssertEqual(state, .poweredOn)
            }
        ])
    }

    // MARK: Peripheral discovery

    func testStartScanning_WhenPoweredOnAndPeripheralDiscovered_CompletesSuccessfully() {
        let centralMock = CBCentralManagerMock(state: .poweredOn)
        let centralManager = CentralManager(centralManager: centralMock)
        let peripheralMock = CBPeripheralMock()
        let stream = centralManager.startScanning()
        centralManager.didDiscoverPeripheral(peripheralMock, advertisementData: peripheralAdvertisements, RSSI: NSNumber(value: -45))
        XCTAssertFutureStreamSucceeds(stream, context: TestContext.immediate, validations: [
            { _ in
                XCTAssert(centralMock.scanForPeripheralsWithServicesCalled)
                if let peripheral = centralManager.peripherals.first, centralManager.peripherals.count == 1 {
                    XCTAssert(peripheralMock.setDelegateCalled)
                    XCTAssertEqual(peripheral.name, peripheralMock.name)
                    XCTAssertEqual(peripheral.identifier, peripheralMock.identifier)
                } else {
                    XCTFail("Discovered peripheral missing")
                }
            }
        ])
    }
    
    func testStartScanning_WhenPoweredOff_CompletesWithError() {
        let centralMock = CBCentralManagerMock(state: .poweredOff)
        let centralManager = CentralManager(centralManager: centralMock)
        let future = centralManager.startScanning()
        XCTAssertFutureStreamFails(future, context: TestContext.immediate, validations: [
            { error in
                XCTAssertFalse(centralMock.scanForPeripheralsWithServicesCalled)
                XCTAssertEqualErrors(error, CentralManagerError.isPoweredOff)
            }
        ])
    }

    func testStartScanning_WithTimeoutPeripeharlDiscovered_CompeletesSuccessfully() {
        let mock = CBCentralManagerMock(state: .poweredOn)
        let centralManager = CentralManager(centralManager: mock)
        let peripheralMock = CBPeripheralMock()
        let future = centralManager.startScanning(timeout: 1.0)
        centralManager.didDiscoverPeripheral(peripheralMock, advertisementData: peripheralAdvertisements, RSSI: NSNumber(value: -45))
        XCTAssertFutureStreamSucceeds(future, context:TestContext.immediate, validations: [
            { peripheral in
                XCTAssertEqual(peripheral.identifier, peripheralMock.identifier)
            }
        ])
    }

    func testStartScanning_OnScanTimeout_CompletesWithPeripheralScanTimeout() {
        let mock = CBCentralManagerMock(state: .poweredOn)
        let centralManager = CentralManager(centralManager: mock)
        let future = centralManager.startScanning(timeout: 0.1)
        XCTAssertFutureStreamFails(future, validations: [
            {error in
                XCTAssertEqualErrors(error, CentralManagerError.serviceScanTimeout)
            }
        ])
    }

    func testStartScanning_WhenInvalidPeripheralDiscovered_CompletesWithError() {
        let centralMock = CBCentralManagerMock(state: .poweredOn)
        let centralManager = CentralManager(centralManager: centralMock)

        let peripheralMockOrig = CBPeripheralMock()
        let peripheralOrig = Peripheral(cbPeripheral: peripheralMockOrig, centralManager: centralManager, advertisements: peripheralAdvertisements, RSSI: RSSI)
        centralManager._discoveredPeripherals[peripheralOrig.identifier] = peripheralOrig

        let peripheralMockInvalid = CBPeripheralMock(identifier: peripheralMockOrig.identifier)
        let stream = centralManager.startScanning()

        centralManager.didDiscoverPeripheral(peripheralMockInvalid, advertisementData: peripheralAdvertisements, RSSI: NSNumber(value: -45))
        XCTAssertFutureStreamFails(stream, context: TestContext.immediate, validations: [
            { error in
                XCTAssert(centralMock.scanForPeripheralsWithServicesCalled)
                XCTAssertEqualErrors(error, CentralManagerError.invalidPeripheral)
            }
        ])
    }

    // MARK: State Restoration

    func testWhenStateRestored_WithPreviousValidState_CompletesSuccessfully() {
        let mock = CBCentralManagerMock()
        let centralManager = CentralManager(centralManager: mock)
        let testScannedServices = [CBUUID(string: UUID().uuidString), CBUUID(string: UUID().uuidString)]
        let testPeripherals = [CBPeripheralMock(state: .connected), CBPeripheralMock(state: .connected)]
        for testPeripheral in testPeripherals {
            let testServices = [CBServiceMock(uuid: testScannedServices[0]), CBServiceMock(uuid: testScannedServices[1])]
            for testService in testServices {
                let testCharacteristics = [CBCharacteristicMock(), CBCharacteristicMock()]
                testService.characteristics = testCharacteristics
            }
            testPeripheral.services = testServices
        }
        let testOptions: [String: AnyObject] = [CBCentralManagerOptionShowPowerAlertKey: NSNumber(value: true),
                                                CBCentralManagerOptionRestoreIdentifierKey: "us.gnos.bluecap.test" as AnyObject]
        let future = centralManager.whenStateRestored()
        centralManager.willRestoreState(testPeripherals.map { $0 as CBPeripheralInjectable },
                                        scannedServices: testScannedServices, options: testOptions)
        XCTAssertFutureSucceeds(future, context: TestContext.immediate) {
            guard let options = centralManager.options else {
                XCTFail()
                return
            }
            let peripherals = centralManager.peripherals
            let scannedServices = centralManager.services.map { $0.uuid }
            XCTAssertEqual(peripherals.count, testPeripherals.count)
            XCTAssertEqual(Set(scannedServices), Set(testScannedServices))
            XCTAssertEqual(options[CBCentralManagerOptionShowPowerAlertKey]! as? NSNumber, testOptions[CBCentralManagerOptionShowPowerAlertKey]! as? NSNumber)
            XCTAssertEqual(options[CBCentralManagerOptionRestoreIdentifierKey]! as? NSString, testOptions[CBCentralManagerOptionRestoreIdentifierKey]! as? NSString)
            XCTAssertEqual(Set(peripherals.map { $0.identifier }), Set(testPeripherals.map { $0.identifier }))
            for testPeripheral in testPeripherals {
                let peripheral = centralManager.discoveredPeripherals[testPeripheral.identifier]
                XCTAssertNotNil(peripheral)
                let services = peripheral!.services
                let testServices = testPeripheral.services!
                XCTAssertEqual(services.count, testServices.count)
                XCTAssertEqual(Set(services.map { $0.uuid }), Set(testServices.map { $0.uuid }))
                for testService in testServices {
                    let testCharacteristics = testService.characteristics!
                    let service = peripheral!.discoveredServices[testService.uuid]
                    let characteristics = service!.first!.characteristics
                    XCTAssertEqual(characteristics.count, testCharacteristics.count)
                    XCTAssertEqual(Set(characteristics.map { $0.uuid }), Set(testCharacteristics.map { $0.uuid }))
                }
            }
        }
    }

    func testWhenStateRestored_WithPreviousInvalidState_CompletesWithCentralRestoreFailed() {
        let mock = CBCentralManagerMock()
        let centralManager = CentralManager(centralManager: mock)
        let future = centralManager.whenStateRestored()
        centralManager.willRestoreState(nil, scannedServices: nil, options: nil)
        XCTAssertFutureFails(future, context: TestContext.immediate) { error in
                XCTAssertEqualErrors(error, CentralManagerError.restoreFailed)
        }
    }
}
