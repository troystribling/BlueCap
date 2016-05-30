//
//  FLLocationManager.swift
//  BlueCap
//
//  Created by Troy Stribling on 9/1/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import Foundation
import CoreLocation

// MARK: - Errors -
public enum FLErrorCode : Int {
    case NotAvailable               = 0
    case UpdateFailed               = 1
    case AuthorizationAlwaysFailed  = 2
    case AuthorisedWhenInUseFailed  = 3
    case NotSupportedForIOSVersion  = 4
}

public struct FLError {
    public static let domain = "FutureLocation"
    public static let locationUpdateFailed = NSError(domain:domain, code:FLErrorCode.UpdateFailed.rawValue, userInfo:[NSLocalizedDescriptionKey:"Location not available"])
    public static let locationNotAvailable = NSError(domain:domain, code:FLErrorCode.NotAvailable.rawValue, userInfo:[NSLocalizedDescriptionKey:"Location update failed"])
    public static let authorizationAlwaysFailed = NSError(domain:domain, code:FLErrorCode.AuthorizationAlwaysFailed.rawValue, userInfo:[NSLocalizedDescriptionKey:"Authorization failed"])
    public static let authorizationWhenInUseFailed = NSError(domain:domain, code:FLErrorCode.AuthorisedWhenInUseFailed.rawValue, userInfo:[NSLocalizedDescriptionKey:"Authorization when in use failed"])
    public static let notSupportedForIOSVersion = NSError(domain:domain, code:FLErrorCode.NotSupportedForIOSVersion.rawValue, userInfo:[NSLocalizedDescriptionKey:"Feature not supported for this iOS version"])
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
    func allowDeferredLocationUpdatesUntilTraveled(distance: CLLocationDistance, timeout: NSTimeInterval)

    // MARK: Significant Change in Location
    static func significantLocationChangeMonitoringAvailable() -> Bool
    func startMonitoringSignificantLocationChanges()
    func stopMonitoringSignificantLocationChanges()

    // MARK: Region Monitoring
    var maximumRegionMonitoringDistance: CLLocationDistance { get }
    var monitoredRegions: Set<CLRegion> { get }
    func startMonitoringForRegion(region: CLRegion)
    func stopMonitoringForRegion(region: CLRegion)

    // MARK: Beacons
    static func isRangingAvailable() -> Bool
    var rangedRegions: Set<CLRegion> { get }
    func startRangingBeaconsInRegion(region: CLBeaconRegion)
    func stopRangingBeaconsInRegion(region: CLBeaconRegion)
    func requestStateForRegion(region: CLRegion)
}

extension CLLocationManager : CLLocationManagerInjectable {}

// MARK: - FLLocationManager -
public class FLLocationManager : NSObject, CLLocationManagerDelegate {

    // MARK: Serilaize Property IO
    static let ioQueue = Queue("us.gnos.futureLocation.location-manager.io")


    // MARK: Properties
    private var _locationUpdatePromise: StreamPromise<[CLLocation]>?
    private var _deferredLocationUpdatePromise: Promise<Void>?
    private var _requestLocationPromise: Promise<[CLLocation]>?
    private var _authorizationStatusChangedPromise: Promise<CLAuthorizationStatus>?

    private var _isUpdating = false

    internal private(set) var clLocationManager: CLLocationManagerInjectable

    public private(set) var isUpdating: Bool {
        get {
            return FLLocationManager.ioQueue.sync { return self._isUpdating }
        }
        set {
            FLLocationManager.ioQueue.sync { self._isUpdating = newValue }
        }
    }

    private var locationUpdatePromise: StreamPromise<[CLLocation]>? {
        get {
            return FLLocationManager.ioQueue.sync { return self._locationUpdatePromise }
        }
        set {
            FLLocationManager.ioQueue.sync { self._locationUpdatePromise = newValue }
        }
    }

    private var deferredLocationUpdatePromise: Promise<Void>? {
        get {
            return FLLocationManager.ioQueue.sync { return self._deferredLocationUpdatePromise}
        }
        set {
            FLLocationManager.ioQueue.sync { self._deferredLocationUpdatePromise = newValue }
        }
    }

    private var requestLocationPromise: Promise<[CLLocation]>? {
        get {
            return FLLocationManager.ioQueue.sync { return self._requestLocationPromise }
        }
        set {
            FLLocationManager.ioQueue.sync { self._requestLocationPromise = newValue }
        }
    }

