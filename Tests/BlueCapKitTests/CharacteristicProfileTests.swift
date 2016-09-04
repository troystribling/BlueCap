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

class CharacteristicProfileTests: XCTestCase {

    var centralManager: CentralManager!
    var service: Service!
    let mockPerpheral = CBPeripheralMock(state: .connected)
    let mockService = CBServiceMock(UUID: CBUUID(string: Gnosus.HelloWorldService.UUID))
    let mockCharacteristic = CBCharacteristicMock(UUID: CBUUID(string: Gnosus.HelloWorldService.Greeting.UUID), properties: [.read, .write], isNotifying: false)

    var peripheral: Peripheral!
    var serviceProfile: ServiceProfile!
    let RSSI = -45

    override func setUp() {
        GnosusProfiles.create(profileManager: profileManager)
        super.setUp()
        self.centralManager = CentralManagerUT(centralManager: CBCentralManagerMock(state: .poweredOn), profileManager: profileManager)
        self.peripheral = Peripheral(cbPeripheral: self.mockPerpheral, centralManager: self.centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI, profileManager: profileManager)
        serviceProfile = profileManager.services[CBUUID(string: Gnosus.HelloWorldService.UUID)]!
        self.service  = Service(cbService: self.mockService, peripheral: self.peripheral, profile: serviceProfile)
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    // MARK: After discovered
    func testAfterDiscovered_WhenCharacteristicIsDiscovered_CompletesSuccessfully() {
        let characteristicProfile = serviceProfile.characteristic[CBUUID(string: Gnosus.HelloWorldService.Greeting.UUID)]!
        let future = characteristicProfile.afterDiscovered()
        service.didDiscoverCharacteristics([self.mockCharacteristic], error: nil)
        XCTAssertFutureStreamSucceeds(future, context: TestContext.immediate, validations: [
            { characteristic in
                XCTAssertEqual(characteristic.UUID, characteristicProfile.UUID)
            }
        ])
    }

    func testAfterDiscovered_WhenCharacteristicDiscoveryFails_CompletesWithFailure() {
        let characteristicProfile = serviceProfile.characteristic[CBUUID(string: Gnosus.HelloWorldService.Greeting.UUID)]!
        let future = characteristicProfile.afterDiscovered()
        service.didDiscoverCharacteristics([self.mockCharacteristic], error: TestFailure.error)
        XCTAssertFutureStreamFails(future, context: TestContext.immediate, validations: [
            { error in
                XCTAssertEqualErrors(error, TestFailure.error)
            }
        ])
    }

}
