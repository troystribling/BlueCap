//
//  BCTimedScanneratorTests.swift
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

// MARK: - BCTimedScanneratorTests -
class BCTimedScanneratorTests: XCTestCase {
    
    var centralManager: BCCentralManager!
    let mockPerpheral = CBPeripheralMock()
    let immediateContext = ImmediateContext()

    override func setUp() {
        self.centralManager = CentralManagerUT(centralManager: CBCentralManagerMock(state: .PoweredOn))
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }

    // MARK: Scan timeout
    func testStartScanning_WhenPeripeharlDiscovered_CompeletesSuccessfully() {
        let scannerator = BCTimedScannerator(centralManager: self.centralManager)
        let future = scannerator.startScanning(2)
        self.centralManager.didDiscoverPeripheral(self.mockPerpheral, advertisementData:peripheralAdvertisements, RSSI:NSNumber(integer: -45))
        XCTAssertFutureStreamSucceeds(future, context:self.immediateContext, validations: [
            { peripheral in
                XCTAssertEqual(peripheral.identifier, self.mockPerpheral.identifier, "Peripheral identifier timeout")
            }
        ])
    }
    
    func testStartScanning_OnScanTimeout_CompletesWithPeripheralScanTimeout() {
        let scannerator = BCTimedScannerator(centralManager :self.centralManager)
        let future = scannerator.startScanning(1)
        XCTAssertFutureStreamFails(future, validations: [
            {error in
                XCTAssertEqual(BCError.centralPeripheralScanTimeout.code, error.code, "onFailure error invalid")
            }
        ])
    }

}
