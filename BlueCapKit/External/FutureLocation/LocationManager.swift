//
//  LocationManager.swift
//  BlueCap
//
//  Created by Troy Stribling on 9/1/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import Foundation
import CoreLocation

/////////////////////////////////////////////
// LocationManagerImpl
public protocol LocationManagerWrappable {
    
    typealias WrappedCLLocation
    
    var location : WrappedCLLocation! {get}
    
    func requestWhenInUseAuthorization()
    func requestAlwaysAuthorization()
    func wrappedStartUpdatingLocation()
    func wrappedStartMonitoringSignificantLocationChanges()
    
}

public protocol CLLocationWrappable {
}

extension CLLocation : CLLocationWrappable {
}

public class LocationManagerImpl<Wrapper where Wrapper:LocationManagerWrappable,
                                               Wrapper.WrappedCLLocation:CLLocationWrappable> {
    
    private var locationUpdatePromise               : StreamPromise<[Wrapper.WrappedCLLocation]>?
    private var authorizationStatusChangedPromise   : Promise<CLAuthorizationStatus>?
    private var _isUpdating                         = false
    
    public var isUpdating : Bool {
        return self._isUpdating
    }
    
    public init() {
    }
    
    // control
    public func startUpdatingLocation(locationManager:Wrapper, currentAuthorization:CLAuthorizationStatus, requestedAuthorization:CLAuthorizationStatus, capacity:Int? = nil) -> FutureStream<[Wrapper.WrappedCLLocation]> {
        if let capacity = capacity {
            self.locationUpdatePromise = StreamPromise<[Wrapper.WrappedCLLocation]>(capacity:capacity)
        } else {
            self.locationUpdatePromise = StreamPromise<[Wrapper.WrappedCLLocation]>()
        }
        let authoriztaionFuture = self.authorize(locationManager, currentAuthorization:currentAuthorization, requestedAuthorization:requestedAuthorization)
        authoriztaionFuture.onSuccess {status in
            self._isUpdating = true
            locationManager.wrappedStartUpdatingLocation()
        }
        authoriztaionFuture.onFailure {error in
            self._isUpdating = false
            self.locationUpdatePromise!.failure(error)
        }
        return self.locationUpdatePromise!.future
    }
    
    public func startMonitoringSignificantLocationChanges(locationManager:Wrapper, currentAuthorization:CLAuthorizationStatus, requestedAuthorization:CLAuthorizationStatus, capacity:Int? = nil) -> FutureStream<[Wrapper.WrappedCLLocation]> {
        if let capacity = capacity {
            self.locationUpdatePromise = StreamPromise<[Wrapper.WrappedCLLocation]>(capacity:capacity)
        } else {
            self.locationUpdatePromise = StreamPromise<[Wrapper.WrappedCLLocation]>()
        }
        let authoriztaionFuture = self.authorize(locationManager, currentAuthorization:currentAuthorization, requestedAuthorization:requestedAuthorization)
        authoriztaionFuture.onSuccess {status in
            self._isUpdating = true
            locationManager.wrappedStartMonitoringSignificantLocationChanges()
        }
        authoriztaionFuture.onFailure {error in
            self._isUpdating = false
            self.locationUpdatePromise!.failure(error)
        }
        return self.locationUpdatePromise!.future
    }

    public func stopUpdatingLocation() {
        self._isUpdating = false
        self.locationUpdatePromise  = nil
    }

    public func stopMonitoringSignificantLocationChanges() {
        self._isUpdating = false
        self.locationUpdatePromise  = nil
    }

    // CLLocationManagerDelegate
    public func didUpdateLocations(locations:[Wrapper.WrappedCLLocation]) {
        Logger.debug()
        if let locationUpdatePromise = self.locationUpdatePromise {
            locationUpdatePromise.success(locations)
        }
    }
    
    public func didFailWithError(error:NSError!) {
        Logger.debug(message:"error \(error.localizedDescription)")
        if let locationUpdatePromise = self.locationUpdatePromise {
            locationUpdatePromise.failure(error)
        }
    }
    
    public func didChangeAuthorizationStatus(status:CLAuthorizationStatus) {
        Logger.debug(message:"status: \(status)")
        self.authorizationStatusChangedPromise?.success(status)
        self.authorizationStatusChangedPromise = nil
    }
    
    public func authorize(locationManager:Wrapper, currentAuthorization:CLAuthorizationStatus, requestedAuthorization:CLAuthorizationStatus) -> Future<Void> {
        let promise = Promise<Void>()
        if currentAuthorization != requestedAuthorization {
            self.authorizationStatusChangedPromise = Promise<CLAuthorizationStatus>()
            switch requestedAuthorization {
            case .AuthorizedAlways:
                self.authorizationStatusChangedPromise?.future.onSuccess {(status) in
                    if status == .AuthorizedAlways {
                        Logger.debug(message:"location AuthorizedAlways succcess")
                        promise.success()
                    } else {
                        Logger.debug(message:"location AuthorizedAlways failed")
                        promise.failure(FLError.authoizationAlwaysFailed)
                    }
                }
                locationManager.requestAlwaysAuthorization()
                break
            case .AuthorizedWhenInUse:
                self.authorizationStatusChangedPromise?.future.onSuccess {(status) in
                    if status == .AuthorizedWhenInUse {
                        Logger.debug(message:"location AuthorizedWhenInUse succcess")
                        promise.success()
                    } else {
                        Logger.debug(message:"location AuthorizedWhenInUse failed")
                        promise.failure(FLError.authoizationWhenInUseFailed)
                    }
                }
                locationManager.requestWhenInUseAuthorization()
                break
            default:
                Logger.debug(message:"location authorization invalid")
                break
            }
        } else {
            promise.success()
        }
        return promise.future
    }
}
// LocationManagerImpl
/////////////////////////////////////////////

