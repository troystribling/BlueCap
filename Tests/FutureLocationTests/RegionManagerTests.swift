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

    var testRegion: Region!
    var mock: CLLocationManagerMock!
    var regionManager: RegionManagerUT!

    override func setUp() {
        super.setUp()
        self.testRegion = Region(region: self.testCLRegion)
        self.mock = CLLocationManagerMock()
        self.regionManager = RegionManagerUT(clLocationManager: self.mock)
    }

    override func tearDown() {
        super.tearDown()
    }

    func testStartMonitoringForRegion_WhenAuthorizedAlwaysAndMonitoringStartsWithoutFailure_CompletesSuccessfully() {
        CLLocationManagerMock._authorizationStatus = .authorizedAlways
        let stream = self.regionManager.startMonitoring(forRegion: self.testRegion, authorization: .authorizedAlways, context: TestContext.immediate)
        self.regionManager.didStartMonitoringForRegion(self.testCLRegion)
        XCTAssertFutureStreamSucceeds(stream, context: TestContext.immediate, validations: [
            { state in
                XCTAssert(state == .start)
                XCTAssert(self.mock.startMonitoringForRegionCalled)
                XCTAssert(self.regionManager.isMonitoring)
            }
        ])
    }

    func testStartMonitoringForRegion_WhenAuthorizedAlwaysAndMonitoringStartsWithoFailure_CompletesWithError() {
        CLLocationManagerMock._authorizationStatus = .authorizedAlways
        let stream = self.regionManager.startMonitoring(forRegion: self.testRegion, authorization: .authorizedAlways, context: TestContext.immediate)
        self.regionManager.monitoringDidFailForRegion(self.testCLRegion, withError: TestFailure.error)
        XCTAssertFutureStreamFails(stream, context: TestContext.immediate, validations: [
            { error in
                XCTAssert(self.mock.startMonitoringForRegionCalled)
                XCTAssertEqualErrors(error, TestFailure.error)
                XCTAssertEqual(self.regionManager.regions.count, 1)
                XCTAssertFalse(self.regionManager.isMonitoring)
            }
        ])
    }
    
    func testStartMonitoringForRegion_WhenAuthorizationFails_CompletesWithError() {
        CLLocationManagerMock._authorizationStatus = .notDetermined
        let stream = self.regionManager.startMonitoring(forRegion: self.testRegion, authorization: .authorizedAlways)
        self.regionManager.didChangeAuthorizationStatus(.denied)
        XCTAssertFutureStreamFails(stream, context: TestContext.immediate, validations: [
            { error in
                XCTAssertEqualErrors(error, LocationError.authorizationAlwaysFailed)
                XCTAssertFalse(self.mock.startMonitoringForRegionCalled)
                XCTAssertEqual(self.regionManager.regions.count, 0)
                XCTAssertFalse(self.regionManager.isMonitoring)
            }
        ])
    }
    
    func testStartMonitoringForRegion_WhenMonitoringOnRegionEnter_CompletesSuccessfully() {
        CLLocationManagerMock._authorizationStatus = .authorizedAlways
        let stream = self.regionManager.startMonitoring(forRegion: self.testRegion, authorization: .authorizedAlways, context: TestContext.immediate)
        var recievedState: RegionState?
        stream.onSuccess(context: TestContext.immediate) { state in
            if state == .start {
                self.regionManager.didEnterRegion(self.testCLRegion)
            } else {
                recievedState = state
                XCTAssertEqual(state, .inside)
            }
        }
        stream.onFailure(context: TestContext.immediate) { _ in
            XCTFail()
        }
        self.regionManager.didStartMonitoringForRegion(self.testCLRegion)
        XCTAssertEqual(recievedState, .inside)
    }
    
    func testStartMonitoringForRegion_WhenMonitoringOnRegionExit_CompletesSuccessfully() {
        CLLocationManagerMock._authorizationStatus = .authorizedAlways
        let stream = self.regionManager.startMonitoring(forRegion: self.testRegion, authorization: .authorizedAlways, context: TestContext.immediate)
        var recievedState: RegionState?
        stream.onSuccess(context: TestContext.immediate) { state in
            if state == .start {
                self.regionManager.didExitRegion(self.testCLRegion)
            } else {
                recievedState = state
                XCTAssertEqual(state, .outside)
            }
        }
        stream.onFailure(context: TestContext.immediate) { _ in
            XCTFail()
        }
        self.regionManager.didStartMonitoringForRegion(self.testCLRegion)
        XCTAssertEqual(recievedState, .inside)
    }

    func testRequestStateForRegion_WhenMonitoring_CompletesSuccessfully() {
        CLLocationManagerMock._authorizationStatus = .authorizedAlways
        let future = self.regionManager.requestState(forRegion: self.testRegion)
        self.regionManager.didDetermineState(.inside, forRegion: self.testCLRegion)
        XCTAssertFutureSucceeds(future, context: TestContext.immediate) { state in
            XCTAssertEqual(state, .inside)
            XCTAssert(self.mock.requestStateForRegionCalled)
        }
    }

    func testStopMonitoringForRegion_WhenMonitoring_StopsMonitoringRegion() {
        CLLocationManagerMock._authorizationStatus = .authorizedAlways
        let stream = self.regionManager.startMonitoring(forRegion: self.testRegion, authorization: .authorizedAlways, context: TestContext.immediate)
        stream.onSuccess(context: TestContext.immediate) { _ in
            XCTFail()
        }
        stream.onFailure(context: TestContext.immediate) { _ in
            XCTFail()
        }
        self.regionManager.stopMonitoringForRegion(self.testRegion)
        self.regionManager.didStartMonitoringForRegion(self.testCLRegion)
        XCTAssert(self.mock.stopMonitoringForRegionCalled)
        XCTAssertFalse(self.regionManager.isMonitoring)
    }
}
