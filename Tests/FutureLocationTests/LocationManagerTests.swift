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

    // MARK: authorize
    func testAuthorize_WhenAuthorizedAlwaysRequestedAndStatusIsAuthorizedAlways_CompletesSuccessfully() {
        CLLocationManagerMock._authorizationStatus = .authorizedAlways
        let future = self.locationManager.authorize(.authorizedAlways, context: TestContext.immediate)
        XCTAssertFutureSucceeds(future, context: TestContext.immediate) { _ in
            XCTAssertFalse(self.mock.requestAlwaysAuthorizationCalled)
        }
    }

    func testAuthorize_WhenAuthorizedAlwaysRequestedAndStatusIsNotDetermined_CompletesSuccessfully() {
        CLLocationManagerMock._authorizationStatus = .notDetermined
        let future = self.locationManager.authorize(.authorizedAlways, context: TestContext.immediate)
        self.locationManager.didChangeAuthorization(status: .authorizedAlways)
        XCTAssertFutureSucceeds(future, context: TestContext.immediate) { _ in
            XCTAssertTrue(self.mock.requestAlwaysAuthorizationCalled)
        }
    }

    func testAuthorize_WhenAuthorizedAlwaysRequestedAndStatusIsAuthorizedWhenInUse_CompletesSuccessfully() {
        CLLocationManagerMock._authorizationStatus = .authorizedWhenInUse
        let future = self.locationManager.authorize(.authorizedAlways, context: TestContext.immediate)
        self.locationManager.didChangeAuthorization(status: .authorizedAlways)
        XCTAssertFutureFails(future, context: TestContext.immediate) { error in
            XCTAssertFalse(self.mock.requestAlwaysAuthorizationCalled)
            XCTAssertEqualErrors(error, LocationError.authorizationInvalid)
        }
    }


    func testAuthorize_WhenAuthorizedAlwaysRequestedAndRequestDenied_CompletesWithError() {
        CLLocationManagerMock._authorizationStatus = .notDetermined
        let future = self.locationManager.authorize(.authorizedAlways, context: TestContext.immediate)
        self.locationManager.didChangeAuthorization(status: .denied)
        XCTAssertFutureFails(future, context: TestContext.immediate) { error in
            XCTAssert(self.mock.requestAlwaysAuthorizationCalled)
            XCTAssertEqualErrors(error, LocationError.authorizationAlwaysFailed)
        }
    }

    func testAuthorize_WhenAuthorizedWhenInUseRequestedAndStatusIsAuthorizedWhenInUse_CompletesSuccessfully() {
        CLLocationManagerMock._authorizationStatus = .authorizedWhenInUse
        let future = self.locationManager.authorize(.authorizedWhenInUse, context: TestContext.immediate)
        XCTAssertFutureSucceeds(future, context: TestContext.immediate) { _ in
            XCTAssertFalse(self.mock.requestWhenInUseAuthorizationCalled)
        }
    }
    
    func testAuthorize_WhenAuthorizedWhenInUseRequestedAndStatusIsNotDetermined_CompletesSuccessfully() {
        CLLocationManagerMock._authorizationStatus = .notDetermined
        let future = self.locationManager.authorize(.authorizedWhenInUse, context: TestContext.immediate)
        self.locationManager.didChangeAuthorization(status: .authorizedWhenInUse)
        XCTAssertFutureSucceeds(future, context: TestContext.immediate) { _ in
            XCTAssert(self.mock.requestWhenInUseAuthorizationCalled)
        }
    }
    
    func testAuthorize_WhenAuthorizedWhenInUseRequestedAndRequestDenied_CompletesWithError() {
        CLLocationManagerMock._authorizationStatus = .notDetermined
        let future = self.locationManager.authorize(.authorizedWhenInUse, context: TestContext.immediate)
        locationManager.didChangeAuthorization(status: .denied)
        XCTAssertFutureFails(future, context: TestContext.immediate) { error in
            XCTAssert(self.mock.requestWhenInUseAuthorizationCalled)
            XCTAssertEqualErrors(error, LocationError.authorizationWhenInUseFailed)
        }
    }

    func testAuthorize_WhenRequestMadeBeforePreviousRequestCompletes_CompletesSuccessfully() {
        CLLocationManagerMock._authorizationStatus = .notDetermined
        let future1 = self.locationManager.authorize(.authorizedWhenInUse, context: TestContext.immediate)
        let future2 = self.locationManager.authorize(.authorizedWhenInUse, context: TestContext.immediate)
        self.locationManager.didChangeAuthorization(status: .authorizedWhenInUse)
        XCTAssertFutureSucceeds(future1, context: TestContext.immediate)
        XCTAssertFutureSucceeds(future2, context: TestContext.immediate)
    }

    // MARK: startUpdatingLocation
    func testStartUpdatingLocation_WhenAuthorizationSucceeds_CompletesSuccessfully() {
        CLLocationManagerMock._authorizationStatus = .authorizedAlways
        let stream = self.locationManager.startUpdatingLocation(authorization: .authorizedAlways, context: TestContext.immediate)
        self.locationManager.didUpdate(locations: testLocations)
        XCTAssertFutureStreamSucceeds(stream, context: TestContext.immediate, validations: [
            { locations in
                XCTAssert(locations.count == 2)
                XCTAssert(self.mock.startUpdatingLocationCalled)
                XCTAssert(self.locationManager.isUpdating)
            }
        ])
    }
    
    func testStartUpdatingLocation_WhenAuthorizedAndUpdateFails_CompletesWithError() {
        CLLocationManagerMock._authorizationStatus = .authorizedAlways
        let stream = self.locationManager.startUpdatingLocation(authorization: .authorizedAlways, context: TestContext.immediate)
        self.locationManager.didFail(withError: TestFailure.error)
        XCTAssertFutureStreamFails(stream, context: TestContext.immediate, validations: [
            { error in
                XCTAssert(self.mock.startUpdatingLocationCalled)
                XCTAssertEqualErrors(error, TestFailure.error)
                XCTAssertTrue(self.locationManager.isUpdating)
            }
        ])
    }

    func testStartUpdatingLocation_WhenAuthorizationFails_CompletesWithError() {
        CLLocationManagerMock._authorizationStatus = .notDetermined
        let stream = self.locationManager.startUpdatingLocation(authorization: .authorizedAlways, context: TestContext.immediate)
        self.locationManager.didChangeAuthorization(status: .denied)
        XCTAssertFutureStreamFails(stream, context: TestContext.immediate, validations: [
            { error in
                XCTAssertFalse(self.mock.startUpdatingLocationCalled)
                XCTAssertEqualErrors(error, LocationError.authorizationAlwaysFailed)
                XCTAssertFalse(self.locationManager.isUpdating)
            }
        ])
    }

    func testStartUpdatingLocation_WhenAlreadyUpdating_CompletesSuccessfully() {
        CLLocationManagerMock._authorizationStatus = .authorizedAlways
        let stream1 = self.locationManager.startUpdatingLocation(authorization: .authorizedAlways, context: TestContext.immediate)
        let stream2 = self.locationManager.startUpdatingLocation(authorization: .authorizedAlways, context: TestContext.immediate)
        self.locationManager.didUpdate(locations: testLocations)
        XCTAssertFutureStreamSucceeds(stream1, context: TestContext.immediate)
        XCTAssertFutureStreamSucceeds(stream2, context: TestContext.immediate)
    }

    // MARK: stopUpdatingLocation
    func testStopUpdatingLocation_WhenLocationIsUpdating_StopsUpdating() {
        CLLocationManagerMock._authorizationStatus = .authorizedAlways
        let stream = self.locationManager.startUpdatingLocation(authorization: .authorizedAlways, context: TestContext.immediate)
        stream.onSuccess(context: TestContext.immediate) { _ in
            XCTFail()
        }
        stream.onFailure(context: TestContext.immediate) { _ in
            XCTFail()
        }
        self.locationManager.stopUpdatingLocation()
        XCTAssert(self.mock.stopUpdatingLocationCalled)
        XCTAssertFalse(self.locationManager.isUpdating)
        self.locationManager.didUpdate(locations: testLocations)
    }

    // MARK: startMonitoringSignificantLocationChanges
    func testStartMonitoringSignificantLocationChanges_WhenAuthorizedAlwaysAndUpdateSucceeds_CompletesSuccessfully() {
        CLLocationManagerMock._authorizationStatus = .authorizedAlways
        let stream = self.locationManager.startMonitoringSignificantLocationChanges(authorization:.authorizedAlways, context: TestContext.immediate)
        self.locationManager.didUpdate(locations: testLocations)
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
        self.locationManager.didFail(withError: TestFailure.error)
        XCTAssertFutureStreamFails(stream, context: TestContext.immediate, validations: [
            { error in
                XCTAssert(self.mock.startMonitoringSignificantLocationChangesCalled)
                XCTAssertEqualErrors(error, TestFailure.error)
                XCTAssertTrue(self.locationManager.isUpdating)
            }
        ])
    }

    func testStartMonitoringSignificantLocationChanges_WhenAuthorizationFails_CompletesWithError() {
        CLLocationManagerMock._authorizationStatus = .notDetermined
        let stream = self.locationManager.startMonitoringSignificantLocationChanges(authorization:.authorizedAlways, context: TestContext.immediate)
        self.locationManager.didChangeAuthorization(status: .denied)
        XCTAssertFutureStreamFails(stream, context: TestContext.immediate, validations: [
            { error in
                XCTAssertFalse(self.mock.startMonitoringSignificantLocationChangesCalled)
                XCTAssertEqualErrors(error, LocationError.authorizationAlwaysFailed)
                XCTAssertFalse(self.locationManager.isUpdating)
            }
        ])
    }

    func testStartMonitoringSignificantLocationChanges_WhenAlreadyUpdating_CompletesSuccessfully() {
        CLLocationManagerMock._authorizationStatus = .authorizedAlways
        let stream1 = self.locationManager.startMonitoringSignificantLocationChanges(authorization: .authorizedAlways, context: TestContext.immediate)
        let stream2 = self.locationManager.startMonitoringSignificantLocationChanges(authorization: .authorizedAlways, context: TestContext.immediate)
        self.locationManager.didUpdate(locations: testLocations)
        XCTAssertFutureStreamSucceeds(stream1, context: TestContext.immediate)
        XCTAssertFutureStreamSucceeds(stream2, context: TestContext.immediate)
    }

    // MARK: stopMonitoringSignificantLocationChanges
    func testStopMonitoringSignificantLocationChanges_WhenLocationIsUpdating_StopsUpdating() {
        CLLocationManagerMock._authorizationStatus = .authorizedAlways
        let stream = self.locationManager.startMonitoringSignificantLocationChanges(authorization: .authorizedAlways, context: TestContext.immediate)
        stream.onSuccess(context: TestContext.immediate) { _ in
            XCTFail()
        }
        stream.onFailure(context: TestContext.immediate) { _ in
            XCTFail()
        }
        self.locationManager.stopMonitoringSignificantLocationChanges()
        XCTAssert(self.mock.stopMonitoringSignificantLocationChangesCalled)
        XCTAssertFalse(self.locationManager.isUpdating)
        self.locationManager.didUpdate(locations: testLocations)
    }

    // MARK: requestLocation
    func testRequestLocation_WhenAuthorizationSucceeds_CompletesSuccessfully() {
        CLLocationManagerMock._authorizationStatus = .authorizedAlways
        let future = self.locationManager.requestLocation(authorization: .authorizedAlways, context: TestContext.immediate)
        self.locationManager.didUpdate(locations: testLocations)
        XCTAssertFutureSucceeds(future, context: TestContext.immediate) { locations in
            XCTAssert(locations.count == 2)
            XCTAssert(self.mock.requestLocationCalled)
        }
    }

    func testRequestLocation_WhenAuthorizedAndRequestFails_CompletesWithError() {
        CLLocationManagerMock._authorizationStatus = .authorizedAlways
        let future = self.locationManager.requestLocation(authorization: .authorizedAlways, context: TestContext.immediate)
        self.locationManager.didFail(withError: TestFailure.error)
        XCTAssertFutureFails(future, context: TestContext.immediate) { error in
            XCTAssert(self.mock.requestLocationCalled)
            XCTAssertEqualErrors(error, TestFailure.error)
        }
    }

    func testRequestLocation_WhenAuthorizationFails_CompletesWithError() {
        CLLocationManagerMock._authorizationStatus = .notDetermined
        let future = self.locationManager.requestLocation(authorization: .authorizedAlways, context: TestContext.immediate)
        self.locationManager.didChangeAuthorization(status: .denied)
        XCTAssertFutureFails(future, context: TestContext.immediate) { error in
            XCTAssertFalse(self.mock.requestLocationCalled)
            XCTAssertEqualErrors(error, LocationError.authorizationAlwaysFailed)
        }
    }

    func testRequestLocation_WhenRequestInProgress_CompletesSuccessfully() {
        CLLocationManagerMock._authorizationStatus = .authorizedAlways
        let future1 = self.locationManager.requestLocation(authorization: .authorizedAlways, context: TestContext.immediate)
        let future2 = self.locationManager.requestLocation(authorization: .authorizedAlways, context: TestContext.immediate)
        self.locationManager.didUpdate(locations: testLocations)
        XCTAssertFutureSucceeds(future1, context: TestContext.immediate)
        XCTAssertFutureSucceeds(future2, context: TestContext.immediate)
    }

    // MARK: allowDeferredLocationUpdatesUntilTraveled
    func testAllowDeferredLocationUpdatesUntilTraveled_WhenUpdateSucceeds_CompletesSuccessfully() {
        CLLocationManagerMock._authorizationStatus = .authorizedAlways
        let future = self.locationManager.allowDeferredLocationUpdates(untilTraveled: 1000.0, timeout: 300.0)
        self.locationManager.didFinishDeferredUpdates(withError: nil)
        XCTAssertFutureSucceeds(future, context: TestContext.immediate) { _ in
            XCTAssert(self.mock.allowDeferredLocationUpdatesUntilTraveledCalled)
        }
    }

    func testAllowDeferredLocationUpdatesUntilTraveled_WhenUpdateFails_CompletesWithError() {
        CLLocationManagerMock._authorizationStatus = .authorizedAlways
        let future = self.locationManager.allowDeferredLocationUpdates(untilTraveled: 1000.0, timeout: 300.0)
        self.locationManager.didFinishDeferredUpdates(withError: TestFailure.error)
        XCTAssertFutureFails(future, context: TestContext.immediate) { error in
            XCTAssert(self.mock.allowDeferredLocationUpdatesUntilTraveledCalled)
            XCTAssertEqualErrors(error, TestFailure.error)
        }
    }

}
