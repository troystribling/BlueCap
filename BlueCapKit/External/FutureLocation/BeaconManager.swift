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
    fileprivate var regionRangingStatus = SerialIODictionary<String, Bool>(LocationManager.ioQueue)
    internal var configuredBeaconRegions = SerialIODictionary<String, BeaconRegion>(LocationManager.ioQueue)

    fileprivate var _isRanging = false

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
    public private(set) var isRanging : Bool {
        get {
            return LocationManager.ioQueue.sync { return self._isRanging}
        }
        set {
            LocationManager.ioQueue.sync { self._isRanging = newValue }
        }
    }

    public func isRangingRegion(identifier:String) -> Bool {
        return self.regionRangingStatus[identifier] ?? false
    }

    public func startRangingBeacons(inRegion beaconRegion: BeaconRegion, context: ExecutionContext = QueueContext.main) -> FutureStream<[Beacon]> {
        let authoriztaionFuture = self.authorize(CLAuthorizationStatus.authorizedAlways)
        return authoriztaionFuture.flatMap(context: context) {status in
            Logger.debug("authorization status: \(status)")
            self.configuredBeaconRegions[beaconRegion.identifier] = beaconRegion
            self.clLocationManager.startRangingBeaconsInRegion(beaconRegion.clBeaconRegion)
            return beaconRegion.beaconPromise.stream
        }
    }

    public func stopRangingBeacons(inRegion beaconRegion: BeaconRegion) {
        self.configuredBeaconRegions.removeValueForKey(beaconRegion.identifier)
        self.regionRangingStatus.removeValueForKey(beaconRegion.identifier)
        self.updateIsRanging(false)
        self.clLocationManager.stopRangingBeaconsInRegion(beaconRegion.clBeaconRegion)
    }

    public func stopRangingAllBeacons() {
        for beaconRegion in self.beaconRegions {
            self.stopRangingBeacons(inRegion: beaconRegion)
        }
    }
    
    // MARK: CLLocationManagerDelegate
    public func locationManager(_: CLLocationManager, didRangeBeacons beacons: [CLBeacon], inRegion region: CLBeaconRegion) {
        self.didRange(beacons: beacons.map { $0 as CLBeaconInjectable }, inRegion: region)
    }
    
    public func locationManager(_: CLLocationManager, rangingBeaconsDidFailForRegion region: CLBeaconRegion, withError error: Error) {
        self.rangingBeaconsDidFail(inRegion: region, withError: error)
    }

    public func didRange(beacons: [CLBeaconInjectable], inRegion region: CLBeaconRegion) {
        Logger.debug("region identifier \(region.identifier)")
        if let beaconRegion = self.configuredBeaconRegions[region.identifier] {
            self.regionRangingStatus[beaconRegion.identifier] = true
            self.updateIsRanging(true)
            let flBeacons = beacons.map { Beacon(clBeacon:$0) }
            beaconRegion._beacons = flBeacons
            beaconRegion.beaconPromise.success(flBeacons)
        }
    }

    public func rangingBeaconsDidFail(inRegion region: CLBeaconRegion, withError error: Error) {
        Logger.debug("region identifier \(region.identifier)")
        self.regionRangingStatus[region.identifier] = false
        self.updateIsRanging(false)
        self.configuredBeaconRegions[region.identifier]?.beaconPromise.failure(error)
    }

    // MARK: Utilies
    func updateIsRanging(_ value: Bool) {
        let regionCount = self.regionRangingStatus.values.filter{$0}.count
        if value {
            self.isRanging = true
        } else {
            if regionCount == 0 {
                self.isRanging = false
            }
        }
    }

}
