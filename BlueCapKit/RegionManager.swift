//
//  LocationRegionManager.swift
//  BlueCap
//
//  Created by Troy Stribling on 8/22/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation
import CoreLocation

public class RegionManager : NSObject,  CLLocationManagerDelegate {

    private var clLocationManager           : CLLocationManager!
    private var configuredRegionMonitors    : Dictionary<CLRegion, RegionMonitor> = [:]
    
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
    
    public var regions : [CLRegion] {
        return Array(self.configuredRegionMonitors.keys)
    }
    
    public var regionMonitors : [RegionMonitor] {
        return Array(self.configuredRegionMonitors.values)
    }
    
    public var maximumRegionMonitoringDistance : CLLocationDistance {
        return self.clLocationManager.maximumRegionMonitoringDistance
    }
    
    public class func sharedInstance() -> RegionManager {
        if thisRegionManager == nil {
            thisRegionManager = RegionManager()
        }
        return thisRegionManager!
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
    public func reverseGeocodeLocation(location:CLLocation, reverseGeocodeSuccess:(placemarks:[CLPlacemark]) -> (), reverseGeocodeFailed:((error:NSError!) -> ())?)  {
    }
    
    // control
    public func startUpdatingLocation(initializer:((manager:RegionManager) -> ())? = nil) {
        if let initializer = initializer {
            initializer(manager:self)
        }
        self.clLocationManager.startUpdatingLocation()
    }
    
    public func stopUpdatingLocation() {
        self.clLocationManager.stopUpdatingLocation()
    }
    
    public func startMonitoringForRegion(regionMonitor:RegionMonitor) {
        self.configuredRegionMonitors[regionMonitor.region] = regionMonitor
        self.clLocationManager.startMonitoringForRegion(regionMonitor.region)
    }

    public func stopMonitoringForRegion(regionMonitor:RegionMonitor) {
        self.configuredRegionMonitors.removeValueForKey(regionMonitor.region)
        self.clLocationManager.stopMonitoringForRegion(regionMonitor.region)
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

    // regions
    public func locationManager(_:CLLocationManager!, didEnterRegion region:CLRegion!) {
        if let regionMonitor = self.configuredRegionMonitors[region] {
            if let enterRegion = regionMonitor.enterRegion {
                Logger.debug("RegionManager#didEnterRegion")
                enterRegion()
            }
        }
    }
    
    public func locationManager(_:CLLocationManager!, didExitRegion region:CLRegion!) {
        if let regionMonitor = self.configuredRegionMonitors[region] {
            if let exitRegion = regionMonitor.exitRegion {
                Logger.debug("RegionManager#didExitRegion")
                exitRegion()
            }
        }
    }
    
    public func locationManager(_:CLLocationManager!, didDetermineState state:CLRegionState, forRegion region:CLRegion!) {
        if let regionMonitor = self.configuredRegionMonitors[region] {
            if let regionStateChanged = regionMonitor.regionStateChanged {
                Logger.debug("RegionManager#didDetermineState")
                regionStateChanged(state:state)
            }
        }
    }
    
    public func locationManager(_:CLLocationManager!, monitoringDidFailForRegion region:CLRegion!, withError error:NSError!) {
        if let regionMonitor = self.configuredRegionMonitors[region] {
            if let errorMonitoringRegion = regionMonitor.errorMonitoringRegion {
                errorMonitoringRegion(error:error)
            }
        }
    }
    
    public func locationManager(_:CLLocationManager!, didStartMonitoringForRegion region:CLRegion!) {
        if let regionMonitor = self.configuredRegionMonitors[region] {
            if let startMonitoringRegion = regionMonitor.startMonitoringRegion {
                Logger.debug("RegionManager#didStartMonitoringForRegion")
                startMonitoringRegion()
            }
        }
    }
}

var thisRegionManager : RegionManager?
