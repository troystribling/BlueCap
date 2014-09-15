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
    
    public var regionMonitors : [RegionMonitor] {
        return self.configuredRegionMonitors.values.array
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
    
    public func startMonitoringAllRegions() {
        for regionMonitor in self.regionMonitors {
            self.clLocationManager.startMonitoringForRegion(regionMonitor.region)
        }
    }
    
    public func stopMonitoringAllRegions() {
        for regionMonitor in self.regionMonitors {
            self.clLocationManager.stopMonitoringForRegion(regionMonitor.region)
        }
    }

    // CLLocationManagerDelegate
    public func locationManager(_:CLLocationManager!, didEnterRegion region:CLRegion!) {
        Logger.debug("RegionManager#didEnterRegion: \(region.identifier)")
        if let regionMonitor = self.configuredRegionMonitors[region] {
            if let enterRegion = regionMonitor.enterRegion {
                enterRegion()
            }
        }
    }
    
    public func locationManager(_:CLLocationManager!, didExitRegion region:CLRegion!) {
        Logger.debug("RegionManager#didExitRegion: \(region.identifier)")
        if let regionMonitor = self.configuredRegionMonitors[region] {
            if let exitRegion = regionMonitor.exitRegion {
                exitRegion()
            }
        }
    }
    
    public func locationManager(_:CLLocationManager!, didDetermineState state:CLRegionState, forRegion region:CLRegion!) {
        Logger.debug("RegionManager#didDetermineState: \(region.identifier)")
        if let regionMonitor = self.configuredRegionMonitors[region] {
            if let regionStateChanged = regionMonitor.regionStateChanged {
                regionStateChanged(state:state)
            }
        }
    }
    
    public func locationManager(_:CLLocationManager!, monitoringDidFailForRegion region:CLRegion!, withError error:NSError!) {
        Logger.debug("RegionManager#monitoringDidFailForRegion: \(region.identifier)")
        if let regionMonitor = self.configuredRegionMonitors[region] {
            if let errorMonitoringRegion = regionMonitor.errorMonitoringRegion {
                errorMonitoringRegion(error:error)
            }
        }
    }
    
    public func locationManager(_:CLLocationManager!, didStartMonitoringForRegion region:CLRegion!) {
        Logger.debug("RegionManager#didStartMonitoringForRegion: \(region.identifier)")
        if let regionMonitor = self.configuredRegionMonitors[region] {
            if let startMonitoringRegion = regionMonitor.startMonitoringRegion {
                startMonitoringRegion()
            }
        }
    }
}

var thisRegionManager : RegionManager?
