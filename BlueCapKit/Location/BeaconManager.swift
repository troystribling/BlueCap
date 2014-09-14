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
    
    private var configuredBeaconMonitors    : Dictionary<CLRegion, BeaconMonitor> = [:]
    
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
    
    // control
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
        Logger.debug("BeaconManager#didRangeBeacons")
        if let beaconMonitor = self.configuredBeaconMonitors[region] {
            if let rangedBeacons = beaconMonitor.rangedBeacons {
                let clbeacons = beacons.reduce([CLBeacon]()) {(clbeacons, beacon) in
                    if let beacon = beacon as? CLBeacon {
                        return clbeacons + [beacon]
                    } else {
                        return clbeacons
                    }
                }
                rangedBeacons(beacons:clbeacons)
            }
        }
    }
    
    public func locationManager(_:CLLocationManager!, rangingBeaconsDidFailForRegion region:CLBeaconRegion!, withError error:NSError!) {
        Logger.debug("BeaconManager#rangingBeaconsDidFailForRegion")
        if let beaconMonitor = self.configuredBeaconMonitors[region] {
            if let errorRangingBeacons = beaconMonitor.errorRangingBeacons {
                errorRangingBeacons(error:error)
            }
        }
    }
    
    public func locationManager(_:CLLocationManager!, didDetermineState state:CLRegionState, forRegion region:CLRegion!) {
        if let beaconMonitor = self.configuredBeaconMonitors[region] {
            if let regionStateChanged = beaconMonitor.regionStateChanged {
                Logger.debug("BeaconManager#didDetermineState")
                regionStateChanged(state:state)
            }
        }
    }

}

var thisBeaconManager : BeaconManager?