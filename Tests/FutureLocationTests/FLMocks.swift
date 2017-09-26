//
//  FLMocks.swift
//  FutureLocation
//
//  Created by Troy Stribling on 4/12/15.
//  Copyright (c) 2015 Troy Stribling. The MIT License (MIT).
//

import UIKit
import CoreLocation
@testable import BlueCapKit

// MARK: - CLLocationManagerMock -
class CLLocationManagerMock : CLLocationManagerInjectable {

    static var _authorizationStatus = CLAuthorizationStatus.notDetermined
    static var _isRangingAvailable = true
    static var _significantLocationChangeMonitoringAvailable = true
    static var _deferredLocationUpdatesAvailable = true
    static var _locationServicesEnabled = true

    var requestAlwaysAuthorizationCalled = false
    var requestWhenInUseAuthorizationCalled = false
    var startUpdatingLocationCalled = false
    var stopUpdatingLocationCalled = false
    var requestLocationCalled = false
    var allowDeferredLocationUpdatesUntilTraveledCalled = false
    var startMonitoringSignificantLocationChangesCalled = false
    var stopMonitoringSignificantLocationChangesCalled = false
    var startMonitoringForRegionCalled = false
    var stopMonitoringForRegionCalled = false
    var startRangingBeaconsInRegionCalled = false
    var stopRangingBeaconsInRegionCalled = false
    var requestStateForRegionCalled = false

    var allowDeferredLocationUpdatesUntilTraveledDistance: CLLocationDistance?
    var allowDeferredLocationUpdatesUntilTraveledTimeout: TimeInterval?
    var startMonitoringForRegionRegion: CLRegion?
    var stopMonitoringForRegionRegion: CLRegion?
    var requestStateForRegionRegion: CLRegion?
    var startRangingBeaconsInRegionRegion: CLBeaconRegion?
    var stopRangingBeaconsInRegionRegion: CLBeaconRegion?

    var delegate: CLLocationManagerDelegate?

    // MARK: Authorization
    class func authorizationStatus() -> CLAuthorizationStatus {
        return self._authorizationStatus
    }

    func requestAlwaysAuthorization() {
        self.requestAlwaysAuthorizationCalled = true
    }

    func requestWhenInUseAuthorization() {
        self.requestWhenInUseAuthorizationCalled = true
    }

    // MARK: Configure
    var pausesLocationUpdatesAutomatically = false
    var allowsBackgroundLocationUpdates = false
    var activityType = CLActivityType.fitness
    var distanceFilter: CLLocationDistance = kCLDistanceFilterNone
    var desiredAccuracy: CLLocationAccuracy = kCLLocationAccuracyBest

    // MARK: Location Updates
    var location: CLLocation?

    static func locationServicesEnabled() -> Bool {
        return _locationServicesEnabled
    }

    func startUpdatingLocation() {
        startUpdatingLocationCalled = true
    }

    func stopUpdatingLocation() {
        stopUpdatingLocationCalled = true
    }

    // MARK: request location
    func requestLocation() {
        requestLocationCalled = true
    }


    // MARK: Deferred Location Updates
    class func deferredLocationUpdatesAvailable() -> Bool {
        return _deferredLocationUpdatesAvailable
    }

    func allowDeferredLocationUpdates(untilTraveled distance: CLLocationDistance, timeout: TimeInterval) {
        allowDeferredLocationUpdatesUntilTraveledCalled = true
        allowDeferredLocationUpdatesUntilTraveledDistance = distance
        allowDeferredLocationUpdatesUntilTraveledTimeout = timeout
    }

    // MARK: Significant Change in Location
    class func significantLocationChangeMonitoringAvailable() -> Bool {
        return _significantLocationChangeMonitoringAvailable
    }

    func startMonitoringSignificantLocationChanges() {
        startMonitoringSignificantLocationChangesCalled = true
    }

    func stopMonitoringSignificantLocationChanges() {
        stopMonitoringSignificantLocationChangesCalled = true
    }

    // MARK: Region Monitoring
    var maximumRegionMonitoringDistance: CLLocationDistance = 1000.0

    var monitoredRegions = Set<CLRegion>()

    func startMonitoring(for region: CLRegion) {
        startMonitoringForRegionCalled = true
        startMonitoringForRegionRegion = region
    }

    func stopMonitoring(for region: CLRegion) {
        stopMonitoringForRegionCalled = true
        stopMonitoringForRegionRegion = region
    }

    func requestState(for region: CLRegion) {
        requestStateForRegionCalled = true
        requestStateForRegionRegion = region
    }

    // MARK: Beacons
    class func isRangingAvailable() -> Bool {
        return _isRangingAvailable
    }

    var rangedRegions = Set<CLRegion>()

    func startRangingBeacons(in region: CLBeaconRegion) {
        startRangingBeaconsInRegionCalled = true
        startRangingBeaconsInRegionRegion = region
    }

    func stopRangingBeacons(in region: CLBeaconRegion) {
        stopRangingBeaconsInRegionCalled = true
        stopRangingBeaconsInRegionRegion = region
    }

    init() {}

}

// MARK: - Test Classes -
class LocationManagerUT : LocationManager {

    override func authorizationStatus() -> CLAuthorizationStatus {
        return CLLocationManagerMock.authorizationStatus()
    }
}

class RegionManagerUT : RegionManager {

    override func authorizationStatus() -> CLAuthorizationStatus {
        return CLLocationManagerMock.authorizationStatus()
    }

}

class BeaconManagerUT : BeaconManager {

    override func authorizationStatus() -> CLAuthorizationStatus {
        return CLLocationManagerMock.authorizationStatus()
    }

}

// MARK: - CLBeaconMock -
class CLBeaconMock : CLBeaconInjectable {
    let proximityUUID: UUID
    let major: NSNumber
    let minor: NSNumber
    let proximity: CLProximity
    let accuracy: CLLocationAccuracy
    let rssi: Int
    init(proximityUUID: UUID, major: NSNumber, minor: NSNumber, proximity: CLProximity, accuracy: CLLocationAccuracy, rssi: Int) {
        self.proximityUUID = proximityUUID
        self.major = major
        self.minor = minor
        self.proximity = proximity
        self.accuracy = accuracy
        self.rssi = rssi
    }
}