    private var authorizationStatusChangedPromise: Promise<CLAuthorizationStatus>? {
        get {
            return FLLocationManager.ioQueue.sync { return self._authorizationStatusChangedPromise }
        }
        set {
            FLLocationManager.ioQueue.sync { self._authorizationStatusChangedPromise = newValue }
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
            if #available(iOS 9.0, *) {
                if let locationManager = self.clLocationManager as? CLLocationManager {
                    return locationManager.allowsBackgroundLocationUpdates
                } else {
                    return false
                }
            } else {
                return false
            }
        }
        set {
            if  #available(iOS 9.0, *) {
                if let locationManager = self.clLocationManager as? CLLocationManager {
                    locationManager.allowsBackgroundLocationUpdates = newValue
                }
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

    private func requestWhenInUseAuthorization()  {
        self.clLocationManager.requestWhenInUseAuthorization()
    }

    private func requestAlwaysAuthorization() {
        self.clLocationManager.requestAlwaysAuthorization()
    }

    public func authorize(authorization: CLAuthorizationStatus) -> Future<Void> {
        let currentAuthorization = self.authorizationStatus()
        let promise = Promise<Void>()
        if currentAuthorization != authorization {
            self.authorizationStatusChangedPromise = Promise<CLAuthorizationStatus>()
            switch authorization {
            case .AuthorizedAlways:
                self.authorizationStatusChangedPromise?.future.onSuccess {(status) in
                    if status == .AuthorizedAlways {
                        FLLogger.debug("location AuthorizedAlways succcess")
                        promise.success()
                    } else {
                        FLLogger.debug("location AuthorizedAlways failed")
                        promise.failure(FLError.authorizationAlwaysFailed)
                    }
                }
                self.requestAlwaysAuthorization()
                break
            case .AuthorizedWhenInUse:
                self.authorizationStatusChangedPromise?.future.onSuccess {(status) in
                    if status == .AuthorizedWhenInUse {
                        FLLogger.debug("location AuthorizedWhenInUse succcess")
                        promise.success()
                    } else {
                        FLLogger.debug("location AuthorizedWhenInUse failed")
                        promise.failure(FLError.authorizationWhenInUseFailed)
                    }
                }
                self.requestWhenInUseAuthorization()
                break
            default:
                FLLogger.debug("location authorization invalid")
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
    public class func reverseGeocodeLocation(location: CLLocation) -> Future<[CLPlacemark]>  {
        let geocoder = CLGeocoder()
        let promise = Promise<[CLPlacemark]>()
        geocoder.reverseGeocodeLocation(location){ (placemarks:[CLPlacemark]?, error:NSError?) in
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
            return FLLocationManager.reverseGeocodeLocation(location)
        } else {
            let promise = Promise<[CLPlacemark]>()
            promise.failure(FLError.locationUpdateFailed)
            return promise.future
        }
    }

    // MARK: Location Updates
    public var location: CLLocation? {
        return self.clLocationManager.location
    }

    public func locationServicesEnabled() -> Bool {
        return CLLocationManager.locationServicesEnabled()
    }

    public func startUpdatingLocation(capacity: Int? = nil, authorization: CLAuthorizationStatus = .AuthorizedWhenInUse, context: ExecutionContext = QueueContext.main) -> FutureStream<[CLLocation]> {
            self.locationUpdatePromise = StreamPromise<[CLLocation]>(capacity:capacity)
            let authoriztaionFuture = self.authorize(authorization)
            authoriztaionFuture.onSuccess(context) {status in
                self.clLocationManager.startUpdatingLocation()
            }
            authoriztaionFuture.onFailure(context) {error in
                self.updateIsUpdating(false)
                self.locationUpdatePromise!.failure(error)
            }
            return self.locationUpdatePromise!.future
    }

    public func stopUpdatingLocation() {
        self.updateIsUpdating(false)
        self.locationUpdatePromise = nil
        self.clLocationManager.stopUpdatingLocation()
    }

    public func requestLocation(authorization: CLAuthorizationStatus = .AuthorizedAlways, context: ExecutionContext = QueueContext.main) -> Future<[CLLocation]> {
        self.requestLocationPromise = Promise<[CLLocation]>()
        guard #available(iOS 9.0, *) else {
            self.requestLocationPromise?.failure(FLError.notSupportedForIOSVersion)
            return self.requestLocationPromise!.future
        }
        guard let clLocationManager = self.clLocationManager as? CLLocationManager else {
            self.requestLocationPromise?.failure(FLError.notSupportedForIOSVersion)
            return self.requestLocationPromise!.future
        }
        self.requestLocationPromise = Promise<[CLLocation]>()
        let authoriztaionFuture = self.authorize(authorization)
        authoriztaionFuture.onSuccess(context) {status in
            clLocationManager.requestLocation()
        }
        authoriztaionFuture.onFailure(context) {error in
            self.updateIsUpdating(false)
            self.requestLocationPromise!.failure(error)
        }
        return self.requestLocationPromise!.future
    }

    // MARK: Significant Change in Location
    public class func significantLocationChangeMonitoringAvailable() -> Bool {
        return CLLocationManager.significantLocationChangeMonitoringAvailable()
    }

    public func startMonitoringSignificantLocationChanges(capacity: Int? = nil, authorization: CLAuthorizationStatus = .AuthorizedAlways, context: ExecutionContext = QueueContext.main) -> FutureStream<[CLLocation]> {
        self.locationUpdatePromise = StreamPromise<[CLLocation]>(capacity:capacity)
        let authoriztaionFuture = self.authorize(authorization)
        authoriztaionFuture.onSuccess(context) {status in
            self.clLocationManager.startMonitoringSignificantLocationChanges()
        }
        authoriztaionFuture.onFailure(context) {error in
            self.updateIsUpdating(false)
            self.locationUpdatePromise!.failure(error)
        }
        return self.locationUpdatePromise!.future
    }
    
    public func stopMonitoringSignificantLocationChanges() {
        self.updateIsUpdating(false)
        self.locationUpdatePromise  = nil
        self.clLocationManager.stopMonitoringSignificantLocationChanges()
    }

    // MARK: Deferred Location Updates
    public func deferredLocationUpdatesAvailable() -> Bool {
        return CLLocationManager.deferredLocationUpdatesAvailable()
    }

    public func allowDeferredLocationUpdatesUntilTraveled(distance: CLLocationDistance, timeout: NSTimeInterval) -> Future<Void> {
        self.deferredLocationUpdatePromise = Promise<Void>()
        self.clLocationManager.allowDeferredLocationUpdatesUntilTraveled(distance, timeout: timeout)
        return self.deferredLocationUpdatePromise!.future
    }

    // MARK: CLLocationManagerDelegate
    public func locationManager(manager: CLLocationManager, didUpdateLocations locations:[CLLocation]) {
        self.didUpdateLocations(locations)
    }

    public func locationManager(_: CLLocationManager, didFailWithError error: NSError) {
        self.didFailWithError(error)
    }

    public func locationManager(_: CLLocationManager, didFinishDeferredUpdatesWithError error: NSError?) {
        self.didFinishDeferredUpdatesWithError(error)
    }
        
    public func locationManager(_: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        self.didChangeAuthorizationStatus(status)
    }

    public func didUpdateLocations(locations:[CLLocation]) {
        FLLogger.debug()
        self.updateIsUpdating(true)
        if let requestLocationPromise = self.requestLocationPromise {
            requestLocationPromise.success(locations)
            self.requestLocationPromise = nil
        }
        self.locationUpdatePromise?.success(locations)
    }

    public func didFailWithError(error: NSError) {
        FLLogger.debug("error \(error.localizedDescription)")
        self.updateIsUpdating(false)
        if let requestLocationPromise = self.requestLocationPromise {
            requestLocationPromise.failure(error)
            self.requestLocationPromise = nil
        }
        self.locationUpdatePromise?.failure(error)
    }

    public func didFinishDeferredUpdatesWithError(error: NSError?) {
        if let error = error {
            self.deferredLocationUpdatePromise?.failure(error)
        } else {
            self.deferredLocationUpdatePromise?.success()
        }
    }

    public func didChangeAuthorizationStatus(status: CLAuthorizationStatus) {
        FLLogger.debug("status: \(status)")
        self.authorizationStatusChangedPromise?.success(status)
    }

    // MARK: Utilies
    func updateIsUpdating(value: Bool) {
        self.willChangeValueForKey("isUpdating")
        self.isUpdating = value
        self.didChangeValueForKey("isUpdating")
    }
}
