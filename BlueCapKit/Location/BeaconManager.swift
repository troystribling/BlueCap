//
//  BeaconManager.swift
//  BlueCap
//
//  Created by Troy Stribling on 8/22/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation
import CoreLocation

public class BeaconManager : RegionManager {
    
    private var regionRangingStatus : [String:Bool]  = [:]

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
        for regionStatus in self.regionRangingStatus.values.array {
            if !regionStatus {
                status = false
                break
            }
        }
        return status
    }
    
    public func isRangingRegion(identifier:String) -> Bool {
        if let status = self.regionRangingStatus[identifier] {
            return status
        } else {
            return false
        }
    }

    // control
    public func startRangingBeaconsInRegion(beaconRegion:BeaconRegion) {
        self.configuredRegions[beaconRegion.region] = beaconRegion
        self.clLocationManager.startRangingBeaconsInRegion(beaconRegion.region as CLBeaconRegion)
    }
    
    public func stopRangingBeaconsInRegion(beaconRegion:BeaconRegion) {
        self.configuredRegions.removeValueForKey(beaconRegion.region)
        self.clLocationManager.stopMonitoringForRegion(beaconRegion.region as CLBeaconRegion)
    }
    
    public func startRangingAllBeacons() {
        for beaconRegion in self.regions {
            self.clLocationManager.startRangingBeaconsInRegion(beaconRegion.region as CLBeaconRegion)
        }
    }
    
    public func stopRangingAllBeacons() {
        for beaconRegion in self.regions {
            self.clLocationManager.stopRangingBeaconsInRegion(beaconRegion.region as CLBeaconRegion)
        }
    }
    
    public func requestStateForRegion(beaconMonitor:BeaconRegion) {
        self.clLocationManager.requestStateForRegion(beaconMonitor.region)
    }
    
    // CLLocationManagerDelegate
    public func locationManager(_:CLLocationManager!, didRangeBeacons beacons:[AnyObject]!, inRegion region:CLBeaconRegion!) {
        Logger.debug("BeaconManager#didRangeBeacons: \(region.identifier)")
        if let region = self.configuredRegions[region] {
            let beaconRegion = region as BeaconRegion
            if let rangedBeacons = beaconRegion.rangedBeacons {
                let bcbeacons = beacons.reduce([Beacon]()) {(bcbeacons, beacon) in
                    if let beacon = beacon as? CLBeacon {
                        return bcbeacons + [Beacon(clbeacon:beacon)]
                    } else {
                        return bcbeacons
                    }
                }
                beaconRegion._beacons = bcbeacons
                rangedBeacons(beacons:bcbeacons)
            }
        }
    }
    
    public func locationManager(_:CLLocationManager!, rangingBeaconsDidFailForRegion region:CLBeaconRegion!, withError error:NSError!) {
        Logger.debug("BeaconManager#rangingBeaconsDidFailForRegion: \(region.identifier)")
        if let region = self.configuredRegions[region] {
            let beaconRegion = region as BeaconRegion
            if let errorRangingBeacons = beaconRegion.errorRangingBeacons {
                errorRangingBeacons(error:error)
            }
        }
    }
    
}

var thisBeaconManager : BeaconManager?