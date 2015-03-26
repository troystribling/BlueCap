//
//  PeripheralManagerTests.swift
//  BlueCapKit
//
//  Created by Troy Stribling on 3/25/15.
//  Copyright (c) 2015 gnos.us. All rights reserved.
//

import UIKit
import XCTest
import CoreBluetooth
import BlueCapKit

class PeripheralManagerTests: XCTestCase {

    // PeripheralmanagerMock
    class PeripheralmanagerMock : PeripheralManagerWrappable {
        
        var _isAdvertising = false
        var _services : [MutableServiceMock] = []
        var _state : CBPeripheralManagerState
        
        var isAdvertising : Bool {
            return self._isAdvertising
        }
        
        var state : CBPeripheralManagerState {
            return self._state
        }
        
        var services : [MutableServiceMock] {
            return self._services
        }
        
        init(isAdvertising:Bool = false, state:CBPeripheralManagerState = .PoweredOff) {
            self._isAdvertising = isAdvertising
            self._state = state
        }
        
        func startAdvertising(advertisementData:[NSObject:AnyObject]) {
            self._isAdvertising = true
        }
        
        func startAdversting(beaconRegion:BeaconRegionMock) {
            self._isAdvertising = true
        }
        
        func stopAdvertising() {
            self._isAdvertising = false
        }
        
        func addWrappedService(service:MutableServiceMock) {
            self._services.append(service)
        }
        
        func removeWrappedService(service:MutableServiceMock) {
            self._services.removeAtIndex(0)
        }
        
        func removeAllWrappedServices() {
            self._services.removeAll(keepCapacity:false)
        }

    }
    
    class MutableServiceMock : MutableServiceWrappable {

        var uuid : CBUUID  {
            return CBUUID(string:"2f0a0017-69aa-f316-3e78-4194989a6c1a")
        }
        
        var name : String {
            return "Mock"
        }
    }
    
    class BeaconRegionMock : BeaconRegionWrappable {
        
        let promise = StreamPromise<[BeaconMock]>()
        
        var identifier : String {
            return "ID"
        }
        
        var beaconPromise  : StreamPromise<[BeaconMock]> {
            return self.promise
        }
        
        func peripheralDataWithMeasuredPower(measuredPower:Int?) -> [NSObject:AnyObject] {
            return [:]
        }
    }
    
    class BeaconMock : BeaconWrappable {
        
    }

    // PeripheralmanagerMock
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }

    func testPowerOnWhenPoweredOn() {        
    }

    func testPowerOnWhenPoweredOff() {
    }

    func testPowerOffWhenPoweredOn() {
    }

    func testPowerOffWhenPoweredOff() {
    }

    func testStartAdvertisingSuccess() {
    }

    func testStartAdvertisingFailure() {
    }

    func testStartAdvertisingBeaconSuccess() {
    }

    func testStartAdvertisingBeaconFailure() {
    }

    func testStopAdvertising() {
    }

    func testAddServiceSuccess() {
    }

    func testAddServiceFailure() {
    }

    func testAddServiceWhenAdvertising() {
    }

    func testRemoveServiceSuccess() {
    }

    func testRemoveServiceFailure() {
    }
    
    func testRemoveSErviceWhenAdvertising() {
    }
}
