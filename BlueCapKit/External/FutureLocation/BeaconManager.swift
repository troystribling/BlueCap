//
//  BeaconManager.swift
//  BlueCap
//
//  Created by Troy Stribling on 8/22/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import Foundation
import CoreLocation

// MARK - FLBeaconManager -

public class BeaconManager : RegionManager {

    // MARK: Properties
    
    fileprivate var regionRangingStatus = [String : Bool]()
    internal var configuredBeaconRegions = [String : BeaconRegion]()

    public fileprivate(set) var isRanging = false

    public func isRangingAvailable() -> Bool {
        return CLLocationManager.isRangingAvailable()
    }

    public var beaconRegions: [BeaconRegion] {
        return Array(self.configuredBeaconRegions.values)
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
    
    public func isRangingRegion(identifier:String) -> Bool {
        return self.regionRangingStatus[identifier] ?? false
    }

    public func startRangingBeacons(in beaconRegion: BeaconRegion, authorization: CLAuthorizationStatus = .authorizedWhenInUse, capacity: Int = Int.max, context: ExecutionContext = QueueContext.main) -> FutureStream<[Beacon]> {
        Logger.debug("region identifier `\(beaconRegion.identifier)`")
        let authorizationFuture = self.authorize(authorization, context: context)
        authorizationFuture.onFailure { _ in self.updateIsRanging(false) }
        return authorizationFuture.flatMap(capacity: capacity, context: context) {status in
            Logger.debug("authorization status: \(status)")
            self.updateIsRanging(true)
            self.configuredBeaconRegions[beaconRegion.identifier] = beaconRegion
            self.clLocationManager.startRangingBeacons(in: beaconRegion.clBeaconRegion)
            return beaconRegion.beaconPromise.stream
        }
    }

    public func stopRangingBeacons(in beaconRegion: BeaconRegion) {
        Logger.debug("region identifier `\(beaconRegion.identifier)`")
        self.configuredBeaconRegions.removeValue(forKey: beaconRegion.identifier)
        self.regionRangingStatus.removeValue(forKey: beaconRegion.identifier)
        self.updateIsRanging(false)
        self.clLocationManager.stopRangingBeacons(in: beaconRegion.clBeaconRegion)
    }

    public func stopRangingAllBeacons() {
        for beaconRegion in self.beaconRegions {
            self.stopRangingBeacons(in: beaconRegion)
        }
    }
    
    // MARK: CLLocationManagerDelegate
    
    @objc public func locationManager(_: CLLocationManager, didRangeBeacons beacons: [CLBeacon], inRegion region: CLBeaconRegion) {
        self.didRange(beacons: beacons.map { $0 as CLBeaconInjectable }, inRegion: region)
    }
    
    @objc public func locationManager(_: CLLocationManager, rangingBeaconsDidFailForRegion region: CLBeaconRegion, withError error: Error) {
        self.rangingBeaconsDidFail(inRegion: region, withError: error)
    }

    public func didRange(beacons: [CLBeaconInjectable], inRegion region: CLBeaconRegion) {
        Logger.debug("ranged \(beacons.count) beacons, in region with identifier \(region.identifier)")
        if let beaconRegion = self.configuredBeaconRegions[region.identifier] {
            self.regionRangingStatus[beaconRegion.identifier] = true
            let flBeacons = beacons.map { Beacon(clBeacon:$0) }
            beaconRegion._beacons = flBeacons
            beaconRegion.beaconPromise.success(flBeacons)
        }
    }

    public func rangingBeaconsDidFail(inRegion region: CLBeaconRegion, withError error: Error) {
        Logger.debug("region identifier \(region.identifier)")
        self.regionRangingStatus[region.identifier] = false
        self.configuredBeaconRegions[region.identifier]?.beaconPromise.failure(error)
    }

    // MARK: Utilies
    
    func updateIsRanging(_ value: Bool) {
        let regionCount = Array(self.regionRangingStatus.values).filter{$0}.count
        if value {
            self.isRanging = true
        } else {
            if regionCount == 0 {
                self.isRanging = false
            }
        }
    }

}
