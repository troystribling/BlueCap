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
        let future = self.locationManager.authorize(.authorizedAlways)
        self.locationManager.didChangeAuthorizationStatus(.denied)
        XCTAssertFutureFails(future, context: TestContext.immediate) { error in
            XCTAssert(self.mock.requestAlwaysAuthorizationCalled)
            XCTAssertEqualErrors(error, LocationError.authorizationAlwaysFailed)
        }
    }

    func testAuthorized_WhenAuthorizedWhenInUseRequestedAndStatusIsAuthorizedWhenInUse_CompletesSuccessfully() {
        CLLocationManagerMock._authorizationStatus = .authorizedWhenInUse
        let future = self.locationManager.authorize(.authorizedWhenInUse)
        XCTAssertFutureSucceeds(future, context: TestContext.immediate) {
            XCTAssertFalse(self.mock.requestWhenInUseAuthorizationCalled)
        }
    }
    
    func testAuthorized_WhenAuthorizedWhenInUseRequestedAndStatusIsNotDetermined_CompletesSuccessfully() {
        CLLocationManagerMock._authorizationStatus = .notDetermined
        let future = self.locationManager.authorize(.authorizedWhenInUse)
        self.locationManager.didChangeAuthorizationStatus(.authorizedWhenInUse)
        XCTAssertFutureSucceeds(future, context: TestContext.immediate) {
            XCTAssert(self.mock.requestWhenInUseAuthorizationCalled)
        }
    }
    
    func testAuthorized_WhenAuthorizedWhenInUseRequestedAndRequestDenied_CompletesWithError() {
        CLLocationManagerMock._authorizationStatus = .notDetermined
        let future = self.locationManager.authorize(.authorizedWhenInUse)
        locationManager.didChangeAuthorizationStatus(.denied)
        XCTAssertFutureFails(future, context: TestContext.immediate) { error in
            XCTAssert(self.mock.requestWhenInUseAuthorizationCalled)
            XCTAssertEqualErrors(error, LocationError.authorizationWhenInUseFailed)
        }
    }
    

    func testStartUpdatingLocation_WhenAuthorizedAlwaysAndUpdateSucceeds_CompletesSuccessfully() {
        CLLocationManagerMock._authorizationStatus = .authorizedAlways
        let stream = self.locationManager.startUpdatingLocation(authorization: .authorizedAlways, context: TestContext.immediate)
        self.locationManager.didUpdateLocations(self.testLocations)
        XCTAssertFutureStreamSucceeds(stream, context: TestContext.immediate, validations: [
            { locations in
                XCTAssert(locations.count == 2)
                XCTAssert(self.mock.startUpdatingLocationCalled)
                XCTAssert(self.locationManager.isUpdating)
            }
        ])
    }
    
    func testStartUpdatingLocation_WhenAuthorizedAlwaysAndUpdateFails_CompletesWithError() {
        CLLocationManagerMock._authorizationStatus = .authorizedAlways
        let stream = self.locationManager.startUpdatingLocation(authorization: .authorizedAlways, context: TestContext.immediate)
        self.locationManager.didFailWithError(TestFailure.error)
        XCTAssertFutureStreamFails(stream, context: TestContext.immediate, validations: [
            { error in
                XCTAssert(self.mock.startUpdatingLocationCalled)
                XCTAssertEqualErrors(error, TestFailure.error)
                XCTAssertFalse(self.locationManager.isUpdating)
            }
        ])
    }

    func testStartUpdatingLocation_WhenAuthorizationFails_CompletesWithError() {
        CLLocationManagerMock._authorizationStatus = .notDetermined
        let stream = self.locationManager.startUpdatingLocation(authorization: .authorizedAlways, context: TestContext.immediate)
        self.locationManager.didChangeAuthorizationStatus(.denied)
        XCTAssertFutureStreamFails(stream, context: TestContext.immediate, validations: [
            { error in
                XCTAssertFalse(self.mock.startUpdatingLocationCalled)
                XCTAssertEqualErrors(error, LocationError.authorizationAlwaysFailed)
                XCTAssertFalse(self.locationManager.isUpdating)
            }
        ])
    }

    func testStopUpdatingLocation_WhenLocationIsUpdating_StopsUpdating() {
        CLLocationManagerMock._authorizationStatus = .authorizedAlways
        let stream = self.locationManager.startUpdatingLocation(authorization: .authorizedAlways, context: TestContext.immediate)
        stream.onSuccess(context: TestContext.immediate) { locations in
            XCTFail()
        }
        stream.onFailure(context: TestContext.immediate) { error in
            XCTFail()
        }
        self.locationManager.stopUpdatingLocation()
        XCTAssert(self.mock.stopUpdatingLocationCalled)
        XCTAssertFalse(self.locationManager.isUpdating)
        self.locationManager.didUpdateLocations(self.testLocations)
    }
 
    func testStartMonitoringSignificantLocationChanges_WhenAuthorizedAlwaysAndUpdateSucceeds_CompletesSuccessfully() {
        CLLocationManagerMock._authorizationStatus = .authorizedAlways
        let stream = self.locationManager.startMonitoringSignificantLocationChanges(authorization:.authorizedAlways, context: TestContext.immediate)
        self.locationManager.didUpdateLocations(self.testLocations)
        XCTAssertFutureStreamSucceeds(stream, context: TestContext.immediate, validations: [
            { locations in
                XCTAssert(locations.count == 2)
                XCTAssert(self.mock.startMonitoringSignificantLocationChangesCalled)
                XCTAssert(self.locationManager.isUpdating)
            }
        ])
    }
    
    func testStartMonitoringSignificantLocationChanges_WhenAuthorizedAlwaysAndUpdateFails_CompletesWithError() {
        CLLocationManagerMock._authorizationStatus = .authorizedAlways
        let stream = self.locationManager.startMonitoringSignificantLocationChanges(authorization:.authorizedAlways, context: TestContext.immediate)
        self.locationManager.didFailWithError(TestFailure.error)
        XCTAssertFutureStreamFails(stream, context: TestContext.immediate, validations: [
            { error in
                XCTAssert(self.mock.startMonitoringSignificantLocationChangesCalled)
                XCTAssertEqualErrors(error, TestFailure.error)
                XCTAssertFalse(self.locationManager.isUpdating)
            }
        ])
    }

    func testStartMonitoringSignificantLocationChanges_WhenAuthorizationFails_CompletesWithError() {
        CLLocationManagerMock._authorizationStatus = .notDetermined
        let stream = self.locationManager.startMonitoringSignificantLocationChanges(authorization:.authorizedAlways)
        self.locationManager.didChangeAuthorizationStatus(.denied)
        XCTAssertFutureStreamFails(stream, context: TestContext.immediate, validations: [
            { error in
                XCTAssertFalse(self.mock.startMonitoringSignificantLocationChangesCalled)
                XCTAssertEqualErrors(error, LocationError.authorizationAlwaysFailed)
                XCTAssertFalse(self.locationManager.isUpdating)
            }
        ])
    }

    func testStopMonitoringSignificantLocationChanges_WhenLocationIsUpdating_StopsUpdating() {
        CLLocationManagerMock._authorizationStatus = .authorizedAlways
        let stream = self.locationManager.startMonitoringSignificantLocationChanges(authorization: .authorizedAlways, context: TestContext.immediate)
        stream.onSuccess(context: TestContext.immediate) { locations in
            XCTFail()
        }
        stream.onFailure(context: TestContext.immediate) { error in
            XCTFail()
        }
        self.locationManager.stopMonitoringSignificantLocationChanges()
        XCTAssert(self.mock.stopMonitoringSignificantLocationChangesCalled)
        XCTAssertFalse(self.locationManager.isUpdating)
        self.locationManager.didUpdateLocations(self.testLocations)
    }


    func testAllowDeferredLocationUpdatesUntilTraveled_WhenUpdateSucceeds_CompletesSuccessfully() {
        CLLocationManagerMock._authorizationStatus = .authorizedAlways
        let future = self.locationManager.allowDeferredLocationUpdatesUntilTraveled(1000.0, timeout: 300.0)
        self.locationManager.didFinishDeferredUpdatesWithError(nil)
        XCTAssertFutureSucceeds(future, context: TestContext.immediate) {
            XCTAssert(self.mock.allowDeferredLocationUpdatesUntilTraveledCalled)
        }
    }

    func testAllowDeferredLocationUpdatesUntilTraveled_WhenUpdateFails_CompletesWithError() {
        CLLocationManagerMock._authorizationStatus = .authorizedAlways
        let future = self.locationManager.allowDeferredLocationUpdatesUntilTraveled(1000.0, timeout: 300.0)
        self.locationManager.didFinishDeferredUpdatesWithError(TestFailure.error)
        XCTAssertFutureFails(future, context: TestContext.immediate) { error in
            XCTAssert(self.mock.allowDeferredLocationUpdatesUntilTraveledCalled)
            XCTAssertEqualErrors(error, TestFailure.error)
        }
    }

}
