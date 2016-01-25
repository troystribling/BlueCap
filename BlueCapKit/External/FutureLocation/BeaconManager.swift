//
//  BeaconManager.swift
//  BlueCap
//
//  Created by Troy Stribling on 8/22/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import Foundation
import CoreLocation

// MARK - BeaconManager -
public class BeaconManager : RegionManager {

    // MARK: Properties
    private var regionRangingStatus = SerialIODictionary<String, Bool>(LocationManagerIO.queue)
    internal var configuredBeaconRegions = SerialIODictionary<String, BeaconRegion>(LocationManagerIO.queue)

    public func isRangingAvailable() -> Bool {
        return CLLocationManager.isRangingAvailable()
    }

    public var beaconRegions: [BeaconRegion] {
        return self.configuredBeaconRegions.values
    }

    public func beaconRegion(identifier: String) -> BeaconRegion? {
        return self.configuredBeaconRegions[identifier]
    }

    //MARK: Initialize
    public convenience init() {
        self.init(clLocationManager: CLLocationManager())
    }

    public override init(clLocationManager: CLLocationManagerInjectable) {
        super.init(clLocationManager: clLocationManager)
    }

    // MARK: Control
    public var isRanging: Bool {
        return Array(self.regionRangingStatus.values).filter{$0}.count > 0
    }

    public func isRangingRegion(identifier:String) -> Bool {
        return self.regionRangingStatus[identifier] ?? false
    }

    public func startRangingBeaconsInRegion(beaconRegion: BeaconRegion, context: ExecutionContext = QueueContext.main) -> FutureStream<[Beacon]> {
        let authoriztaionFuture = self.authorize(CLAuthorizationStatus.AuthorizedAlways)
        authoriztaionFuture.onSuccess(context) {status in
            Logger.debug("authorization status: \(status)")
            self.regionRangingStatus[beaconRegion.identifier] = true
            self.configuredBeaconRegions[beaconRegion.identifier] = beaconRegion
            self.configuredRegions[beaconRegion.identifier] = beaconRegion
            self.clLocationManager.startRangingBeaconsInRegion(beaconRegion.clBeaconRegion)
        }
        authoriztaionFuture.onFailure(context) {error in
            beaconRegion.beaconPromise.failure(error)
        }
        return beaconRegion.beaconPromise.future

    }

    public func stopRangingBeaconsInRegion(beaconRegion: BeaconRegion) {
        self.configuredBeaconRegions.removeValueForKey(beaconRegion.identifier)
        self.regionRangingStatus[beaconRegion.identifier] = false
        self.configuredRegions.removeValueForKey(beaconRegion.identifier)
        self.clLocationManager.stopRangingBeaconsInRegion(beaconRegion.clBeaconRegion)
    }

    public func stopRangingAllBeacons() {
        for beaconRegion in self.beaconRegions {
            self.stopRangingBeaconsInRegion(beaconRegion)
        }
    }
    
    // MARK: CLLocationManagerDelegate
    public func locationManager(_: CLLocationManager, didRangeBeacons beacons: [CLBeacon], inRegion region: CLBeaconRegion) {
        self.didRangeBeacons(beacons.map{$0 as CLBeaconInjectable}, inRegion: region)
    }
    
    public func locationManager(_: CLLocationManager, rangingBeaconsDidFailForRegion region: CLBeaconRegion, withError error: NSError) {
        self.rangingBeaconsDidFailForRegion(region, withError: error)
    }

    public func didRangeBeacons(beacons: [CLBeaconInjectable], inRegion region: CLBeaconRegion) {
        Logger.debug("region identifier \(region.identifier)")
        if let beaconRegion = self.configuredBeaconRegions[region.identifier] {
            let flBeacons = beacons.map{Beacon(clBeacon:$0)}
            beaconRegion._beacons = flBeacons
            beaconRegion.beaconPromise.success(flBeacons)
        }
    }

    public func rangingBeaconsDidFailForRegion(region: CLBeaconRegion, withError error: NSError) {
        Logger.debug("region identifier \(region.identifier)")
        self.regionRangingStatus[region.identifier] = false
        self.configuredBeaconRegions[region.identifier]?.beaconPromise.failure(error)
    }
    
}
