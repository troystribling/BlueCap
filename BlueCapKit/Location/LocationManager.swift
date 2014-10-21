//
//  LocationManager.swift
//  BlueCap
//
//  Created by Troy Stribling on 9/1/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation
import CoreLocation

public class LocationManager : NSObject,  CLLocationManagerDelegate {
    
    private var authorizationStatusChanged  : ((status:CLAuthorizationStatus) -> ())?

    internal var clLocationManager          : CLLocationManager!
    
    public var locationsUpdateSuccess       : ((locations:[CLLocation]) -> ())?
    public var locationsUpdateFailed        : ((error:NSError!) -> ())?
    public var pausedLocationUpdates        : (() -> ())?
    public var resumedLocationUpdates       : (() -> ())?
    
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
    
    public class func sharedInstance() -> LocationManager {
        if thisLocationManager == nil {
            thisLocationManager = LocationManager()
        }
        return thisLocationManager!
    }

    public class func authorizationStatus() -> CLAuthorizationStatus {
        return CLLocationManager.authorizationStatus()
    }
    
    public class func locationServicesEnabled() -> Bool {
        return CLLocationManager.locationServicesEnabled()
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
    public class func reverseGeocodeLocation(location:CLLocation, reverseGeocodeSuccess:(placemarks:[CLPlacemark]) -> (), reverseGeocodeFailed:((error:NSError!) -> ())? = nil)  {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location){(placemarks:[AnyObject]!, error:NSError!) in
            if error == nil {
                var places = Array<CLPlacemark>()
                if placemarks != nil {
                    places = placemarks.reduce(Array<CLPlacemark>()) {(result, place) in
                        if let place = place as? CLPlacemark {
                            return result + [place]
                        } else {
                            return result
                        }
                    }
                }
                reverseGeocodeSuccess(placemarks:places)
            } else {
                if let reverseGeocodeFailed = reverseGeocodeFailed {
                    reverseGeocodeFailed(error:error)
                }
            }
        }
    }
    
    public func reverseGeocodeLocation(reverseGeocodeSuccess:(placemarks:[CLPlacemark]) -> (), reverseGeocodeFailed:((error:NSError!) -> ())? = nil)  {
        if let location = self.location {
            RegionManager.reverseGeocodeLocation(self.location, reverseGeocodeSuccess, reverseGeocodeFailed)
        } else {
            if let reverseGeocodeFailed = reverseGeocodeFailed {
                reverseGeocodeFailed(error:NSError(domain:"BlueCap", code:408, userInfo:[NSLocalizedDescriptionKey:"location not available"]))
            }
        }
    }
    
    // control
    public func startUpdatingLocation(authorization:CLAuthorizationStatus, initializer:((manager:LocationManager) -> ())? = nil) {
        if let initializer = initializer {
            initializer(manager:self)
        }
        self.authorize(authorization){self.clLocationManager.startUpdatingLocation()}
    }
    
    public func startUpdatingLocation(initializer:((manager:LocationManager) -> ())? = nil) {
        self.startUpdatingLocation(CLAuthorizationStatus.Authorized, initializer:initializer)
    }
    
    public func stopUpdatingLocation() {
        self.locationsUpdateSuccess     = nil
        self.locationsUpdateFailed      = nil
        self.pausedLocationUpdates      = nil
        self.resumedLocationUpdates     = nil
        self.clLocationManager.stopUpdatingLocation()
    }
    
    // CLLocationManagerDelegate
    public func locationManager(_:CLLocationManager!, didUpdateLocations locations:[AnyObject]!) {
        if let locations = locations {
            Logger.debug("LocationManager#didUpdateLocations")
            if let locationsUpdateSuccess = self.locationsUpdateSuccess {
                let cllocations = locations.reduce([CLLocation]()) {(cllocations, location) in
                    if let location = location as? CLLocation {
                        return cllocations + [location]
                    } else {
                        return cllocations
                    }
                }
                locationsUpdateSuccess(locations:cllocations)
            }
        }
    }
    
    public func locationManager(_:CLLocationManager!, didFailWithError error:NSError!) {
        Logger.debug("LocationManager#didFailWithError: \(error.localizedDescription)")
        if let locationsUpdateFalied = self.locationsUpdateFailed {
            locationsUpdateFalied(error:error)
        }
    }
    
    public func locationManager(_:CLLocationManager!, didFinishDeferredUpdatesWithError error:NSError!) {
    }
    
    public func locationManagerDidPauseLocationUpdates(_:CLLocationManager!) {
        Logger.debug("LocationManager#locationManagerDidPauseLocationUpdates")
        if let pausedLocationUpdates = self.pausedLocationUpdates {
            pausedLocationUpdates()
        }
    }
    
    public func locationManagerDidResumeLocationUpdates(_:CLLocationManager!) {
        Logger.debug("LocationManager#locationManagerDidResumeLocationUpdates")
        if let resumedLocationUpdates = self.resumedLocationUpdates {
            resumedLocationUpdates()
        }
    }
    
    public func locationManager(_:CLLocationManager!, didChangeAuthorizationStatus status:CLAuthorizationStatus) {
        Logger.debug("LocationManager#didChangeAuthorizationStatus: \(status)")
        if let authorizationStatusChanged = self.authorizationStatusChanged {
            authorizationStatusChanged(status:status)
        }
    }
    
    internal func authorize(authorization:CLAuthorizationStatus, andExecute:() -> ()) {
        if LocationManager.authorizationStatus() != authorization {
            switch authorization {
            case .Authorized:
                self.authorizationStatusChanged = {(status) in
                    if status == .Authorized {
                        Logger.debug("LocationManager#authorize: Location Authorized succcess")
                        andExecute()
                    } else {
                        Logger.debug("LocationManager#authorize: Location Authorized failed")
                        if let locationsUpdateFailed = self.locationsUpdateFailed {
                            locationsUpdateFailed(error:NSError(domain:"BlueCap", code:408, userInfo:[NSLocalizedDescriptionKey:"Authorization failed"]))
                        }
                    }
                }
                LocationManager.sharedInstance().requestAlwaysAuthorization()
                break
            case .AuthorizedWhenInUse:
                self.authorizationStatusChanged = {(status) in
                    if status == .AuthorizedWhenInUse {
                        Logger.debug("LocationManager#authorize: Location AuthorizedWhenInUse success")
                        andExecute()
                    } else {
                        Logger.debug("LocationManager#authorize: Location AuthorizedWhenInUse failed")
                    }
                }
                LocationManager.sharedInstance().requestWhenInUseAuthorization()
                break
            default:
                break
            }
        } else {
            andExecute()
        }
        
    }
}

var thisLocationManager : LocationManager?
