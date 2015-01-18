//
//  LocationManager.swift
//  BlueCap
//
//  Created by Troy Stribling on 9/1/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation
import CoreLocation

enum LocationError : Int {
    case NotAvailable               = 30
    case UpdateFailed               = 31
    case AuthorizationFailed        = 32
    case AuthorisedWhenInUseFailed  = 33
}

struct FLError {
    static let domain = "FutureLocation"
    static let locationUpdateFailed = NSError(domain:domain, code:LocationError.UpdateFailed.rawValue, userInfo:[NSLocalizedDescriptionKey:"Location not available"])
    static let locationNotAvailable = NSError(domain:domain, code:LocationError.NotAvailable.rawValue, userInfo:[NSLocalizedDescriptionKey:"Location update failed"])
    static let authoizationFailed = NSError(domain:domain, code:LocationError.AuthorizationFailed.rawValue, userInfo:[NSLocalizedDescriptionKey:"Authorization failed"])
    static let authoizationWhenInUseFailed = NSError(domain:domain, code:LocationError.AuthorizationFailed.rawValue, userInfo:[NSLocalizedDescriptionKey:"Authorization when in use failed"])
}

public class LocationManager : NSObject,  CLLocationManagerDelegate {
    
    internal var clLocationManager                  : CLLocationManager!
    
    private var locationUpdatePromise               : StreamPromise<[CLLocation]>?
    private var authorizationStatusChangedPromise   = Promise<CLAuthorizationStatus>()
    
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
    
    public var location : CLLocation! {
        return self.clLocationManager.location
    }
    

    public class func authorizationStatus() -> CLAuthorizationStatus {
        return CLLocationManager.authorizationStatus()
    }
    
    public class func locationServicesEnabled() -> Bool {
        return CLLocationManager.locationServicesEnabled()
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
                    places = placemarks.reduce(Array<CLPlacemark>()) {(result, place) in
                        if let place = place as? CLPlacemark {
                            return result + [place]
                        } else {
                            return result
                        }
                    }
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
        self.clLocationManager.requestAlwaysAuthorization()
    }
    
    public func requestWhenInUseAuthorization() {
        self.clLocationManager.requestWhenInUseAuthorization()
    }
    
    public func requestAlwaysAuthorization() {
        self.clLocationManager.requestAlwaysAuthorization()
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
    public func startUpdatingLocation(authorization:CLAuthorizationStatus = .Authorized) -> FutureStream<[CLLocation]> {
        self.locationUpdatePromise = StreamPromise<[CLLocation]>()
        let authoriztaionFuture = self.authorize(authorization)
        authoriztaionFuture.onSuccess {status in
            self.clLocationManager.startUpdatingLocation()
        }
        authoriztaionFuture.onFailure {error in
            self.locationUpdatePromise!.failure(error)
        }
        return self.locationUpdatePromise!.future
    }

    public func startUpdatingLocation(capacity:Int, authorization:CLAuthorizationStatus = .Authorized) -> FutureStream<[CLLocation]> {
        self.locationUpdatePromise = StreamPromise<[CLLocation]>(capacity:capacity)
        let authoriztaionFuture = self.authorize(authorization)
        authoriztaionFuture.onSuccess {status in
            self.clLocationManager.startUpdatingLocation()
        }
        authoriztaionFuture.onFailure {error in
            self.locationUpdatePromise!.failure(error)
        }
        return self.locationUpdatePromise!.future
    }
        
    public func stopUpdatingLocation() {
        self.locationUpdatePromise  = nil
        self.clLocationManager.stopUpdatingLocation()
    }
    
    // CLLocationManagerDelegate
    public func locationManager(_:CLLocationManager!, didUpdateLocations locations:[AnyObject]!) {
        if let locations = locations {
            Logger.debug("LocationManager#didUpdateLocations")
            if let locationUpdatePromise = self.locationUpdatePromise {
                let cllocations = locations.reduce([CLLocation]()) {(cllocations, location) in
                    if let location = location as? CLLocation {
                        return cllocations + [location]
                    } else {
                        return cllocations
                    }
                }
                locationUpdatePromise.success(cllocations)
            }
        }
    }
    
    public func locationManager(_:CLLocationManager!, didFailWithError error:NSError!) {
        Logger.debug("LocationManager#didFailWithError: \(error.localizedDescription)")
        if let locationUpdatePromise = self.locationUpdatePromise {
            locationUpdatePromise.failure(error)
        }
    }
    
    public func locationManager(_:CLLocationManager!, didFinishDeferredUpdatesWithError error:NSError!) {
    }
        
    public func locationManager(_:CLLocationManager!, didChangeAuthorizationStatus status:CLAuthorizationStatus) {
        Logger.debug("LocationManager#didChangeAuthorizationStatus: \(status)")
        self.authorizationStatusChangedPromise.success(status)
    }
    
    internal func authorize(authorization:CLAuthorizationStatus) -> Future<Void> {
        let promise = Promise<Void>()
        if LocationManager.authorizationStatus() != authorization {
            self.authorizationStatusChangedPromise = Promise<CLAuthorizationStatus>()
            switch authorization {
            case .Authorized:
                self.authorizationStatusChangedPromise.future.onSuccess {(status) in
                    if status == .Authorized {
                        Logger.debug("LocationManager#authorize: Location Authorized succcess")
                        promise.success()
                    } else {
                        Logger.debug("LocationManager#authorize: Location Authorized failed")
                        promise.failure(FLError.authoizationFailed)
                    }
                }
                self.requestAlwaysAuthorization()
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
                self.requestWhenInUseAuthorization()
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
