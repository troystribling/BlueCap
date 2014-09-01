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
    
    internal var clLocationManager           : CLLocationManager!
    
    public var locationsUpdateSuccess      : ((locations:[CLLocation]) -> ())?
    public var locationsUpdateFailed       : ((error:NSError!) -> ())?
    public var pausedLocationUpdates       : (() -> ())?
    public var resumedLocationUpdates      : (() -> ())?
    public var authorizationStatusChanged  : (() -> ())?
    
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
    
    public override init() {
        super.init()
        self.clLocationManager = CLLocationManager()
        self.clLocationManager.delegate = self
    }
    
    public class func authorizationStatus() -> CLAuthorizationStatus {
        return CLLocationManager.authorizationStatus()
    }
    
    public class func locationServicesEnabled() -> Bool {
        return CLLocationManager.locationServicesEnabled()
    }
    
    // reverse geocode
    public class func reverseGeocodeLocation(location:CLLocation, reverseGeocodeSuccess:(placemarks:[CLPlacemark]) -> (), reverseGeocodeFailed:((error:NSError!) -> ())?)  {
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
    
    public func reverseGeocodeLocation(reverseGeocodeSuccess:(placemarks:[CLPlacemark]) -> (), reverseGeocodeFailed:((error:NSError!) -> ())?)  {
        if let location = self.location {
            RegionManager.reverseGeocodeLocation(self.location, reverseGeocodeSuccess, reverseGeocodeFailed)
        } else {
            if let reverseGeocodeFailed = reverseGeocodeFailed {
                reverseGeocodeFailed(error:NSError.errorWithDomain("BlueCap", code:408, userInfo:[NSLocalizedDescriptionKey:"location not available"]))
            }
        }
    }
    
    // control
    public func startUpdatingLocation(initializer:((manager:LocationManager) -> ())? = nil) {
        if let initializer = initializer {
            initializer(manager:self)
        }
        self.clLocationManager.startUpdatingLocation()
    }
    
    public func stopUpdatingLocation() {
        self.clLocationManager.stopUpdatingLocation()
    }
    
    // CLLocationManagerDelegate
    public func locationManager(_:CLLocationManager!, didUpdateLocations locations:[AnyObject]!) {
        if let locationsUpdateSuccess = self.locationsUpdateSuccess {
            if let locations = locations {
                Logger.debug("RegionManager#didUpdateLocations")
                let cllocations = locations.reduce(Array<CLLocation>()) {(result, location) in
                    if let location = location as? CLLocation {
                        return result + [location]
                    } else {
                        return result
                    }
                }
                locationsUpdateSuccess(locations:cllocations)
            }
        }
    }
    
    public func locationManager(_:CLLocationManager!, didFailWithError error:NSError!) {
        if let locationsUpdateFalied = self.locationsUpdateFailed {
            Logger.debug("RegionManager#didFailWithError: \(error.localizedDescription)")
            locationsUpdateFalied(error:error)
        }
    }
    
    public func locationManager(_:CLLocationManager!, didFinishDeferredUpdatesWithError error:NSError!) {
    }
    
    public func locationManagerDidPauseLocationUpdates(_:CLLocationManager!) {
        if let pausedLocationUpdates = self.pausedLocationUpdates {
            Logger.debug("RegionManager#locationManagerDidPauseLocationUpdates")
            pausedLocationUpdates()
        }
    }
    
    public func locationManagerDidResumeLocationUpdates(_:CLLocationManager!) {
        if let resumedLocationUpdates = self.resumedLocationUpdates {
            Logger.debug("RegionManager#locationManagerDidResumeLocationUpdates")
            resumedLocationUpdates()
        }
    }
    
    public func locationManager(_:CLLocationManager!, didChangeAuthorizationStatus status:CLAuthorizationStatus) {
        if let authorizationStatusChanged = self.authorizationStatusChanged {
            Logger.debug("RegionManager#didChangeAuthorizationStatus")
            authorizationStatusChanged()
        }
    }
}

var thisLocationManager : LocationManager?
