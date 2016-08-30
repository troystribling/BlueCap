//
//  LocationManagerTests.swift
//  FutureLocation
//
//  Created by Troy Stribling on 3/28/15.
//  Copyright (c) 2015 Troy Stribling. The MIT License (MIT).
//

import UIKit
import XCTest
import CoreLocation
@testable import BlueCapKit

class LocationManagerTests: XCTestCase {

    let testLocations = [CLLocation(latitude: 37.760412, longitude: -122.414602), CLLocation(latitude: 37.745480, longitude: -122.420092)]
    var mock: CLLocationManagerMock!
    var locationManager: LocationManagerUT!

    override func setUp() {
        super.setUp()
        self.mock = CLLocationManagerMock()
        self.locationManager = LocationManagerUT(clLocationManager: mock)
    }
    
    override func tearDown() {
        super.tearDown()
    }

    func waitForExpectations(_ timeout: Double = 2.0) {
        self.waitForExpectations(timeout: timeout) { error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testAuthorized_WhenAuthorizedAlwaysRequestedAndStatusIsAuthorizedAlways_CompletesSuccessfully() {
        CLLocationManagerMock._authorizationStatus = .authorizedAlways
        let future = self.locationManager.authorize(.authorizedAlways)
        XCTAssertFutureSucceeds(future, context: TestContext.immediate) {
            XCTAssertFalse(self.mock.requestAlwaysAuthorizationCalled)
        }
    }

    func testAuthorized_WhenAuthorizedAlwaysRequestedAndStatusIsNotDetermined_CompletesSuccessfully() {
        CLLocationManagerMock._authorizationStatus = .notDetermined
        let future = self.locationManager.authorize(.authorizedAlways)
        self.locationManager.didChangeAuthorizationStatus(.authorizedAlways)
        XCTAssertFutureSucceeds(future, context: TestContext.immediate) {
            XCTAssertFalse(self.mock.requestAlwaysAuthorizationCalled)
        }
    }

    func testAuthorized_WhenAuthorizedAlwaysRequestedAndStatusIsAuthorizedWhenInUse_CompletesSuccessfully() {
        CLLocationManagerMock._authorizationStatus = .authorizedWhenInUse
        let future = self.locationManager.authorize(.authorizedAlways)
        self.locationManager.didChangeAuthorizationStatus(.authorizedAlways)
        XCTAssertFutureSucceeds(future, context: TestContext.immediate) {
            XCTAssertFalse(self.mock.requestAlwaysAuthorizationCalled)
        }
    }


    func testAuthorized_WhenAuthorizedAlwaysRequestedAndRequestDenied_CompletesWithError() {
        CLLocationManagerMock._authorizationStatus = .notDetermined
        let expectation = self.expectation(description: "onFailure fulfilled for future")
        let future = self.locationManager.authorize(.authorizedAlways)
        future.onSuccess {
            XCTFail()
        }
        future.onFailure{ error in
            expectation.fulfill()
        }
        self.locationManager.didChangeAuthorizationStatus(.denied)
        waitForExpectations()
        XCTAssertFutureFails(future, context: TestContext.immediate) { error in
            XCTAssert(self.mock.requestAlwaysAuthorizationCalled)
            XCTAssertEqualErrors(error, LocationError.authorizationAlwaysFailed)
        }
    }

    func testAuthorized_WhenAuthorizedWhenInUseRequestedAndStatusIsAuthorizedWhenInUse_CompletesSuccessfully() {
        CLLocationManagerMock._authorizationStatus = .authorizedWhenInUse
        let expectation = self.expectation(description: "onSuccess fulfilled for future")
        let future = self.locationManager.authorize(.authorizedWhenInUse)
        future.onSuccess {
            XCTAssertFalse(self.mock.requestWhenInUseAuthorizationCalled)
            expectation.fulfill()
        }
        future.onFailure{error in
            XCTFail()
        }
        waitForExpectations()
    }
    
    func testAuthorized_WhenAuthorizedWhenInUseRequestedAndStatusIsNotDetermined_CompletesSuccessfully() {
        CLLocationManagerMock._authorizationStatus = .notDetermined
        let expectation = self.expectation(description: "onSuccess fulfilled for future")
        let future = self.locationManager.authorize(.authorizedWhenInUse)
        future.onSuccess {
            XCTAssert(self.mock.requestWhenInUseAuthorizationCalled)
            expectation.fulfill()
        }
        future.onFailure{error in
            XCTFail()
        }
        self.locationManager.didChangeAuthorizationStatus(.authorizedWhenInUse)
        waitForExpectations()
    }
    
    func testAuthorized_WhenAuthorizedWhenInUseRequestedAndRequestDenied_CompletesWithError() {
        CLLocationManagerMock._authorizationStatus = .notDetermined
        let expectation = self.expectation(description: "onFailure fulfilled for future")
        let future = self.locationManager.authorize(.authorizedWhenInUse)
        future.onSuccess {
            XCTAssert(false, "onSuccess called")
        }
        future.onFailure{error in
            XCTAssert(self.mock.requestWhenInUseAuthorizationCalled)
            XCTAssertEqualErrors(error, LocationError.authorizationWhenInUseFailed)
            expectation.fulfill()
        }
        locationManager.didChangeAuthorizationStatus(.denied)
        waitForExpectations()
    }
    

    func testStartUpdatingLocation_WhenAuthorizedAlwaysAndUpdateSucceeds_CompletesSuccessfully() {
        CLLocationManagerMock._authorizationStatus = .authorizedAlways
        let expectation = self.expectation(description: "onSuccess fulfilled for future")
        let future = self.locationManager.startUpdatingLocation(authorization: .authorizedAlways, context: context)
        future.onSuccess(context) {locations in
            XCTAssert(locations.count == 2, "locations count invalid")
            XCTAssert(self.mock.startUpdatingLocationCalled, "startUpdatingLocation not called")
            XCTAssert(self.locationManager.isUpdating, "isUpdating value invalid")
            expectation.fulfill()
        }
        future.onFailure(context) {error in
            XCTAssert(false, "onFailure called")
        }
        self.locationManager.didUpdateLocations(self.testLocations)
        waitForExpectations()
    }
    
    func testStartUpdatingLocation_WhenAuthorizedAlwaysAndUpdateFails_CompletesWithError() {
        CLLocationManagerMock._authorizationStatus = .authorizedAlways
        let expectation = self.expectation(description: "onFailure fulfilled for future")
        let future = self.locationManager.startUpdatingLocation(authorization: .authorizedAlways, context: context)
        future.onSuccess(context) {locations in
            XCTAssert(false, "onSuccess called")
        }
        future.onFailure(context) {error in
            XCTAssert(self.mock.startUpdatingLocationCalled, "startUpdatingLocation not called")
            XCTAssertEqual(error.code, TestFailure.error.code, "Error code invalid")
            XCTAssertFalse(self.locationManager.isUpdating, "isUpdating value invalid")
            expectation.fulfill()
        }
        self.locationManager.didFailWithError(TestFailure.error)
        waitForExpectations()
    }

    func testStartUpdatingLocation_WhenAuthorizationFails_CompletesWithError() {
        CLLocationManagerMock._authorizationStatus = .notDetermined
        let expectation = self.expectation(description: "onFailure fulfilled for future")
        let future = self.locationManager.startUpdatingLocation(authorization: .authorizedAlways)
        future.onSuccess {locations in
            XCTAssert(false, "onSuccess called")
        }
        future.onFailure {error in
            XCTAssertFalse(self.mock.startUpdatingLocationCalled, "startUpdatingLocation called")
            XCTAssertEqual(error.code, FLError.authorizationAlwaysFailed.code, "Error code invalid")
            XCTAssertFalse(self.locationManager.isUpdating, "isUpdating value invalid")
            expectation.fulfill()
        }
        self.locationManager.didChangeAuthorizationStatus(.denied)
        waitForExpectations()
    }

    func testStopUpdatingLocation_WhenLocationIsUpdating_StopsUpdating() {
        CLLocationManagerMock._authorizationStatus = .authorizedAlways
        let expectation = self.expectation(description: "onSuccess fulfilled for future")
        let context = ImmediateContext()
        let future = self.locationManager.startUpdatingLocation(authorization: .authorizedAlways, context: context)
        future.onSuccess(context) {locations in
            XCTAssert(self.locationManager.isUpdating, "isUpdating value invalid")
            XCTAssertFalse(self.mock.stopUpdatingLocationCalled, "stopUpdatingLocation not called")
            expectation.fulfill()
        }
        future.onFailure(context) {error in
            XCTAssert(false, "onFailure called")
        }
        self.locationManager.didUpdateLocations(self.testLocations)
        self.locationManager.stopUpdatingLocation()
        XCTAssert(self.mock.stopUpdatingLocationCalled, "stopUpdatingLocation not called")
        XCTAssertFalse(self.locationManager.isUpdating, "isUpdating is true")
        self.locationManager.didUpdateLocations(self.testLocations)
        waitForExpectations()
    }
 
    func testUpdateSignificantLocationChangesSuccess() {
        CLLocationManagerMock._authorizationStatus = .authorizedAlways
        let expectation = self.expectation(description: "onSuccess fulfilled for future")
        let context = ImmediateContext()
        let future = self.locationManager.startMonitoringSignificantLocationChanges(authorization:.authorizedAlways, context: context)
        future.onSuccess(context) { locations in
            XCTAssert(locations.count == 2, "locations count invalid")
            XCTAssert(self.mock.startMonitoringSignificantLocationChangesCalled, "startMonitoringSignificantLocationChanges called")
            XCTAssert(self.locationManager.isUpdating, "isUpdating value invalid")
            expectation.fulfill()
        }
        future.onFailure(context) {error in
            XCTAssert(false, "onFailure called")
        }
        self.locationManager.didUpdateLocations(self.testLocations)
        waitForExpectations()
    }
    
    func testStartMonitoringSignificantLocationChanges_WhenAuthorizedAlwaysAndUpdateSucceeds_CompletesSuccessfully() {
        CLLocationManagerMock._authorizationStatus = .authorizedAlways
        let expectation = self.expectation(description: "onFailure fulfilled for future")
        let context = ImmediateContext()
        let future = self.locationManager.startMonitoringSignificantLocationChanges(authorization:.authorizedAlways, context: context)
        future.onSuccess(context) {locations in
            XCTAssert(false, "onSuccess called")
        }
        future.onFailure(context) {error in
            XCTAssert(self.mock.startMonitoringSignificantLocationChangesCalled, "startUpdatingLocation called")
            XCTAssertEqual(error.code, TestFailure.error.code, "Error code invalid")
            XCTAssertFalse(self.locationManager.isUpdating, "isUpdating value invalid")
            expectation.fulfill()
        }
        self.locationManager.didFailWithError(TestFailure.error)
        waitForExpectations()
    }

    func testStopMonitoringSignificantLocationChanges_WhenLocationIsUpdating_StopsUpdating() {
        CLLocationManagerMock._authorizationStatus = .authorizedAlways
        let expectation = self.expectation(description: "onSuccess fulfilled for future")
        let context = ImmediateContext()
        let future = self.locationManager.startMonitoringSignificantLocationChanges(authorization: .authorizedAlways, context: context)
        future.onSuccess(context) {locations in
            XCTAssert(self.locationManager.isUpdating, "isUpdating value invalid")
            expectation.fulfill()
        }
        future.onFailure(context) {error in
            XCTAssert(false, "onFailure called")
        }
        self.locationManager.didUpdateLocations(self.testLocations)
        self.locationManager.stopMonitoringSignificantLocationChanges()
        XCTAssert(self.mock.stopMonitoringSignificantLocationChangesCalled, "stopUpdatingLocation not called")
        XCTAssertFalse(self.locationManager.isUpdating, "isUpdating is true")
        self.locationManager.didUpdateLocations(self.testLocations)
        waitForExpectations()
    }


    func testStartUpdatingLocation_WhenAuthorizationFails_CompletesWithError() {
        CLLocationManagerMock._authorizationStatus = .notDetermined
        let expectation = self.expectation(description: "onFailure fulfilled for future")
        let future = self.locationManager.startMonitoringSignificantLocationChanges(authorization:.authorizedAlways)
        future.onSuccess {locations in
            XCTAssert(false, "onSuccess called")
        }
        future.onFailure {error in
            XCTAssertFalse(self.mock.startMonitoringSignificantLocationChangesCalled, "startUpdatingLocation called")
            XCTAssertEqual(error.code, FLError.authorizationAlwaysFailed.code, "Error code invalid")
            XCTAssertFalse(self.locationManager.isUpdating, "isUpdating value invalid")
            expectation.fulfill()
        }
        self.locationManager.didChangeAuthorizationStatus(.denied)
        waitForExpectations()
    }

    func testAllowDeferredLocationUpdatesUntilTraveled_WhenUpdateSucceeds_CompletesSuccessfully() {
        CLLocationManagerMock._authorizationStatus = .authorizedAlways
        let expectation = self.expectation(description: "onSuccess fulfilled for future")
        let future = self.locationManager.allowDeferredLocationUpdatesUntilTraveled(1000.0, timeout: 300.0)
        future.onSuccess {
            XCTAssert(self.mock.allowDeferredLocationUpdatesUntilTraveledCalled, "allowDeferredLocationUpdatesUntilTraveled not called")
            expectation.fulfill()
        }
        future.onFailure { error in
            XCTAssert(false, "onFailure calledf")
        }
        self.locationManager.didFinishDeferredUpdatesWithError(nil)
        waitForExpectations()
    }

    func testAllowDeferredLocationUpdatesUntilTraveled_WhenUpdateFails_CompletesWithError() {
        CLLocationManagerMock._authorizationStatus = .authorizedAlways
        let expectation = self.expectation(description: "onFailure fulfilled for future")
        let future = self.locationManager.allowDeferredLocationUpdatesUntilTraveled(1000.0, timeout: 300.0)
        future.onSuccess {
            XCTAssert(false, "onFailure calledf")
        }
        future.onFailure { error in
            XCTAssert(self.mock.allowDeferredLocationUpdatesUntilTraveledCalled, "allowDeferredLocationUpdatesUntilTraveled not called")
            XCTAssertEqual(error.code, TestFailure.error.code, "error code invalid")
            expectation.fulfill()
        }
        self.locationManager.didFinishDeferredUpdatesWithError(TestFailure.error)
        waitForExpectations()
    }

}
