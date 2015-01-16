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
    
    public var isRanging : Bool {
        return self.regionRangingStatus.values.array.any{$0}
    }
    
    public override init() {
        super.init()
    }

    public class func isRangingAvailable() -> Bool {
        return CLLocationManager.isRangingAvailable()
    }
    
    public override class var sharedInstance : BeaconManager {
        struct Static {
            static let instance = BeaconManager()
        }
        return Static.instance
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
    public func startRangingBeaconsInRegion(authorization:CLAuthorizationStatus, beaconRegion:BeaconRegion)  -> FutureStream<CLRegionState> {
        let authoriztaionFuture = self.authorize(authorization)
        authoriztaionFuture.onSuccess {status in
            self.regionRangingStatus[beaconRegion.identifier] = true
            self.configuredBeaconRegions[beaconRegion.region] = beaconRegion
            self.clLocationManager.startRangingBeaconsInRegion(beaconRegion.region as CLBeaconRegion)
        }
        authoriztaionFuture.onFailure {error in
            beaconRegion.promise.failure(error)
        }
        return beaconRegion.promise.future
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

private var thisBeaconManager : BeaconManager?