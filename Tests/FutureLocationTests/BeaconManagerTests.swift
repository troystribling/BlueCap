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
        CLBeaconMock(proximityUUID: UUID(), major: 1, minor: 2, proximity: .immediate, accuracy: kCLLocationAccuracyBest, rssi: -45),
        CLBeaconMock(proximityUUID: UUID(), major: 1, minor: 2, proximity: .far, accuracy: kCLLocationAccuracyBest, rssi: -85)]

    var testBeaconRegion: BeaconRegion!
    var mock: CLLocationManagerMock!
    var beaconManager: BeaconManagerUT!

    override func setUp() {
        super.setUp()
        self.testBeaconRegion = BeaconRegion(region: self.testCLBeaconRegion)
        self.mock = CLLocationManagerMock()
        self.beaconManager = BeaconManagerUT(clLocationManager: self.mock)
    }

    override func tearDown() {
        super.tearDown()
    }

    func testStartRangingRegion_WhenAuthorizedAndBeaconsDiscovered_CompletesSuccessfully() {
        CLLocationManagerMock._authorizationStatus = .authorizedAlways
        let stream = self.beaconManager.startRangingBeacons(in: self.testBeaconRegion, authorization: .authorizedAlways, context: TestContext.immediate)
        self.beaconManager.didRange(beacons: self.testCLBeacons.map{$0 as CLBeaconInjectable}, inRegion: self.testCLBeaconRegion)
        XCTAssertFutureStreamSucceeds(stream, context: TestContext.immediate, validations: [
            { beacons in
                XCTAssertEqual(beacons.count, 2)
                XCTAssertEqual(self.beaconManager.beaconRegions.count, 1)
                XCTAssertEqual(self.testBeaconRegion.beacons.count, 2)
                XCTAssert(self.beaconManager.isRanging)
                XCTAssert(self.mock.startRangingBeaconsInRegionCalled)
            }
        ])
    }
    
    func testStartRangingRegion_WhenAuthorizedAndRangingFails_CompletesWithError() {
        CLLocationManagerMock._authorizationStatus = .authorizedAlways
        let stream = self.beaconManager.startRangingBeacons(in: self.testBeaconRegion, authorization: .authorizedAlways, context: TestContext.immediate)
        self.beaconManager.rangingBeaconsDidFail(inRegion: self.testCLBeaconRegion, withError: TestFailure.error)
        XCTAssertFutureStreamFails(stream, context: TestContext.immediate, validations: [
            { error in
                XCTAssert(self.mock.startRangingBeaconsInRegionCalled)
                XCTAssertEqual(self.testBeaconRegion.beacons.count, 0)
                XCTAssertEqualErrors(error, TestFailure.error)
                XCTAssertTrue(self.beaconManager.isRanging)
            }
        ])
    }
    
    func testStartRangingRegion_WhenAuthorizationFails_CompletesWithError() {
        CLLocationManagerMock._authorizationStatus = .notDetermined
        let stream = self.beaconManager.startRangingBeacons(in: self.testBeaconRegion, authorization: .authorizedAlways, context: TestContext.immediate)
        self.beaconManager.didChangeAuthorization(status: .denied)
        XCTAssertFutureStreamFails(stream, context: TestContext.immediate, validations: [
            { error in
                XCTAssertEqualErrors(error, LocationError.authorizationAlwaysFailed)
                XCTAssertFalse(self.mock.startRangingBeaconsInRegionCalled)
                XCTAssertEqual(self.testBeaconRegion.beacons.count, 0)
                XCTAssertFalse(self.beaconManager.isRanging)
            }
        ])
    }

    func testStopRanging_WhenRanging_StopsRanging() {
        CLLocationManagerMock._authorizationStatus = .authorizedAlways
        let future = self.beaconManager.startRangingBeacons(in: self.testBeaconRegion, authorization: .authorizedAlways, context: TestContext.immediate)
        future.onSuccess(context: TestContext.immediate) { beacons in
            XCTAssert(self.beaconManager.isRanging, "isRanging invalid")
            XCTAssertFalse(self.mock.stopRangingBeaconsInRegionCalled, "stopRangingBeaconsInRegion called")
        }
        future.onFailure(context: TestContext.immediate) { _ in
            XCTFail()
        }
        self.beaconManager.didRange(beacons: self.testCLBeacons.map{$0 as CLBeaconInjectable}, inRegion: self.testCLBeaconRegion)
        self.beaconManager.stopRangingBeacons(in: self.testBeaconRegion)
        XCTAssert(self.mock.stopRangingBeaconsInRegionCalled)
        XCTAssertFalse(self.beaconManager.isRanging)
    }
}
