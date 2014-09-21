//
//  BeaconManager.swift
//  BlueCap
//
//  Created by Troy Stribling on 8/22/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation
import CoreLocation

public class BeaconManager : LocationManager {
    
    private var configuredBeaconMonitors    : [CLRegion:BeaconMonitor]  = [:]
    private var isRangingRegion             : [NSUUID:Bool]             = [:]
    private var isMonitoringRegion          : [NSUUID:Bool]             = [:]

    public var beaconMonitors : [BeaconMonitor] {
        return self.configuredBeaconMonitors.values.array
    }

    public override init() {
        super.init()
    }

    public class func isRangingAvailable() -> Bool {
        return CLLocationManager.isRangingAvailable()
    }
    
    public override class func sharedInstance() -> BeaconManager {
        if thisBeaconManager == nil {
            thisBeaconManager = BeaconManager()
        }
        return thisBeaconManager!
    }
    
    public func isRangingAllRegions() -> Bool {
        var status = true
        for regionStatus in self.isRangingRegion.values.array {
            if !regionStatus {
                status = false
                break
            }
        }
        return status
    }
    
    public func isRangingRegion(beaconMonitor:BeaconMonitor) -> Bool {
        return self.isRangingRegion(beaconMonitor.proximityUUID)
    }

    public func isRangingRegion(proximityUUID:NSUUID) -> Bool {
        if let status = self.isRangingRegion[proximityUUID] {
            return status
        } else {
            return false
        }
    }

    public func isMonitoringAllRegions() -> Bool {
        var status = true
        for regionStatus in self.isMonitoringRegion.values.array {
            if !regionStatus {
                
                status = false
                break
            }
        }
        return status
    }
    
    public func isMonitoringRegion(beaconMonitor:BeaconMonitor) -> Bool {
        return self.isMonitoringRegion(beaconMonitor.proximityUUID)
    }
    
    public func isMonitoringRegion(proximityUUID:NSUUID) -> Bool {
        if let status = self.isMonitoringRegion[proximityUUID] {
            return status
        } else {
            return false
        }
    }
    
    // control
    public func startMonitoringForRegion(beaconMonitor:BeaconMonitor) {
        self.isMonitoringRegion[beaconMonitor.proximityUUID] = true
        self.configuredBeaconMonitors[beaconMonitor.region] = beaconMonitor
        self.clLocationManager.startMonitoringForRegion(beaconMonitor.region)
    }
    
    public func stopMonitoringForRegion(beaconMonitor:BeaconMonitor) {
        self.isMonitoringRegion[beaconMonitor.proximityUUID] = false
        self.configuredBeaconMonitors.removeValueForKey(beaconMonitor.region)
        self.clLocationManager.stopMonitoringForRegion(beaconMonitor.region)
    }
    
    public func startMonitoringAllRegions() {
        for beaconMonitor in self.beaconMonitors {
            self.clLocationManager.startMonitoringForRegion(beaconMonitor.region)
        }
    }
    
    public func stopMonitoringAllRegions() {
        for beaconMonitor in self.beaconMonitors {
            self.clLocationManager.stopMonitoringForRegion(beaconMonitor.region)
        }
    }

    public func startRangingBeaconsInRegion(beaconMonitor:BeaconMonitor) {
        self.configuredBeaconMonitors[beaconMonitor.region] = beaconMonitor
        self.clLocationManager.startRangingBeaconsInRegion(beaconMonitor.region)
    }
    
    public func stopRangingBeaconsInRegion(beaconMonitor:BeaconMonitor) {
        self.configuredBeaconMonitors.removeValueForKey(beaconMonitor.region)
        self.clLocationManager.stopMonitoringForRegion(beaconMonitor.region)
    }
    
    public func startRangingAllBeacons() {
        for beaconMonitor in self.beaconMonitors {
            self.clLocationManager.startRangingBeaconsInRegion(beaconMonitor.region)
        }
    }
    
    public func stopRangingAllBeacons() {
        for beaconMonitor in self.beaconMonitors {
            self.clLocationManager.stopRangingBeaconsInRegion(beaconMonitor.region)
        }
    }
    
    public func requestStateForRegion(beaconMonitor:BeaconMonitor) {
        self.clLocationManager.requestStateForRegion(beaconMonitor.region)
    }
    
    // CLLocationManagerDelegate
    public func locationManager(_:CLLocationManager!, didRangeBeacons beacons:[AnyObject]!, inRegion region:CLBeaconRegion!) {
        Logger.debug("BeaconManager#didRangeBeacons: \(region.identifier)")
        if let beaconMonitor = self.configuredBeaconMonitors[region] {
            if let rangedBeacons = beaconMonitor.rangedBeacons {
                let bcbeacons = beacons.reduce([Beacon]()) {(bcbeacons, beacon) in
                    if let beacon = beacon as? CLBeacon {
                        return bcbeacons + [Beacon(clbeacon:beacon)]
                    } else {
                        return bcbeacons
                    }
                }
                beaconMonitor._beacons = bcbeacons
                rangedBeacons(beacons:bcbeacons)
            }
        }
    }
    
    public func locationManager(_:CLLocationManager!, rangingBeaconsDidFailForRegion region:CLBeaconRegion!, withError error:NSError!) {
        Logger.debug("BeaconManager#rangingBeaconsDidFailForRegion: \(region.identifier)")
        if let beaconMonitor = self.configuredBeaconMonitors[region] {
            if let errorRangingBeacons = beaconMonitor.errorRangingBeacons {
                errorRangingBeacons(error:error)
            }
        }
    }
    
    public func locationManager(_:CLLocationManager!, didEnterRegion region:CLRegion!) {
        Logger.debug("BeaconManager#didEnterRegion: \(region.identifier)")
        if let regionMonitor = self.configuredBeaconMonitors[region] {
            if let enterRegion = regionMonitor.enterRegion {
                enterRegion()
            }
        }
    }
    
    public func locationManager(_:CLLocationManager!, didExitRegion region:CLRegion!) {
        Logger.debug("BeaconManager#didExitRegion: \(region.identifier)")
        if let regionMonitor = self.configuredBeaconMonitors[region] {
            if let exitRegion = regionMonitor.exitRegion {
                exitRegion()
            }
        }
    }

    public func locationManager(_:CLLocationManager!, didDetermineState state:CLRegionState, forRegion region:CLRegion!) {
        Logger.debug("BeaconManager#didDetermineState: \(region.identifier)")
        if let beaconMonitor = self.configuredBeaconMonitors[region] {
            if let regionStateChanged = beaconMonitor.regionStateChanged {
                regionStateChanged(state:state)
            }
        }
    }

    public func locationManager(_:CLLocationManager!, monitoringDidFailForRegion region:CLRegion!, withError error:NSError!) {
        Logger.debug("BeaconManager#locationManager: \(region.identifier)")
        if let beaconMonitor = self.configuredBeaconMonitors[region] {
            if let errorMonitoringRegion = beaconMonitor.errorMonitoringRegion {
                errorMonitoringRegion(error:error)
            }
        }
    }
    
    public func locationManager(_:CLLocationManager!, didStartMonitoringForRegion region:CLRegion!) {
        Logger.debug("BeaconManager#didStartMonitoringForRegion: \(region.identifier)")
        if let beaconMonitor = self.configuredBeaconMonitors[region] {
            if let startMonitoringRegion = beaconMonitor.startMonitoringRegion {
                startMonitoringRegion()
            }
        }
    }

}

var thisBeaconManager : BeaconManager?