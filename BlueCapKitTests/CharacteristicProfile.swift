//
//  CharacteristicProfile.swift
//  BlueCapKit
//
//  Created by Troy Stribling on 4/12/16.
//  Copyright © 2016 Troy Stribling. All rights reserved.
//

import UIKit
import XCTest
import CoreBluetooth
@testable import BlueCapKit

class CharacteristicProfile: XCTestCase {

    var centralManager: BCCentralManager!
    var service: BCService!
    let mockPerpheral = CBPeripheralMock(state: .Connected)
    let mockService = CBServiceMock(UUID: CBUUID(string: Gnosus.HelloWorldService.UUID))
    let mockCharacteristic = CBCharacteristicMock(UUID: CBUUID(string: Gnosus.HelloWorldService.Greeting.UUID), properties: [.Read, .Write], isNotifying: false)

    var peripheral: BCPeripheral!
    let RSSI = -45

    override func setUp() {
        super.setUp()
        GnosusProfiles.create()
        self.centralManager = CentralManagerUT(centralManager: CBCentralManagerMock(state: .PoweredOn))
        self.peripheral = BCPeripheral(cbPeripheral: self.mockPerpheral, centralManager: self.centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        self.service  = BCService(cbService: self.mockService, peripheral: self.peripheral)
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    // MARK: After discovered
    func testAfterDiscovered_WhenCharacteristicIsDiscovered_CompletesSuccessfully() {
        let onSuccessExpectation = expectationWithDescription("onSuccess fulfilled for future")
        let serviceProfile = BCProfileManager.sharedInstance.services[CBUUID(string: Gnosus.HelloWorldService.UUID)]
        let characteristicProfile = serviceProfile?.characteristic[CBUUID(string: Gnosus.HelloWorldService.Greeting.UUID)]
        characteristicProfile?.afterDiscovered().onSuccess { _ in
            onSuccessExpectation.fulfill()
        }
        characteristicProfile?.afterDiscovered().onFailure { error in
            XCTFail("onFailure called")
        }
        service.didDiscoverCharacteristics([self.mockCharacteristic], error: nil)
        waitForExpectationsWithTimeout(2) { error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testAfterDiscovered_WhenCharacteristicDiscoveryFailes_CompletesWithFailure() {
        let onFailureExpectation = expectationWithDescription("onFailuree fulfilled for future")
        let serviceProfile = BCProfileManager.sharedInstance.services[CBUUID(string: Gnosus.HelloWorldService.UUID)]
        let characteristicProfile = serviceProfile?.characteristic[CBUUID(string: Gnosus.HelloWorldService.Greeting.UUID)]
        characteristicProfile?.afterDiscovered().onSuccess { _ in
            XCTFail("onSuccess called")
        }
        characteristicProfile?.afterDiscovered().onFailure { error in
            XCTAssertEqual(error.code, TestFailure.error.code, "Error code is invalid")
            onFailureExpectation.fulfill()
        }
        service.didDiscoverCharacteristics([self.mockCharacteristic], error: TestFailure.error)
        waitForExpectationsWithTimeout(2) { error in
            XCTAssertNil(error, "\(error)")
        }
    }

}
