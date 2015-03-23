//
//  CentralManagerTests.swift
//  BlueCapKit
//
//  Created by Troy Stribling on 1/7/15.
//  Copyright (c) 2015 gnos.us. All rights reserved.
//

import UIKit
import XCTest
import CoreBluetooth
import BlueCapKit

class CentralManagerTests: XCTestCase {
    
    // CentralManagerMock
    class CentralManagerMock : CentralManagerWrappable {
        
        let impl = CentralManagerImpl<CentralManagerMock>()
        
        var _state : CBCentralManagerState
        let _peripherals = [PeripheralMock(name:"Peripheral-1"), PeripheralMock(name:"Peripheral-2")]
        
        var poweredOn : Bool {
            return self.state == CBCentralManagerState.PoweredOn
        }
        
        var poweredOff : Bool {
            return self.state == CBCentralManagerState.PoweredOff
        }
        
        var peripherals : [PeripheralMock] {
            return self._peripherals
        }
        
        var state: CBCentralManagerState {
            return self._state
        }
        
        init(state:CBCentralManagerState = .PoweredOn) {
            self._state = state
        }
        
        func scanForPeripheralsWithServices(uuids:[CBUUID]!) {
        }
        
        func stopScan() {
        }

    }
    
    class PeripheralMock : PeripheralWrappable {
        
        let impl = PeripheralImpl<PeripheralMock>()
        
        var _state :CBPeripheralState
        var _name : String
        
        let _services = [ServiceMock(uuid:CBUUID(string:"2f0a0017-69aa-f316-3e78-4194989a6ccc"), name:"Service Mock-1"),
                         ServiceMock(uuid:CBUUID(string:"2f0a0017-69aa-f316-3e78-4194989a6aaa"), name:"Service Mock-2")]
        
        var name : String {
            return self._name
        }
        
        var state: CBPeripheralState {
            return self._state
        }
        
        var services : [ServiceMock] {
            return self._services
        }
        
        init(name:String, state:CBPeripheralState = .Disconnected) {
            self._state = state
            self._name = name
        }
        
        func connect() {
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

    final class ServiceMock : ServiceWrappable {
        
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
                self.impl.didDiscoverCharacteristics(self, error:nil)
            }
        }
        
        func createCharacteristics() {
        }
        
        func discoverAllCharacteristics() -> Future<ServiceMock> {
            let future = self.impl.discoverIfConnected(self, characteristics:nil)
            self.didDiscoverCharacteristics(nil)
            return future
        }
    }
    
    // CentralManagerMock

    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }

    func testPowerOn() {
    }
    
    func testPowerOff() {
    }
    
    func testStartPromiscuousScanning() {
    }

    func testStartServiceScanning() {        
    }

    func testStopScanning() {
        
    }
    
    func testDisconnectAllPeripherals() {
        
    }

}
