//
//  BeaconManagerTests.swift
//  FutureLocation
//
//  Created by Troy Stribling on 3/29/15.
//  Copyright (c) 2015 Troy Stribling. The MIT License (MIT).
//

import UIKit
import XCTest
import CoreLocation
@testable import BlueCapKit

class BeaconManagerTests: XCTestCase {

    let testCLBeaconRegion = CLBeaconRegion(proximityUUID: UUID(), major: 1, minor: 2, identifier: "Test Beaccon")
    let testCLBeacons = [
        CLBeaconMock(proximityUUID: UUID() as NSUUID, major: 1, minor: 2, proximity: .immediate, accuracy: kCLLocationAccuracyBest, rssi: -45), CLBeaconMock(proximityUUID: UUID() as NSUUID, major: 1, minor: 2, proximity: .far, accuracy: kCLLocationAccuracyBest, rssi: -85)]

    var testBeaconRegion: FLBeaconRegion!
    var mock: CLLocationManagerMock!
    var beaconManager: BeaconManagerUT!

    override func setUp() {
        super.setUp()
        self.testBeaconRegion = FLBeaconRegion(region: self.testCLBeaconRegion)
        self.mock = CLLocationManagerMock()
        self.beaconManager = BeaconManagerUT(clLocationManager: self.mock)
    }

    override func tearDown() {
        super.tearDown()
    }

    func waitForExpectations(_ timeout: Double = 2.0) {
        waitForExpectations(timeout: timeout) { error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testStartRangingRegionSuccess() {
        CLLocationManagerMock._authorizationStatus = .authorizedAlways
        let expectation = self.expectation(description: "onSuccess fulfilled for future")
        let context = ImmediateContext()
        let future = self.beaconManager.startRangingBeaconsInRegion(self.testBeaconRegion, context: context)
        future.onSuccess(context) { beacons in
            XCTAssertEqual(beacons.count, 2, "Beacon count invalid")
            XCTAssertEqual(self.beaconManager.beaconRegions.count, 1, "BeaconRegion count invalid")
            XCTAssertEqual(self.testBeaconRegion.beacons.count, 2, "Region Beacon count invalid")
            XCTAssert(self.beaconManager.isRanging, "isRanging invalid")
            XCTAssert(self.mock.startRangingBeaconsInRegionCalled, "startRangingBeaconsInRegion not called")
            expectation.fulfill()
        }
        future.onFailure(context) { error in
            XCTAssert(false, "onFailure called")
        }
        self.beaconManager.didRangeBeacons(self.testCLBeacons.map{$0 as CLBeaconInjectable}, inRegion: self.testCLBeaconRegion)
        waitForExpectations()
    }
    
    func testStartRangingRegionFailure() {
        CLLocationManagerMock._authorizationStatus = .authorizedAlways
        let expectation = self.expectation(description: "onFailure fulfilled for future")
        let context = ImmediateContext()
        let future = self.beaconManager.startRangingBeaconsInRegion(self.testBeaconRegion, context: context)
        future.onSuccess(context) { beacons in
            XCTAssert(false, "onSuccess called")
        }
        future.onFailure(context) { error in
            XCTAssert(self.mock.startRangingBeaconsInRegionCalled, "startRangingBeaconsInRegion not called")
            XCTAssertEqual(self.testBeaconRegion.beacons.count, 0, "Region Beacon count invalid")
            XCTAssertEqual(error.code, TestFailure.error.code, "Error code invalid")
            XCTAssertFalse(self.beaconManager.isRanging, "isRanging invalid")
            expectation.fulfill()
        }
        self.beaconManager.rangingBeaconsDidFailForRegion(self.testCLBeaconRegion, withError: TestFailure.error)
        waitForExpectations()
    }
    
    func testStartRangingAuthorizationFailure() {
        CLLocationManagerMock._authorizationStatus = .notDetermined
        let expectation = self.expectation(description: "onSuccess fulfilled for future")
        let future = self.beaconManager.startRangingBeaconsInRegion(self.testBeaconRegion)
        future.onSuccess {state in
            XCTAssert(false, "onSuccess called")
        }
        future.onFailure { error in
            XCTAssertEqual(error.code, FLError.authorizationAlwaysFailed.code, "Error code invalid")
            XCTAssertFalse(self.mock.startRangingBeaconsInRegionCalled, "startRangingBeaconsInRegion not called")
            XCTAssertEqual(self.testBeaconRegion.beacons.count, 0, "Region Beacon count invalid")
            XCTAssertFalse(self.beaconManager.isRanging, "isRanging invalid")
            expectation.fulfill()
        }
        self.beaconManager.didChangeAuthorizationStatus(.denied)
        waitForExpectations()
    }

    func testStopRangingRegion() {
        CLLocationManagerMock._authorizationStatus = .authorizedAlways
        let expectation = self.expectation(description: "onSuccess fulfilled for future")
        let context = ImmediateContext()
        let future = self.beaconManager.startRangingBeaconsInRegion(self.testBeaconRegion, context: context)
        future.onSuccess(context) { beacons in
            XCTAssert(self.beaconManager.isRanging, "isRanging invalid")
            XCTAssertFalse(self.mock.stopRangingBeaconsInRegionCalled, "stopRangingBeaconsInRegion called")
            expectation.fulfill()
        }
        future.onFailure(context) { error in
            XCTAssert(false, "onFailure called")
        }
        self.beaconManager.didRangeBeacons(self.testCLBeacons.map{$0 as CLBeaconInjectable}, inRegion: self.testCLBeaconRegion)
        self.beaconManager.stopRangingBeaconsInRegion(self.testBeaconRegion)
        XCTAssert(self.mock.stopRangingBeaconsInRegionCalled, "stopRangingBeaconsInRegion not called")
        XCTAssertFalse(self.beaconManager.isRanging, "isRanging invalid")
        waitForExpectations()
    }
}
