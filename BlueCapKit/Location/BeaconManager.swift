//
//  BeaconManager.swift
//  BlueCap
//
//  Created by Troy Stribling on 8/22/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation
import CoreLocation

public class BeaconManager : NSObject, CLLocationManagerDelegate {
    
    var clLocationManager : CLLocationManager!
    
    public override init() {
        super.init()
        self.clLocationManager = CLLocationManager()
        self.clLocationManager.delegate = self
    }

    public class func isRangingAvailable() -> Bool {
        return CLLocationManager.isRangingAvailable()
    }
    
    // CLLocationManagerDelegate
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
    
    public func locationManager(_:CLLocationManager!, didRangeBeacons beacons:[AnyObject]!, inRegion region:CLBeaconRegion!) {
    }
    
    public func locationManager(_:CLLocationManager!, rangingBeaconsDidFailForRegion region:CLBeaconRegion!, withError error:NSError!) {
    }
    
    public func locationManager(_:CLLocationManager!,  didVisit visit:CLVisit!) {
    }
    
    public func locationManager(_:CLLocationManager!, didChangeAuthorizationStatus status:CLAuthorizationStatus) {
    }

}
