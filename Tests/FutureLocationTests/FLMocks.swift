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

    static var _authorizationStatus = CLAuthorizationStatus.NotDetermined
    static var _isRangingAvailable = true
    static var _significantLocationChangeMonitoringAvailable = true
    static var _deferredLocationUpdatesAvailable = true
    static var _locationServicesEnabled = true

    var requestAlwaysAuthorizationCalled = false
    var requestWhenInUseAuthorizationCalled = false
    var startUpdatingLocationCalled = false
    var stopUpdatingLocationCalled = false
    var allowDeferredLocationUpdatesUntilTraveledCalled = false
    var startMonitoringSignificantLocationChangesCalled = false
    var stopMonitoringSignificantLocationChangesCalled = false
    var startMonitoringForRegionCalled = false
    var stopMonitoringForRegionCalled = false
    var startRangingBeaconsInRegionCalled = false
    var stopRangingBeaconsInRegionCalled = false
    var requestStateForRegionCalled = false

    var allowDeferredLocationUpdatesUntilTraveledDistance: CLLocationDistance?
    var allowDeferredLocationUpdatesUntilTraveledTimeout: NSTimeInterval?
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
    var activityType = CLActivityType.Fitness
    var distanceFilter: CLLocationDistance = kCLDistanceFilterNone
    var desiredAccuracy: CLLocationAccuracy = kCLLocationAccuracyBest

    // MARK: Location Updates
    var location: CLLocation?

    static func locationServicesEnabled() -> Bool {
        return self._locationServicesEnabled
    }

    func startUpdatingLocation() {
        self.startUpdatingLocationCalled = true
    }

    func stopUpdatingLocation() {
        self.stopUpdatingLocationCalled = true
    }

    // MARK: Deferred Location Updates
    class func deferredLocationUpdatesAvailable() -> Bool {
        return self._deferredLocationUpdatesAvailable
    }

    func allowDeferredLocationUpdatesUntilTraveled(distance: CLLocationDistance, timeout: NSTimeInterval) {
        self.allowDeferredLocationUpdatesUntilTraveledCalled = true
        self.allowDeferredLocationUpdatesUntilTraveledDistance = distance
        self.allowDeferredLocationUpdatesUntilTraveledTimeout = timeout
    }

    // MARK: Significant Change in Location
    class func significantLocationChangeMonitoringAvailable() -> Bool {
        return self._significantLocationChangeMonitoringAvailable
    }

    func startMonitoringSignificantLocationChanges() {
        self.startMonitoringSignificantLocationChangesCalled = true
    }

    func stopMonitoringSignificantLocationChanges() {
        self.stopMonitoringSignificantLocationChangesCalled = true
    }

    // MARK: Region Monitoring
    var maximumRegionMonitoringDistance: CLLocationDistance = 1000.0

    var monitoredRegions = Set<CLRegion>()

    func startMonitoringForRegion(region: CLRegion) {
        self.startMonitoringForRegionCalled = true
        self.startMonitoringForRegionRegion = region
    }

    func stopMonitoringForRegion(region: CLRegion) {
        self.stopMonitoringForRegionCalled = true
        self.stopMonitoringForRegionRegion = region
    }

    func requestStateForRegion(region: CLRegion) {
        self.requestStateForRegionCalled = true
        self.requestStateForRegionRegion = region
    }

    // MARK: Beacons
    class func isRangingAvailable() -> Bool {
        return self._isRangingAvailable
    }

    var rangedRegions = Set<CLRegion>()

    func startRangingBeaconsInRegion(region: CLBeaconRegion) {
        self.startRangingBeaconsInRegionCalled = true
        self.startRangingBeaconsInRegionRegion = region
    }

    func stopRangingBeaconsInRegion(region: CLBeaconRegion) {
        self.stopRangingBeaconsInRegionCalled = true
        self.stopRangingBeaconsInRegionRegion = region
    }

    init() {}

}

// MARK: - Test Classes -
class LocationManagerUT : FLLocationManager {

    override func authorizationStatus() -> CLAuthorizationStatus {
        return CLLocationManagerMock.authorizationStatus()
    }
}

class RegionManagerUT : FLRegionManager {

    override func authorizationStatus() -> CLAuthorizationStatus {
        return CLLocationManagerMock.authorizationStatus()
    }

}

class BeaconManagerUT : FLBeaconManager {

    override func authorizationStatus() -> CLAuthorizationStatus {
        return CLLocationManagerMock.authorizationStatus()
    }

}

// MARK: - CLBeaconMock -
class CLBeaconMock : CLBeaconInjectable {
    let proximityUUID: NSUUID
    let major: NSNumber
    let minor: NSNumber
    let proximity: CLProximity
    let accuracy: CLLocationAccuracy
    let rssi: Int
    init(proximityUUID: NSUUID, major: NSNumber, minor: NSNumber, proximity: CLProximity, accuracy: CLLocationAccuracy, rssi: Int) {
        self.proximityUUID = proximityUUID
        self.major = major
        self.minor = minor
        self.proximity = proximity
        self.accuracy = accuracy
        self.rssi = rssi
    }
}



