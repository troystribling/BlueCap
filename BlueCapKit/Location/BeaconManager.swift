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
    
    private var regionRangingStatus         : [String:Bool]                     = [:]
    internal var configuredBeaconRegions    : [CLBeaconRegion:BeaconRegion]     = [:]

    public var beaconRegions : [BeaconRegion] {
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
    public func startRangingBeaconsInRegion(authorization:CLAuthorizationStatus, beaconRegion:BeaconRegion) -> FutureStream<[Beacon]> {
        let authoriztaionFuture = self.authorize(authorization)
        authoriztaionFuture.onSuccess {status in
            self.regionRangingStatus[beaconRegion.identifier] = true
            self.configuredBeaconRegions[beaconRegion.clBeaconRegion] = beaconRegion
            self.clLocationManager.startRangingBeaconsInRegion(beaconRegion.clBeaconRegion)
        }
        authoriztaionFuture.onFailure {error in
            beaconRegion.beaconPromise.failure(error)
        }
        return beaconRegion.beaconPromise.future
    }

    public func startRangingBeaconsInRegion(beaconRegion:BeaconRegion) -> FutureStream<[Beacon]> {
       return self.startRangingBeaconsInRegion(CLAuthorizationStatus.AuthorizedAlways, beaconRegion:beaconRegion)
    }

    public func stopRangingBeaconsInRegion(beaconRegion:BeaconRegion) {
        self.regionRangingStatus.removeValueForKey(beaconRegion.identifier)
        self.configuredBeaconRegions.removeValueForKey(beaconRegion.clBeaconRegion)
        self.clLocationManager.stopRangingBeaconsInRegion(beaconRegion.clBeaconRegion)
    }
    
    public func resumeRangingAllBeacons() {
        for beaconRegion in self.beaconRegions {
            self.regionRangingStatus[beaconRegion.identifier] = true
            self.clLocationManager.startRangingBeaconsInRegion(beaconRegion.clBeaconRegion)
        }
    }
    
    public func pauseRangingAllBeacons() {
        for beaconRegion in self.beaconRegions {
            self.regionRangingStatus[beaconRegion.identifier] = false
            self.clLocationManager.stopRangingBeaconsInRegion(beaconRegion.clBeaconRegion)
        }
    }

    public func stopRangingAllBeacons() {
        for beaconRegion in self.beaconRegions {
            self.stopRangingBeaconsInRegion(beaconRegion)
        }
    }

    public func requestStateForRegion(beaconMonitor:BeaconRegion) {
        self.clLocationManager.requestStateForRegion(beaconMonitor.clRegion)
    }
    
    // CLLocationManagerDelegate
    public func locationManager(_:CLLocationManager!, didRangeBeacons beacons:[AnyObject]!, inRegion region:CLBeaconRegion!) {
        Logger.debug("BeaconManager#didRangeBeacons: \(region.identifier)")
        if let beaconRegion = self.configuredBeaconRegions[region] {
            let bcbeacons = beacons.map{Beacon(clbeacon:($0 as! CLBeacon))}
            beaconRegion._beacons = bcbeacons
            beaconRegion.beaconPromise.success(bcbeacons)
        }
    }
    
    public func locationManager(_:CLLocationManager!, rangingBeaconsDidFailForRegion region:CLBeaconRegion!, withError error:NSError!) {
        Logger.debug("BeaconManager#rangingBeaconsDidFailForRegion: \(region.identifier)")
        if let beaconRegion = self.configuredBeaconRegions[region] {
            beaconRegion.beaconPromise.failure(error)
        }
    }
    
}

private var thisBeaconManager : BeaconManager?