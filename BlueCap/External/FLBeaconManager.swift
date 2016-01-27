//
//  FLBeaconManager.swift
//  BlueCap
//
//  Created by Troy Stribling on 8/22/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import Foundation
import CoreLocation

// MARK - FLBeaconManager -
public class FLBeaconManager : FLRegionManager {

    // MARK: Properties
    private var regionRangingStatus = FLSerialIODictionary<String, Bool>(FLLocationManager.ioQueue)
    internal var configuredBeaconRegions = FLSerialIODictionary<String, FLBeaconRegion>(FLLocationManager.ioQueue)

    public func isRangingAvailable() -> Bool {
        return CLLocationManager.isRangingAvailable()
    }

    public var beaconRegions: [FLBeaconRegion] {
        return self.configuredBeaconRegions.values
    }

    public func beaconRegion(identifier: String) -> FLBeaconRegion? {
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

    public func startRangingBeaconsInRegion(beaconRegion: FLBeaconRegion, context: ExecutionContext = QueueContext.main) -> FutureStream<[FLBeacon]> {
        let authoriztaionFuture = self.authorize(CLAuthorizationStatus.AuthorizedAlways)
        authoriztaionFuture.onSuccess(context) {status in
            FLLogger.debug("authorization status: \(status)")
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

    public func stopRangingBeaconsInRegion(beaconRegion: FLBeaconRegion) {
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
        FLLogger.debug("region identifier \(region.identifier)")
        if let beaconRegion = self.configuredBeaconRegions[region.identifier] {
            let flBeacons = beacons.map{FLBeacon(clBeacon:$0)}
            beaconRegion._beacons = flBeacons
            beaconRegion.beaconPromise.success(flBeacons)
        }
    }

    public func rangingBeaconsDidFailForRegion(region: CLBeaconRegion, withError error: NSError) {
        FLLogger.debug("region identifier \(region.identifier)")
        self.regionRangingStatus[region.identifier] = false
        self.configuredBeaconRegions[region.identifier]?.beaconPromise.failure(error)
    }
    
}