public enum LocationError : Int {
    case NotAvailable               = 0
    case UpdateFailed               = 1
    case AuthorizationAlwaysFailed  = 2
    case AuthorisedWhenInUseFailed  = 3
}

public struct FLError {
    public static let domain = "FutureLocation"
    public static let locationUpdateFailed = NSError(domain:domain, code:LocationError.UpdateFailed.rawValue, userInfo:[NSLocalizedDescriptionKey:"Location not available"])
    public static let locationNotAvailable = NSError(domain:domain, code:LocationError.NotAvailable.rawValue, userInfo:[NSLocalizedDescriptionKey:"Location update failed"])
    public static let authoizationAlwaysFailed = NSError(domain:domain, code:LocationError.AuthorizationAlwaysFailed.rawValue, userInfo:[NSLocalizedDescriptionKey:"Authorization failed"])
    public static let authoizationWhenInUseFailed = NSError(domain:domain, code:LocationError.AuthorisedWhenInUseFailed.rawValue, userInfo:[NSLocalizedDescriptionKey:"Authorization when in use failed"])
}

public class LocationManager : NSObject,  CLLocationManagerDelegate, LocationManagerWrappable {
    
    public let locationImpl = LocationManagerImpl<LocationManager>()

    // LocationManagerImpl

    public var isUpdating : Bool {
        return self.locationImpl.isUpdating
    }

    public var location : CLLocation! {
        return self.clLocationManager.location
    }
    
    public class func authorizationStatus() -> CLAuthorizationStatus {
        return CLLocationManager.authorizationStatus()
    }
    
    public class func locationServicesEnabled() -> Bool {
        return CLLocationManager.locationServicesEnabled()
    }
    
    public class func significantLocationChangeMonitoringAvailable() -> Bool {
        return CLLocationManager.significantLocationChangeMonitoringAvailable()
    }

    public class func deferredLocationUpdatesAvailable() -> Bool {
        return CLLocationManager.deferredLocationUpdatesAvailable()
    }

    public class func headingAvailable() -> Bool {
        return CLLocationManager.deferredLocationUpdatesAvailable()
    }
    
    public func requestWhenInUseAuthorization() {
        self.clLocationManager.requestWhenInUseAuthorization()
    }
    
    public func requestAlwaysAuthorization() {
        self.clLocationManager.requestAlwaysAuthorization()
    }
    
    
    public func wrappedStartUpdatingLocation() {
        self.clLocationManager.startUpdatingLocation()
    }
    
    public func wrappedStopUpdatingLocation() {
        self.clLocationManager.stopUpdatingLocation()
    }
    
    public func wrappedStartMonitoringSignificantLocationChanges() {
        self.clLocationManager.startMonitoringSignificantLocationChanges()
    }
    
    public func wrappedStopMonitoringSignificantLocationChanges() {
        self.clLocationManager.stopMonitoringSignificantLocationChanges()
    }

