//
//  RegionManagerTests.swift
//  FutureLocation
//
//  Created by Troy Stribling on 3/29/15.
//  Copyright (c) 2015 Troy Stribling. The MIT License (MIT).
//

import UIKit
import XCTest
import CoreLocation
@testable import BlueCapKit

class RegionManagerTests: XCTestCase {

    let testCLRegion = CLCircularRegion(center: CLLocationCoordinate2D(latitude: 37.760412, longitude: -122.414602),
                                        radius: 100.0, identifier: "Test Region")

    var testRegion: FLRegion!
    var mock: CLLocationManagerMock!
    var regionManager: RegionManagerUT!

    override func setUp() {
        super.setUp()
        self.testRegion = FLRegion(region: self.testCLRegion)
        self.mock = CLLocationManagerMock()
        self.regionManager = RegionManagerUT(clLocationManager: self.mock)
    }

    override func tearDown() {
        super.tearDown()
    }

    func waitForExpectations(_ timeout: Double = 2.0) {
        self.waitForExpectations(timeout: timeout) { error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testStartMonitoringRegionSuccess() {
        CLLocationManagerMock._authorizationStatus = .authorizedAlways
        let expectation = self.expectation(description: "onSuccess fulfilled for future")
        let context = ImmediateContext()
        let future = self.regionManager.startMonitoringForRegion(self.testRegion, authorization: .AuthorizedAlways, context: context)
        future.onSuccess(context) { state in
            XCTAssert(state == .Start, "region state invalid")
            XCTAssert(self.mock.startMonitoringForRegionCalled, "startMonitoringForRegion not called")
            XCTAssert(self.regionManager.isMonitoring, "isMonitoring vaoue invalid")
            expectation.fulfill()
        }
        future.onFailure(context) { error in
            XCTAssert(false, "onFailure called")
        }
        self.regionManager.didStartMonitoringForRegion(self.testCLRegion)
        waitForExpectations()
    }

    func testStartMonitoringRegionFailure() {
        CLLocationManagerMock._authorizationStatus = .authorizedAlways
        let expectation = self.expectation(description: "onFailure fulfilled for future")
        let context = ImmediateContext()
        let future = self.regionManager.startMonitoringForRegion(self.testRegion, authorization: .AuthorizedAlways, context: context)
        future.onSuccess(context) { state in
            XCTAssert(false, "onSuccess called")
        }
        future.onFailure(context) { error in
            XCTAssert(self.mock.startMonitoringForRegionCalled, "startMonitoringForRegion not called")
            XCTAssertEqual(error.code, TestFailure.error.code, "Error code invalid")
            XCTAssertEqual(self.regionManager.regions.count, 1, "Region count invalid")
            XCTAssertFalse(self.regionManager.isMonitoring, "isMonitoring vaoue invalid")
            expectation.fulfill()
        }
        self.regionManager.monitoringDidFailForRegion(self.testCLRegion, withError: TestFailure.error)
        waitForExpectations()
    }
    
    func testStartMonitoringAuthorizationFailure() {
        CLLocationManagerMock._authorizationStatus = .notDetermined
        let expectation = self.expectation(description: "onFailure fulfilled for future")
        let future = self.regionManager.startMonitoringForRegion(self.testRegion, authorization: .AuthorizedAlways)
        future.onSuccess { state in
            XCTAssert(false, "onSuccess called")
        }
        future.onFailure {error in
            XCTAssertEqual(error.code, FLError.authorizationAlwaysFailed.code, "Error code invalid")
            XCTAssertFalse(self.mock.startMonitoringForRegionCalled, "startMonitoringForRegion called")
            XCTAssertEqual(self.regionManager.regions.count, 0, "Region count invalid")
            XCTAssertFalse(self.regionManager.isMonitoring, "isMonitoring vaoue invalid")
            expectation.fulfill()
        }
        self.regionManager.didChangeAuthorizationStatus(.denied)
        waitForExpectations()
    }
    
    func testDidEnterRegion() {
        CLLocationManagerMock._authorizationStatus = .authorizedAlways
        let expectation = self.expectation(description: "onSuccess fulfilled for future")
        let context = ImmediateContext()
        let future = self.regionManager.startMonitoringForRegion(self.testRegion, authorization: .AuthorizedAlways, context: context)
        future.onSuccess(context) { state in
            if state == .Start {
                dispatch_async(dispatch_get_main_queue()) { self.regionManager.didEnterRegion(self.testCLRegion) }
            } else {
                XCTAssert(state == .Inside, "region state invalid")
                expectation.fulfill()
            }
        }
        future.onFailure(context) { error in
            XCTAssert(false, "onFailure called")
        }
        self.regionManager.didStartMonitoringForRegion(self.testCLRegion)
        waitForExpectations()
    }
    
    func testDidExitRegion() {
        CLLocationManagerMock._authorizationStatus = .authorizedAlways
        let expectation = self.expectation(description: "onSuccess fulfilled for future")
        let context = ImmediateContext()
        let future = self.regionManager.startMonitoringForRegion(self.testRegion, authorization: .AuthorizedAlways, context: context)
        future.onSuccess(context) { state in
            if state == .Start {
                dispatch_async(dispatch_get_main_queue()) { self.regionManager.didExitRegion(self.testCLRegion) }
            } else {
                XCTAssert(state == .Outside, "region state invalid")
                expectation.fulfill()
            }
        }
        future.onFailure(context) { error in
            XCTAssert(false, "onFailure called")
        }
        self.regionManager.didStartMonitoringForRegion(self.testCLRegion)
        waitForExpectations()
    }

    func testRequetsStateForRegion() {
        CLLocationManagerMock._authorizationStatus = .authorizedAlways
        let expectation = self.expectation(description: "onSuccess fulfilled for future")
        let future = self.regionManager.requestStateForRegion(self.testRegion)
        future.onSuccess { state in
            XCTAssertEqual(state, CLRegionState.inside, "state invalid")
            XCTAssert(self.mock.requestStateForRegionCalled, "requestStateForRegion not called")
            expectation.fulfill()
        }
        future.onFailure { error in
            XCTAssert(false, "onFailure called")
        }
        self.regionManager.didDetermineState(.inside, forRegion: self.testCLRegion)
        self.regionManager.didStartMonitoringForRegion(self.testCLRegion)
        waitForExpectations()

    }

    func testStopMonitoringRegion() {
        CLLocationManagerMock._authorizationStatus = .authorizedAlways
        let expectation = self.expectation(description: "onSuccess fulfilled for future")
        let context = ImmediateContext()
        let future = self.regionManager.startMonitoringForRegion(self.testRegion, authorization: .AuthorizedAlways, context: context)
        future.onSuccess(context) { state in
            XCTAssertFalse(self.mock.stopMonitoringForRegionCalled, "stopMonitoringForRegion called")
            XCTAssert(self.regionManager.isMonitoring, "isMonitoring vaoue invalid")
            expectation.fulfill()
        }
        future.onFailure(context) { error in
            XCTAssert(false, "onFailure called")
        }
        self.regionManager.didStartMonitoringForRegion(self.testCLRegion)
        self.regionManager.stopMonitoringForRegion(self.testRegion)
        XCTAssert(self.mock.stopMonitoringForRegionCalled, "stopMonitoringForRegion not called")
        XCTAssertFalse(self.regionManager.isMonitoring, "isMonitoring vaoue invalid")
        waitForExpectations()
    }
}
