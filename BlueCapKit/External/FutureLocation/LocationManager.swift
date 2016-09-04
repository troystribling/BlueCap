//
//  LocationManager.swift
//  BlueCap
//
//  Created by Troy Stribling on 9/1/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import Foundation
import CoreLocation

// MARK: - Errors -
public enum LocationError : Swift.Error {
    case notAvailable
    case updateFailed
    case authorizationAlwaysFailed
    case authorizationWhenInUseFailed
    case notSupportedForIOSVersion
}

// MARK: - CLLocationManagerInjectable -
public protocol CLLocationManagerInjectable {

    var delegate: CLLocationManagerDelegate? { get set }

    // MARK: Authorization
    static func authorizationStatus() -> CLAuthorizationStatus
    func requestAlwaysAuthorization()
    func requestWhenInUseAuthorization()

    // MARK: Configure
    var pausesLocationUpdatesAutomatically: Bool { get set }
    var activityType: CLActivityType { get set }
    var distanceFilter : CLLocationDistance { get set }
    var desiredAccuracy: CLLocationAccuracy { get set }

    // MARK: Location Updates
    var location: CLLocation? { get }
    static func locationServicesEnabled() -> Bool
    func startUpdatingLocation()
    func stopUpdatingLocation()

     // MARK: Deferred Location Updates
    static func deferredLocationUpdatesAvailable() -> Bool
    func allowDeferredLocationUpdatesUntilTraveled(_ distance: CLLocationDistance, timeout: Double)

    // MARK: Significant Change in Location
    static func significantLocationChangeMonitoringAvailable() -> Bool
    func startMonitoringSignificantLocationChanges()
    func stopMonitoringSignificantLocationChanges()

    // MARK: Region Monitoring
    var maximumRegionMonitoringDistance: CLLocationDistance { get }
    var monitoredRegions: Set<CLRegion> { get }
    func startMonitoringForRegion(_ region: CLRegion)
    func stopMonitoringForRegion(_ region: CLRegion)

    // MARK: Beacons
    static func isRangingAvailable() -> Bool
    var rangedRegions: Set<CLRegion> { get }
    func startRangingBeaconsInRegion(_ region: CLBeaconRegion)
    func stopRangingBeaconsInRegion(_ region: CLBeaconRegion)
    func requestStateForRegion(_ region: CLRegion)
}

extension CLLocationManager : CLLocationManagerInjectable {}

// MARK: - FLLocationManager -
public class LocationManager : NSObject, CLLocationManagerDelegate {

    // MARK: Serilaize Property IO
    static let ioQueue = Queue("us.gnos.futureLocation.location-manager.io")


    // MARK: Properties
    fileprivate var _locationUpdatePromise: StreamPromise<[CLLocation]>?
    fileprivate var _deferredLocationUpdatePromise: Promise<Void>?
    fileprivate var _requestLocationPromise: Promise<[CLLocation]>?
    fileprivate var _authorizationStatusChangedPromise: Promise<CLAuthorizationStatus>?

    fileprivate var _isUpdating = false

    internal fileprivate(set) var clLocationManager: CLLocationManagerInjectable

    public fileprivate(set) var isUpdating: Bool {
        get {
            return LocationManager.ioQueue.sync { return self._isUpdating }
        }
        set {
            LocationManager.ioQueue.sync { self._isUpdating = newValue }
        }
    }

    fileprivate var locationUpdatePromise: StreamPromise<[CLLocation]>? {
        get {
            return LocationManager.ioQueue.sync { return self._locationUpdatePromise }
        }
        set {
            LocationManager.ioQueue.sync { self._locationUpdatePromise = newValue }
        }
    }

    fileprivate var deferredLocationUpdatePromise: Promise<Void>? {
        get {
            return LocationManager.ioQueue.sync { return self._deferredLocationUpdatePromise}
        }
        set {
            LocationManager.ioQueue.sync { self._deferredLocationUpdatePromise = newValue }
        }
    }

    fileprivate var requestLocationPromise: Promise<[CLLocation]>? {
        get {
            return LocationManager.ioQueue.sync { return self._requestLocationPromise }
        }
        set {
            LocationManager.ioQueue.sync { self._requestLocationPromise = newValue }
        }
    }

    fileprivate var authorizationStatusChangedPromise: Promise<CLAuthorizationStatus>? {
        get {
            return LocationManager.ioQueue.sync { return self._authorizationStatusChangedPromise }
        }
        set {
            LocationManager.ioQueue.sync { self._authorizationStatusChangedPromise = newValue }
        }
    }

