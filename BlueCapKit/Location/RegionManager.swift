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
    
    public class func sharedInstance() -> RegionManager {
        if thisRegionManager == nil {
            thisRegionManager = RegionManager()
        }
        return thisRegionManager!
    }
    
    public override init() {
        super.init()
    }
    
    public func isMonitoring() -> Bool {
        var status = false
        for regionStatus in self.regionMonitorStatus.values.array {
            if regionStatus {
                status = true
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
    
    public func region(identifier:String) -> Region? {
        let regions = self.configuredRegions.keys.array.filter{$0.identifier == identifier}
        if let region = regions.first {
            return self.configuredRegions[region]
        } else {
            return nil
        }
    }

    // control
    public func startMonitoringForRegion(authorization:CLAuthorizationStatus, region:Region) {
        self.authorize(authorization){
            self.regionMonitorStatus[region.identifier] = true
            self.configuredRegions[region.region] = region
            self.clLocationManager.startMonitoringForRegion(region.region)
        }
    }

    public func startMonitoringForRegion(region:Region) {
        self.startMonitoringForRegion(CLAuthorizationStatus.Authorized, region:region)
    }

    public func stopMonitoringForRegion(region:Region) {
        self.regionMonitorStatus.removeValueForKey(region.identifier)
        self.configuredRegions.removeValueForKey(region.region)
        self.clLocationManager.stopMonitoringForRegion(region.region)
    }
    
    public func resumeMonitoringAllRegions() {
        for region in self.regions {
            self.regionMonitorStatus[region.identifier] = true
            self.clLocationManager.startMonitoringForRegion(region.region)
        }
    }
    
    public func pauseMonitoringAllRegions() {
        for region in self.regions {
            self.regionMonitorStatus[region.identifier] = false
            self.clLocationManager.stopMonitoringForRegion(region.region)
        }
    }

    public func stopMonitoringAllRegions() {
        for region in self.regions {
            self.stopMonitoringForRegion(region)
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
            if let regionStateDetermined = bcregion.regionStateDetermined {
                regionStateDetermined(state:state)
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
