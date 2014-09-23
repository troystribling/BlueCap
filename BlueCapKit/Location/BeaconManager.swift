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
    
    private var regionRangingStatus         : [String:Bool]             = [:]
    internal var configuredBeaconRegions    : [CLRegion:BeaconRegion]   = [:]

    public var beaconRegions : [Region] {
        return self.configuredBeaconRegions.values.array
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
    
    public func isRanging() -> Bool {
        var status = false
        for regionStatus in self.regionRangingStatus.values.array {
            if regionStatus {
                status = true
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

    public func beaconRegion(identifier:String) -> BeaconRegion? {
        let regions = self.configuredBeaconRegions.keys.array.filter{$0.identifier == identifier}
        if let region = regions.first {
            return self.configuredBeaconRegions[region]
        } else {
            return nil
        }
    }
    
    // control
    public func startRangingBeaconsInRegion(authorization:CLAuthorizationStatus, beaconRegion:BeaconRegion) {
        self.authorize(authorization) {
            self.regionRangingStatus[beaconRegion.identifier] = true
            self.configuredBeaconRegions[beaconRegion.region] = beaconRegion
            self.clLocationManager.startRangingBeaconsInRegion(beaconRegion.region as CLBeaconRegion)
        }
    }

    public func startRangingBeaconsInRegion(beaconRegion:BeaconRegion) {
        self.startRangingBeaconsInRegion(CLAuthorizationStatus.Authorized, beaconRegion:beaconRegion)
    }

    public func stopRangingBeaconsInRegion(beaconRegion:BeaconRegion) {
        self.regionRangingStatus.removeValueForKey(beaconRegion.identifier)
        self.configuredBeaconRegions.removeValueForKey(beaconRegion.region)
        self.clLocationManager.stopRangingBeaconsInRegion(beaconRegion.region as CLBeaconRegion)
    }
    
    public func resumeRangingAllBeacons() {
        for beaconRegion in self.regions {
            self.regionRangingStatus[beaconRegion.identifier] = true
            self.clLocationManager.startRangingBeaconsInRegion(beaconRegion.region as CLBeaconRegion)
        }
    }
    
    public func pauseRangingAllBeacons() {
        for beaconRegion in self.regions {
            self.regionRangingStatus[beaconRegion.identifier] = false
            self.clLocationManager.stopRangingBeaconsInRegion(beaconRegion.region as CLBeaconRegion)
        }
    }

    public func stopRangingAllBeacons() {
        for beaconRegion in self.regions {
            self.stopRangingBeaconsInRegion(beaconRegion as BeaconRegion)
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