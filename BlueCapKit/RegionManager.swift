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

    private var clLocationManager               : CLLocationManager!
    private var locationsUpdateSuccessCallback  : ((locations:[AnyObject]!) -> ())?
    private var locationsUpdateFailedCallback   : ((error:NSError!) -> ())?
    private var pausedLocationUpdatesCallback   : (() -> ())?
    private var resumedLocationUpdatesCallback  : (() -> ())?
    private var enterRegionCallbacks            : Dictionary<CLRegion, ()->()> = [:]
    private var exitRegionCallbacks             : Dictionary<CLRegion, ()->()> = [:]
    
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
    
    public var monitoredRegions : [CLRegion] {
        return Array(self.enterRegionCallbacks.keys)
    }
    
    public var maximumRegionMonitoringDistance : CLLocationDistance {
        return self.clLocationManager.maximumRegionMonitoringDistance
    }
    
    public init(initializer:(manager:RegionManager) -> ()) {
        super.init()
        self.clLocationManager = CLLocationManager()
        self.clLocationManager.delegate = self
        initializer(manager:self)
    }
    
    public class func authorizationStatus() -> CLAuthorizationStatus {
        return CLLocationManager.authorizationStatus()
    }
    
    public class func locationServicesEnabled() -> Bool {
        return CLLocationManager.locationServicesEnabled()
    }
    
    // callbacks
    public func onlocationsUpdateSuccess(locationsUpdateSuccess:(locations:[AnyObject]!) -> ()) {
        self.locationsUpdateSuccessCallback = locationsUpdateSuccess
    }
    
    public func onlocationsUpdateFailed(locationsUpdateFailed:(error:NSError!) -> ()) {
        self.locationsUpdateFailedCallback = locationsUpdateFailed
    }

    public func onPausedLocationUpdates(pausedLocationUpdates:() -> ()) {
        self.pausedLocationUpdatesCallback = pausedLocationUpdates
    }

    public func onResumedLocationUpdates(resumedLocationUpdates:() -> ()) {
        self.resumedLocationUpdatesCallback = resumedLocationUpdates
    }

    // control
    public func startUpdatingLocation() {
        self.clLocationManager.startUpdatingLocation()
    }
    
    public func stopUpdatingLocation() {
        self.clLocationManager.stopUpdatingLocation()
    }
    
    public func startMonitoringForRegion(region:CLRegion!) {
    }

    public func stopMonitoringForRegion(region:CLRegion!) {
    }

    // CLLocationManagerDelegate
    public func locationManager(_: CLLocationManager!, didUpdateLocations locations:[AnyObject]!) {
        if let locationsUpdateSuccessCallback = self.locationsUpdateSuccessCallback {
            locationsUpdateSuccessCallback(locations:locations)
        }
    }
    
    public func locationManager(_:CLLocationManager!, didFailWithError error:NSError!) {
        if let locationsUpdateFaliedCallback = self.locationsUpdateFailedCallback {
            locationsUpdateFaliedCallback(error:error)
        }
    }
    
    public func locationManager(_: CLLocationManager!, didFinishDeferredUpdatesWithError error:NSError!) {
    }
    
    public func locationManagerDidPauseLocationUpdates(_:CLLocationManager!) {
    }
    
    public func locationManagerDidResumeLocationUpdates(_:CLLocationManager!) {
    }
    
    public func locationManager(_:CLLocationManager!, didEnterRegion region:CLRegion!) {
    }
    
    public func locationManager(_:CLLocationManager!, didExitRegion region:CLRegion!) {
    }
    
    public func locationManager(_:CLLocationManager!, didDetermineState state:CLRegionState, forRegion region:CLRegion!) {
    }
    
    public func locationManager(_:CLLocationManager!, didStartMonitoringForRegion region:CLRegion!) {
    }
    
    public func locationManager(_:CLLocationManager!,  didVisit visit:CLVisit!) {
    }
    
    public func locationManager(_:CLLocationManager!, didChangeAuthorizationStatus status:CLAuthorizationStatus) {
    }
}