    // MARK: Configure
    public var pausesLocationUpdatesAutomatically: Bool {
        get {
            return self.clLocationManager.pausesLocationUpdatesAutomatically
        }
        set {
            self.clLocationManager.pausesLocationUpdatesAutomatically = newValue
        }
    }

    public var allowsBackgroundLocationUpdates: Bool {
        get {
            if let locationManager = self.clLocationManager as? CLLocationManager {
                return locationManager.allowsBackgroundLocationUpdates
            } else {
                return false
            }
        }
        set {
            if let locationManager = self.clLocationManager as? CLLocationManager {
                locationManager.allowsBackgroundLocationUpdates = newValue
            }
        }
    }

    public var activityType: CLActivityType {
        get {
            return self.clLocationManager.activityType
        }
        set {
            self.clLocationManager.activityType = newValue
        }
    }

    public var distanceFilter: CLLocationDistance {
        get {
            return self.clLocationManager.distanceFilter
        }
        set {
            self.clLocationManager.distanceFilter = newValue
        }
    }
    
    public var desiredAccuracy: CLLocationAccuracy {
        get {
            return self.clLocationManager.desiredAccuracy
        }
        set {
            self.clLocationManager.desiredAccuracy = newValue
        }
    }

    // MARK: Authorization
    public func authorizationStatus() -> CLAuthorizationStatus {
        return CLLocationManager.authorizationStatus()
    }

    fileprivate func requestWhenInUseAuthorization()  {
        self.clLocationManager.requestWhenInUseAuthorization()
    }

    fileprivate func requestAlwaysAuthorization() {
        self.clLocationManager.requestAlwaysAuthorization()
    }

    public func authorize(_ authorization: CLAuthorizationStatus) -> Future<Void> {
        let currentAuthorization = self.authorizationStatus()
        let promise = Promise<Void>()
        if currentAuthorization != authorization {
            self.authorizationStatusChangedPromise = Promise<CLAuthorizationStatus>()
            switch authorization {
            case .authorizedAlways:
                self.authorizationStatusChangedPromise?.future.onSuccess {(status) in
                    if status == .authorizedAlways {
                        Logger.debug("location AuthorizedAlways succcess")
                        promise.success()
                    } else {
                        Logger.debug("location AuthorizedAlways failed")
                        promise.failure(LocationError.authorizationAlwaysFailed)
                    }
                }
                self.requestAlwaysAuthorization()
                break
            case .authorizedWhenInUse:
                self.authorizationStatusChangedPromise?.future.onSuccess {(status) in
                    if status == .authorizedWhenInUse {
                        Logger.debug("location AuthorizedWhenInUse succcess")
                        promise.success()
                    } else {
                        Logger.debug("location AuthorizedWhenInUse failed")
                        promise.failure(LocationError.authorizationWhenInUseFailed)
                    }
                }
                self.requestWhenInUseAuthorization()
                break
            default:
                Logger.debug("location authorization invalid")
                break
            }
        } else {
            promise.success()
        }
        return promise.future
    }

    //MARK: Initialize
    public convenience override init() {
        self.init(clLocationManager: CLLocationManager())
    }

    public init(clLocationManager: CLLocationManagerInjectable) {
        self.clLocationManager = clLocationManager
        super.init()
        self.clLocationManager.delegate = self
    }

    // MARK: Reverse Geocode
    public class func reverseGeocodeLocation(_ location: CLLocation) -> Future<[CLPlacemark]>  {
        let geocoder = CLGeocoder()
        let promise = Promise<[CLPlacemark]>()
        geocoder.reverseGeocodeLocation(location) { (placemarks: [CLPlacemark]?, error: Swift.Error?) -> Void in
            if let error = error {
                promise.failure(error)
            } else {
                if let placemarks = placemarks {
                    promise.success(placemarks)
                } else {
                    promise.success([CLPlacemark]())
                }
            }
        }
        return promise.future
    }

    public func reverseGeocodeLocation()  -> Future<[CLPlacemark]>  {
        if let location = self.location {
            return LocationManager.reverseGeocodeLocation(location)
        } else {
            return Future(error: LocationError.updateFailed)
        }
    }

    // MARK: Location Updates
    public var location: CLLocation? {
        return self.clLocationManager.location
    }

    public func locationServicesEnabled() -> Bool {
        return CLLocationManager.locationServicesEnabled()
    }