    // LocationManagerImpl

    internal var clLocationManager : CLLocationManager!
    
    public var distanceFilter : CLLocationDistance {
        get {
            return self.clLocationManager.distanceFilter
        }
        set {
            self.clLocationManager.distanceFilter = newValue
        }
    }
    
    public var desiredAccuracy : CLLocationAccuracy {
        get {
            return self.clLocationManager.desiredAccuracy
        }
        set {
            self.clLocationManager.desiredAccuracy = newValue
        }
    }
    
    public class func reverseGeocodeLocation(location:CLLocation) -> Future<[CLPlacemark]>  {
        let geocoder = CLGeocoder()
        let promise = Promise<[CLPlacemark]>()
        geocoder.reverseGeocodeLocation(location){(placemarks:[AnyObject]!, error:NSError!) in
            if let error = error {
                promise.failure(error)
            } else {
                var places = [CLPlacemark]()
                if placemarks != nil {
                    places = placemarks.map {$0 as! CLPlacemark}
                }
                promise.success(places)
            }
        }
        return promise.future
    }
    
    public override init() {
        super.init()
        self.clLocationManager = CLLocationManager()
        self.clLocationManager.delegate = self
    }
    
    // reverse geocode
    public func reverseGeocodeLocation()  -> Future<[CLPlacemark]>  {
        if let location = self.location {
            return LocationManager.reverseGeocodeLocation(self.location)
        } else {
            let promise = Promise<[CLPlacemark]>()
            promise.failure(FLError.locationUpdateFailed)
            return promise.future
        }
    }
    
    // control
    public func startUpdatingLocation(authorization:CLAuthorizationStatus = .AuthorizedAlways) -> FutureStream<[CLLocation]> {
        return self.locationImpl.startUpdatingLocation(self, currentAuthorization:LocationManager.authorizationStatus(), requestedAuthorization:authorization, capacity:nil)
    }

    public func startUpdatingLocation(capacity:Int, authorization:CLAuthorizationStatus = .AuthorizedAlways) -> FutureStream<[CLLocation]> {
        return self.locationImpl.startUpdatingLocation(self, currentAuthorization:LocationManager.authorizationStatus(), requestedAuthorization:authorization, capacity:capacity)
    }

    public func stopUpdatingLocation() {
        self.locationImpl.stopUpdatingLocation()
        self.clLocationManager.stopUpdatingLocation()
    }
    
    public func startMonitoringSignificantLocationChanges(authorization:CLAuthorizationStatus = .AuthorizedAlways) -> FutureStream<[CLLocation]> {
        return self.locationImpl.startUpdatingLocation(self, currentAuthorization:LocationManager.authorizationStatus(), requestedAuthorization:authorization, capacity:nil)
    }
    
    public func startMonitoringSignificantLocationChanges(capacity:Int, authorization:CLAuthorizationStatus = .AuthorizedAlways) -> FutureStream<[CLLocation]> {
        return self.locationImpl.startUpdatingLocation(self, currentAuthorization:LocationManager.authorizationStatus(), requestedAuthorization:authorization, capacity:capacity)
    }
    
    public func stopMonitoringSignificantLocationChanges() {
        self.locationImpl.stopMonitoringSignificantLocationChanges()
        self.clLocationManager.stopMonitoringSignificantLocationChanges()
    }
    
    // CLLocationManagerDelegate
    public func locationManager(_:CLLocationManager!, didUpdateLocations locations:[AnyObject]!) {
        if let locations = locations {
            let cllocations = locations.map{$0 as! CLLocation}
            self.locationImpl.didUpdateLocations(cllocations)
        }
    }
    
    public func locationManager(_:CLLocationManager!, didFailWithError error:NSError!) {
        self.locationImpl.didFailWithError(error)
    }
    
    public func locationManager(_:CLLocationManager!, didFinishDeferredUpdatesWithError error:NSError!) {
    }
        
    public func locationManager(_:CLLocationManager!, didChangeAuthorizationStatus status:CLAuthorizationStatus) {
        self.locationImpl.didChangeAuthorizationStatus(status)
    }
    
    public func authorize(authorization:CLAuthorizationStatus) -> Future<Void> {
        return self.locationImpl.authorize(self, currentAuthorization:LocationManager.authorizationStatus(), requestedAuthorization:authorization)
    }
}
