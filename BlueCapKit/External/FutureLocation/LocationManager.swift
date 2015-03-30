//
//  LocationManager.swift
//  BlueCap
//
//  Created by Troy Stribling on 9/1/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
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
    func startUpdatingLocation()
    func stopUpdatingLocation()
    
}

public protocol CLLocationWrappable {
}

extension CLLocation : CLLocationWrappable {
}

public class LocationManagerImpl<Wrapper where Wrapper:LocationManagerWrappable,
                                               Wrapper.WrappedCLLocation:CLLocationWrappable> {
    
    private var locationUpdatePromise               : StreamPromise<[Wrapper.WrappedCLLocation]>?
    private var authorizationStatusChangedPromise   = Promise<CLAuthorizationStatus>()
    
    
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
            locationManager.startUpdatingLocation()
        }
        authoriztaionFuture.onFailure {error in
            self.locationUpdatePromise!.failure(error)
        }
        return self.locationUpdatePromise!.future
    }
    
    public func stopUpdatingLocation(locationManager:Wrapper) {
        self.locationUpdatePromise  = nil
        locationManager.stopUpdatingLocation()
    }
    
    // CLLocationManagerDelegate
    public func didUpdateLocations(locations:[Wrapper.WrappedCLLocation]) {
        Logger.debug("LocationManagerImpl#didUpdateLocations")
        if let locationUpdatePromise = self.locationUpdatePromise {
            locationUpdatePromise.success(locations)
        }
    }
    
    public func didFailWithError(error:NSError!) {
        Logger.debug("LocationManagerImpl#didFailWithError: \(error.localizedDescription)")
        if let locationUpdatePromise = self.locationUpdatePromise {
            locationUpdatePromise.failure(error)
        }
    }
    
    public func didChangeAuthorizationStatus(status:CLAuthorizationStatus) {
        Logger.debug("LocationManagerImpl#didChangeAuthorizationStatus: \(status)")
        self.authorizationStatusChangedPromise.success(status)
        self.authorizationStatusChangedPromise = Promise<CLAuthorizationStatus>()
    }
    
    public func authorize(locationManager:Wrapper, currentAuthorization:CLAuthorizationStatus, requestedAuthorization:CLAuthorizationStatus) -> Future<Void> {
        let promise = Promise<Void>()
        if currentAuthorization != requestedAuthorization {
            switch requestedAuthorization {
            case .AuthorizedAlways:
                self.authorizationStatusChangedPromise.future.onSuccess {(status) in
                    if status == .AuthorizedAlways {
                        Logger.debug("LocationManager#authorize: Location Authorized succcess")
                        promise.success()
                    } else {
                        Logger.debug("LocationManager#authorize: Location Authorized failed")
                        promise.failure(FLError.authoizationAlwaysFailed)
                    }
                }
                locationManager.requestAlwaysAuthorization()
                break
            case .AuthorizedWhenInUse:
                self.authorizationStatusChangedPromise.future.onSuccess {(status) in
                    if status == .AuthorizedWhenInUse {
                        Logger.debug("LocationManager#authorize: Location AuthorizedWhenInUse success")
                        promise.success()
                    } else {
                        Logger.debug("LocationManager#authorize: Location AuthorizedWhenInUse failed")
                        promise.failure(FLError.authoizationWhenInUseFailed)
                    }
                }
                locationManager.requestWhenInUseAuthorization()
                break
            default:
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

struct FLError {
    static let domain = "FutureLocation"
    static let locationUpdateFailed = NSError(domain:domain, code:LocationError.UpdateFailed.rawValue, userInfo:[NSLocalizedDescriptionKey:"Location not available"])
    static let locationNotAvailable = NSError(domain:domain, code:LocationError.NotAvailable.rawValue, userInfo:[NSLocalizedDescriptionKey:"Location update failed"])
    static let authoizationAlwaysFailed = NSError(domain:domain, code:LocationError.AuthorizationAlwaysFailed.rawValue, userInfo:[NSLocalizedDescriptionKey:"Authorization failed"])
    static let authoizationWhenInUseFailed = NSError(domain:domain, code:LocationError.AuthorisedWhenInUseFailed.rawValue, userInfo:[NSLocalizedDescriptionKey:"Authorization when in use failed"])
}

public class LocationManager : NSObject,  CLLocationManagerDelegate, LocationManagerWrappable {
    
    let impl = LocationManagerImpl<LocationManager>()

    // LocationManagerImpl

    public var location : CLLocation! {
        return self.clLocationManager.location
    }
    
    
    public class func authorizationStatus() -> CLAuthorizationStatus {
        return CLLocationManager.authorizationStatus()
    }
    
    public class func locationServicesEnabled() -> Bool {
        return CLLocationManager.locationServicesEnabled()
    }
    
    public func requestWhenInUseAuthorization() {
        self.clLocationManager.requestWhenInUseAuthorization()
    }
    
    public func requestAlwaysAuthorization() {
        self.clLocationManager.requestAlwaysAuthorization()
    }
    
    
    public func startUpdatingLocation() {
        self.clLocationManager.startUpdatingLocation()
    }
    
    public func stopUpdatingLocation() {
        self.clLocationManager.stopUpdatingLocation()
    }

    // LocationManagerImpl

    internal var clLocationManager                  : CLLocationManager!
    
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
        return self.impl.startUpdatingLocation(self, currentAuthorization:LocationManager.authorizationStatus(), requestedAuthorization:authorization, capacity:nil)
    }

    public func startUpdatingLocation(capacity:Int, authorization:CLAuthorizationStatus = .AuthorizedAlways) -> FutureStream<[CLLocation]> {
        return self.impl.startUpdatingLocation(self, currentAuthorization:LocationManager.authorizationStatus(), requestedAuthorization:authorization, capacity:capacity)
    }
    
    // CLLocationManagerDelegate
    public func locationManager(_:CLLocationManager!, didUpdateLocations locations:[AnyObject]!) {
        if let locations = locations {
            let cllocations = locations.map{$0 as! CLLocation}
            self.impl.didUpdateLocations(cllocations)
        }
    }
    
    public func locationManager(_:CLLocationManager!, didFailWithError error:NSError!) {
        self.impl.didFailWithError(error)
    }
    
    public func locationManager(_:CLLocationManager!, didFinishDeferredUpdatesWithError error:NSError!) {
    }
        
    public func locationManager(_:CLLocationManager!, didChangeAuthorizationStatus status:CLAuthorizationStatus) {
        self.impl.didChangeAuthorizationStatus(status)
    }
    
    public func authorize(authorization:CLAuthorizationStatus) -> Future<Void> {
        return self.impl.authorize(self, currentAuthorization:LocationManager.authorizationStatus(), requestedAuthorization:authorization)
    }
}
