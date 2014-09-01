//
//  LocationRegionManager.swift
//  BlueCap
//
//  Created by Troy Stribling on 8/22/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation
import CoreLocation

public class RegionManager : LocationManager {

    private var configuredRegionMonitors    : Dictionary<CLRegion, RegionMonitor> = [:]
    
    public var regions : [CLRegion] {
        return Array(self.configuredRegionMonitors.keys)
    }
    
    public var regionMonitors : [RegionMonitor] {
        return Array(self.configuredRegionMonitors.values)
    }
    
    public var maximumRegionMonitoringDistance : CLLocationDistance {
        return self.clLocationManager.maximumRegionMonitoringDistance
    }
    
    public override class func sharedInstance() -> RegionManager {
        if thisRegionManager == nil {
            thisRegionManager = RegionManager()
        }
        return thisRegionManager!
    }
    
    public override init() {
        super.init()
    }
    
    // control
    public func startMonitoringForRegion(regionMonitor:RegionMonitor) {
        self.configuredRegionMonitors[regionMonitor.region] = regionMonitor
        self.clLocationManager.startMonitoringForRegion(regionMonitor.region)
    }

    public func stopMonitoringForRegion(regionMonitor:RegionMonitor) {
        self.configuredRegionMonitors.removeValueForKey(regionMonitor.region)
        self.clLocationManager.stopMonitoringForRegion(regionMonitor.region)
    }

    // CLLocationManagerDelegate
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