    public func startUpdatingLocation(capacity: Int = Int.max, authorization: CLAuthorizationStatus = .authorizedWhenInUse, context: ExecutionContext = QueueContext.main) -> FutureStream<[CLLocation]> {
        self.locationUpdatePromise = StreamPromise<[CLLocation]>(capacity:capacity)
        let authorizationFuture = self.authorize(authorization)
        authorizationFuture.onSuccess(context: context) {status in
            self.clLocationManager.startUpdatingLocation()
        }
        authorizationFuture.onFailure(context: context) {error in
            self.isUpdating = false
            self.locationUpdatePromise!.failure(error)
        }
        return self.locationUpdatePromise!.stream
    }

    public func stopUpdatingLocation() {
        self.isUpdating = false
        self.locationUpdatePromise = nil
        self.clLocationManager.stopUpdatingLocation()
    }

    public func requestLocation(authorization: CLAuthorizationStatus = .authorizedAlways, context: ExecutionContext = QueueContext.main) -> Future<[CLLocation]> {
        self.requestLocationPromise = Promise<[CLLocation]>()
        guard let clLocationManager = self.clLocationManager as? CLLocationManager else {
            self.requestLocationPromise?.failure(LocationError.notSupportedForIOSVersion)
            return self.requestLocationPromise!.future
        }
        self.requestLocationPromise = Promise<[CLLocation]>()
        let authoriztaionFuture = self.authorize(authorization)
        authoriztaionFuture.onSuccess(context: context) {status in
            clLocationManager.requestLocation()
        }
        authoriztaionFuture.onFailure(context: context) {error in
            self.isUpdating = false
            self.requestLocationPromise!.failure(error)
        }
        return self.requestLocationPromise!.future
    }

    // MARK: Significant Change in Location
    public class func significantLocationChangeMonitoringAvailable() -> Bool {
        return CLLocationManager.significantLocationChangeMonitoringAvailable()
    }

    public func startMonitoringSignificantLocationChanges(capacity: Int = Int.max, authorization: CLAuthorizationStatus = .authorizedAlways, context: ExecutionContext = QueueContext.main) -> FutureStream<[CLLocation]> {
        self.locationUpdatePromise = StreamPromise<[CLLocation]>(capacity: capacity)
        let authoriztaionFuture = self.authorize(authorization)
        authoriztaionFuture.onSuccess(context: context) {status in
            self.clLocationManager.startMonitoringSignificantLocationChanges()
        }
        authoriztaionFuture.onFailure(context: context) {error in
            self.isUpdating = false
            self.locationUpdatePromise!.failure(error)
        }
        return self.locationUpdatePromise!.stream
    }
    
    public func stopMonitoringSignificantLocationChanges() {
        self.isUpdating = false
        self.locationUpdatePromise  = nil
        self.clLocationManager.stopMonitoringSignificantLocationChanges()
    }

    // MARK: Deferred Location Updates
    public func deferredLocationUpdatesAvailable() -> Bool {
        return CLLocationManager.deferredLocationUpdatesAvailable()
    }

    public func allowDeferredLocationUpdatesUntilTraveled(_ distance: CLLocationDistance, timeout: Double) -> Future<Void> {
        self.deferredLocationUpdatePromise = Promise<Void>()
        self.clLocationManager.allowDeferredLocationUpdatesUntilTraveled(distance, timeout: timeout)
        return self.deferredLocationUpdatePromise!.future
    }

    // MARK: CLLocationManagerDelegate
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.didUpdate(locations: locations)
    }

    @nonobjc public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        self.didFail(withError: error)
    }

    @nonobjc public func locationManager(_ manager: CLLocationManager, didFinishDeferredUpdatesWithError error: Error?) {
        self.didFinishDeferredUpdates(withError: error)
    }
        
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        self.didChangeAuthorization(status: status)
    }

    public func didUpdate(locations locations: [CLLocation]) {
        Logger.debug()
        self.isUpdating = true
        if let requestLocationPromise = self.requestLocationPromise {
            requestLocationPromise.success(locations)
            self.requestLocationPromise = nil
        }
        self.locationUpdatePromise?.success(locations)
    }

    public func didFail(withError error: Error) {
        Logger.debug("error \(error.localizedDescription)")
        self.isUpdating = false
        if let requestLocationPromise = self.requestLocationPromise {
            requestLocationPromise.failure(error)
            self.requestLocationPromise = nil
        }
        self.locationUpdatePromise?.failure(error)
    }

    public func didFinishDeferredUpdates(withError error: Error?) {
        if let error = error {
            self.deferredLocationUpdatePromise?.failure(error)
        } else {
            self.deferredLocationUpdatePromise?.success()
        }
    }

    public func didChangeAuthorization(status status: CLAuthorizationStatus) {
        Logger.debug("status: \(status)")
        self.authorizationStatusChangedPromise?.success(status)
    }

}
