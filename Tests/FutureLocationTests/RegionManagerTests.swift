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
        self.testRegion = Region(region: testCLRegion)
        self.mock = CLLocationManagerMock()
        self.regionManager = RegionManagerUT(clLocationManager: self.mock)
    }

    override func tearDown() {
        super.tearDown()
    }

    // startMonitoringForRegion
    
    func testStartMonitoringForRegion_WhenAuthorizedAlwaysAndMonitoringStartsWithoutFailure_CompletesSuccessfully() {
        CLLocationManagerMock._authorizationStatus = .authorizedAlways
        let stream = regionManager.startMonitoring(for: testRegion, authorization: .authorizedAlways, context: TestContext.immediate)
        self.regionManager.didStartMonitoring(forRegion: testCLRegion)
        XCTAssertFutureStreamSucceeds(stream, context: TestContext.immediate, validations: [
            { state in
                XCTAssert(state == .start)
                XCTAssert(self.mock.startMonitoringForRegionCalled)
                XCTAssert(self.regionManager.isMonitoring)
            }
        ])
    }

    func testStartMonitoringForRegion_WhenAuthorizedAlwaysAndMonitoringStartsWithFailure_CompletesWithError() {
        CLLocationManagerMock._authorizationStatus = .authorizedAlways
        let stream = regionManager.startMonitoring(for: testRegion, authorization: .authorizedAlways, context: TestContext.immediate)
        regionManager.monitoringDidFail(forRegion: testCLRegion, withError: TestFailure.error)
        XCTAssertFutureStreamFails(stream, context: TestContext.immediate, validations: [
            { error in
                XCTAssert(self.mock.startMonitoringForRegionCalled)
                XCTAssertEqualErrors(error, TestFailure.error)
                XCTAssertEqual(self.regionManager.regions.count, 1)
                XCTAssert(self.regionManager.isMonitoring)
            }
        ])
    }
    
    func testStartMonitoringForRegion_WhenAuthorizationFails_CompletesWithError() {
        CLLocationManagerMock._authorizationStatus = .notDetermined
        let stream = regionManager.startMonitoring(for: testRegion, authorization: .authorizedAlways, context: TestContext.immediate)
        regionManager.didChangeAuthorization(status: .denied)
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
        let stream = regionManager.startMonitoring(for: testRegion, authorization: .authorizedAlways, context: TestContext.immediate)
        var updateCount = 0
        stream.onSuccess(context: TestContext.immediate) { state in
            updateCount += 1
            switch updateCount {
            case 1:
                XCTAssertEqual(state, .start)
            case 2:
                XCTAssertEqual(state, .inside)
            default:
                XCTFail()
            }
        }
        stream.onFailure(context: TestContext.immediate) { _ in
            XCTFail()
        }
        self.regionManager.didStartMonitoring(forRegion: self.testCLRegion)
        self.regionManager.didEnter(region: self.testCLRegion)
    }
    
    func testStartMonitoringForRegion_WhenMonitoringOnRegionExit_CompletesSuccessfully() {
        CLLocationManagerMock._authorizationStatus = .authorizedAlways
        let stream = regionManager.startMonitoring(for: testRegion, authorization: .authorizedAlways, context: TestContext.immediate)
        var updateCount = 0
        stream.onSuccess(context: TestContext.immediate) { state in
            updateCount += 1
            switch updateCount {
            case 1:
                XCTAssertEqual(state, .start)
            case 2:
                XCTAssertEqual(state, .outside)
            default:
                XCTFail()
            }
        }
        stream.onFailure(context: TestContext.immediate) { _ in
            XCTFail()
        }
        self.regionManager.didStartMonitoring(forRegion: testCLRegion)
        self.regionManager.didExit(region: self.testCLRegion)
    }

    // MARK: requestStateForRegion

    func testRequestStateForRegion_WhenMonitoring_CompletesSuccessfully() {
        CLLocationManagerMock._authorizationStatus = .authorizedAlways
        let future = regionManager.requestState(for: self.testRegion)
        self.regionManager.didDetermine(state: .inside, forRegion: self.testCLRegion)
        XCTAssertFutureSucceeds(future, context: TestContext.immediate) { state in
            XCTAssertEqual(state, .inside)
            XCTAssert(self.mock.requestStateForRegionCalled)
        }
    }

    // MARK: stopMonitoringForRegion

    func testStopMonitoringForRegion_WhenMonitoring_StopsMonitoringRegion() {
        CLLocationManagerMock._authorizationStatus = .authorizedAlways
        let stream = regionManager.startMonitoring(for: testRegion, authorization: .authorizedAlways, context: TestContext.immediate)
        stream.onSuccess(context: TestContext.immediate) { _ in
            XCTFail()
        }
        stream.onFailure(context: TestContext.immediate) { _ in
            XCTFail()
        }
        self.regionManager.stopMonitoring(for: testRegion)
        self.regionManager.didStartMonitoring(forRegion: testCLRegion)
        XCTAssert(self.mock.stopMonitoringForRegionCalled)
        XCTAssertFalse(self.regionManager.isMonitoring)
    }
}
