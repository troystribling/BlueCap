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

    internal var configuredRegions       : [CLRegion:Region] = [:]
    internal var regionMonitorStatus     : [String:Bool]     = [:]

    
    public var regions : [Region] {
        return self.configuredRegions.values.array
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
    
    public func isMonitoringAllRegions() -> Bool {
        var status = true
        for regionStatus in self.regionMonitorStatus.values.array {
            if !regionStatus {
                status = false
                break
            }
        }
        return status
    }
    
    public func isMonitoringRegion(identifier:String) -> Bool {
        if let status = self.regionMonitorStatus[identifier] {
            return status
        } else {
            return false
        }
    }
    
    // control
    public func startMonitoringForRegion(region:Region) {
        self.regionMonitorStatus[region.idenitifier] = true
        self.configuredRegions[region.region] = region
        self.clLocationManager.startMonitoringForRegion(region.region)
    }

    public func stopMonitoringForRegion(region:Region) {
        self.regionMonitorStatus[region.idenitifier] = false
        self.configuredRegions.removeValueForKey(region.region)
        self.clLocationManager.stopMonitoringForRegion(region.region)
    }
    
    public func startMonitoringAllRegions() {
        for regionMonitor in self.regions {
            self.clLocationManager.startMonitoringForRegion(regionMonitor.region)
        }
    }
    
    public func stopMonitoringAllRegions() {
        for regionMonitor in self.regions {
            self.clLocationManager.stopMonitoringForRegion(regionMonitor.region)
        }
    }

    // CLLocationManagerDelegate
    public func locationManager(_:CLLocationManager!, didEnterRegion region:CLRegion!) {
        Logger.debug("RegionManager#didEnterRegion: \(region.identifier)")
        if let bcregion = self.configuredRegions[region] {
            if let enterRegion = bcregion.enterRegion {
                enterRegion()
            }
        }
    }
    
    public func locationManager(_:CLLocationManager!, didExitRegion region:CLRegion!) {
        Logger.debug("RegionManager#didExitRegion: \(region.identifier)")
        if let bcregion = self.configuredRegions[region] {
            if let exitRegion = bcregion.exitRegion {
                exitRegion()
            }
        }
    }
    
    public func locationManager(_:CLLocationManager!, didDetermineState state:CLRegionState, forRegion region:CLRegion!) {
        Logger.debug("RegionManager#didDetermineState: \(region.identifier)")
        if let bcregion = self.configuredRegions[region] {
            if let regionStateChanged = bcregion.regionStateChanged {
                regionStateChanged(state:state)
            }
        }
    }
    
    public func locationManager(_:CLLocationManager!, monitoringDidFailForRegion region:CLRegion!, withError error:NSError!) {
        Logger.debug("RegionManager#monitoringDidFailForRegion: \(region.identifier)")
        if let bcregion = self.configuredRegions[region] {
            if let errorMonitoringRegion = bcregion.errorMonitoringRegion {
                errorMonitoringRegion(error:error)
            }
        }
    }
    
    public func locationManager(_:CLLocationManager!, didStartMonitoringForRegion region:CLRegion!) {
        Logger.debug("RegionManager#didStartMonitoringForRegion: \(region.identifier)")
        if let bcregion = self.configuredRegions[region] {
            if let startMonitoringRegion = bcregion.startMonitoringRegion {
                startMonitoringRegion()
            }
        }
    }
}

var thisRegionManager : RegionManager?
