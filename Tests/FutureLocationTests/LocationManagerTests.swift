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

    func testAuthorizedAlwaysWhenAuthorizedAlways() {
        CLLocationManagerMock._authorizationStatus = .authorizedAlways
        let expectation = self.expectation(description: "onSuccess fulfilled for future")
        let future = self.locationManager.authorize(.authorizedAlways)
        future.onSuccess {
            XCTAssertFalse(self.mock.requestAlwaysAuthorizationCalled, "requestAlwaysAuthorization called")
            expectation.fulfill()
        }
        future.onFailure{error in
            XCTAssert(false, "onFailure called")
        }
        waitForExpectations()
    }

    func testAuthorizedAlwaysSuccess() {
        CLLocationManagerMock._authorizationStatus = .notDetermined
        let expectation = self.expectation(description: "onSuccess fulfilled for future")
        let future = self.locationManager.authorize(.authorizedAlways)
        future.onSuccess {
            XCTAssert(self.mock.requestAlwaysAuthorizationCalled, "requestAlwaysAuthorization not called")
            expectation.fulfill()
        }
        future.onFailure{error in
            XCTAssert(false, "onFailure called")
        }
        self.locationManager.didChangeAuthorizationStatus(.authorizedAlways)
        waitForExpectations()
    }

    func testAuthorizedAlwaysFailure() {
        CLLocationManagerMock._authorizationStatus = .notDetermined
        let expectation = self.expectation(description: "onFailure fulfilled for future")
        let future = self.locationManager.authorize(.authorizedAlways)
        future.onSuccess {
            XCTAssert(false, "onSuccess called")
        }
        future.onFailure{error in
            XCTAssert(self.mock.requestAlwaysAuthorizationCalled, "requestAlwaysAuthorization not called")
            expectation.fulfill()
        }
        self.locationManager.didChangeAuthorizationStatus(.denied)
        waitForExpectations()
    }

    func testAuthorizedWhenInUseWhenAuthorizedWhenInUse() {
        CLLocationManagerMock._authorizationStatus = .authorizedWhenInUse
        let expectation = self.expectation(description: "onSuccess fulfilled for future")
        let future = self.locationManager.authorize(.authorizedWhenInUse)
        future.onSuccess {
            XCTAssertFalse(self.mock.requestWhenInUseAuthorizationCalled, "requestWhenInUseAuthorization called")
            expectation.fulfill()
        }
        future.onFailure{error in
            XCTAssert(false, "onFailure called")
        }
        waitForExpectations()
    }
    
    func testAuthorizedWhenInUseSuccess() {
        CLLocationManagerMock._authorizationStatus = .notDetermined
        let expectation = self.expectation(description: "onSuccess fulfilled for future")
        let future = self.locationManager.authorize(.authorizedWhenInUse)
        future.onSuccess {
            XCTAssert(self.mock.requestWhenInUseAuthorizationCalled, "requestWhenInUseAuthorization not called")
            expectation.fulfill()
        }
        future.onFailure{error in
            XCTAssert(false, "onFailure called")
        }
        self.locationManager.didChangeAuthorizationStatus(.authorizedWhenInUse)
        waitForExpectations()
    }
    
    func testAuthorizedWhenInUseFailure() {
        CLLocationManagerMock._authorizationStatus = .notDetermined
        let expectation = self.expectation(description: "onFailure fulfilled for future")
        let future = self.locationManager.authorize(.authorizedWhenInUse)
        future.onSuccess {
            XCTAssert(false, "onSuccess called")
        }
        future.onFailure{error in
            XCTAssert(self.mock.requestWhenInUseAuthorizationCalled, "requestWhenInUseAuthorization not called")
            XCTAssertEqual(error.code, FLError.authorizationWhenInUseFailed.code, "Error code invalid")
            expectation.fulfill()
        }
        locationManager.didChangeAuthorizationStatus(.denied)
        waitForExpectations()
    }
    

    func testUpdateLocationSuccess() {
        CLLocationManagerMock._authorizationStatus = .authorizedAlways
        let expectation = self.expectation(description: "onSuccess fulfilled for future")
        let context = ImmediateContext()
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
    
    func testUpdateLocationFailure() {
        CLLocationManagerMock._authorizationStatus = .authorizedAlways
        let expectation = self.expectation(description: "onFailure fulfilled for future")
        let context = ImmediateContext()
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

    func testUpdateLocationAuthorizationFailure() {
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

    func testStopLocationUpdates() {
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
    
    func testUpdateSignificantLocationChangesFailure() {
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

    func testStopSignificantLocationChangeUpdates() {
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


    func testUpdateSignificantLocationChangesAuthorizationFailure() {
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

    func testRequestLocationCastFailure() {
        CLLocationManagerMock._authorizationStatus = .authorizedAlways
        let expectation = self.expectation(description: "onFailure fulfilled for future")
        let context = ImmediateContext()
        let future = self.locationManager.requestLocation(.AuthorizedAlways, context: context)
        future.onSuccess(context) {locations in
            XCTAssert(false, "onFailure called")
        }
        future.onFailure(context) { error in
            XCTAssertEqual(error.code, FLError.notSupportedForIOSVersion.code, "Error code invalid")
            XCTAssertFalse(self.locationManager.isUpdating, "isUpdating value invalid")
            expectation.fulfill()
        }
        waitForExpectations()
    }

    func testDeferrLocationUpdatesSuccess() {
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

    func testDeferrLocationUpdatesFailure() {
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
