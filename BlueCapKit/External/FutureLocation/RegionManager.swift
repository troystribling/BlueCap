//
//  LocationRegionManager.swift
//  BlueCap
//
//  Created by Troy Stribling on 8/22/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import Foundation
import CoreLocation

// MARK: - RegionManager -
public class RegionManager : LocationManager {

    // MARK: Properties
    internal var regionMonitorStatus = SerialDictionary<String, Bool>(LocationManagerIO.queue)
    internal var configuredRegions = SerialDictionary<String, Region>(LocationManagerIO.queue)
    private var requestStateForRegionPromises = SerialDictionary<String, Promise<CLRegionState>>(LocationManagerIO.queue)


    // MARK: Configure
    public var maximumRegionMonitoringDistance: CLLocationDistance {
        return self.clLocationManager.maximumRegionMonitoringDistance
    }

    public var regions: [Region] {
        return self.configuredRegions.values
    }

    public func region(identifier: String) -> Region? {
        return self.configuredRegions[identifier]
    }

    //MARK: Initialize
    public convenience init() {
        self.init(clLocationManager: CLLocationManager())
    }

    public override init(clLocationManager: CLLocationManagerInjectable) {
        super.init(clLocationManager: clLocationManager)
    }

    // MARK: Control
    public var isMonitoring : Bool {
        return self.regionMonitorStatus.values.filter{$0}.count > 0
    }

    public func isMonitoringRegion(identifier: String) -> Bool {
        return self.regionMonitorStatus[identifier] ?? false
    }

    public func startMonitoringForRegion(region: Region, authorization: CLAuthorizationStatus = .AuthorizedWhenInUse, context: ExecutionContext = QueueContext.main) -> FutureStream<RegionState> {
        let authoriztaionFuture = self.authorize(authorization)
        authoriztaionFuture.onSuccess(context) {status in
            self.configuredRegions[region.identifier] = region
            self.clLocationManager.startMonitoringForRegion(region.clRegion)
        }
        authoriztaionFuture.onFailure(context) {error in
            region.regionPromise.failure(error)
        }
        return region.regionPromise.future
    }

    public func stopMonitoringForRegion(region: Region) {
        self.regionMonitorStatus.removeValueForKey(region.identifier)
        self.configuredRegions.removeValueForKey(region.identifier)
        self.clLocationManager.stopMonitoringForRegion(region.clRegion)
    }

    public func stopMonitoringAllRegions() {
        for region in self.regions {
            self.stopMonitoringForRegion(region)
        }
    }

    public func requestStateForRegion(region: Region) -> Future<CLRegionState> {
        self.requestStateForRegionPromises[region.identifier] = Promise<CLRegionState>()
        self.clLocationManager.requestStateForRegion(region.clRegion)
        return self.requestStateForRegionPromises[region.identifier]!.future
    }

    // MARK: CLLocationManagerDelegate
    public func locationManager(_: CLLocationManager, didEnterRegion region: CLRegion) {
        self.didEnterRegion(region)
    }
    
    public func locationManager(_: CLLocationManager, didExitRegion region: CLRegion) {
        self.didExitRegion(region)
    }
    
    public func locationManager(_: CLLocationManager, didDetermineState state: CLRegionState, forRegion region: CLRegion) {
        self.didDetermineState(state, forRegion: region)
    }
    
    public func locationManager(_:CLLocationManager, monitoringDidFailForRegion region: CLRegion?, withError error:NSError) {
        self.monitoringDidFailForRegion(region, withError: error)
    }
    
    public func locationManager(_: CLLocationManager, didStartMonitoringForRegion region: CLRegion) {
        self.didStartMonitoringForRegion(region)
    }

    public func didEnterRegion(region: CLRegion) {
        Logger.debug("region identifier \(region.identifier)")
        self.configuredRegions[region.identifier]?.regionPromise.success(.Inside)
    }

    public func didExitRegion(region: CLRegion) {
        Logger.debug("region identifier \(region.identifier)")
        self.configuredRegions[region.identifier]?.regionPromise.success(.Outside)
    }

    public func didDetermineState(state: CLRegionState, forRegion region: CLRegion) {
        Logger.debug("region identifier \(region.identifier)")
        self.requestStateForRegionPromises[region.identifier]?.success(state)
        self.requestStateForRegionPromises.removeValueForKey(region.identifier)
    }

    public func monitoringDidFailForRegion(region: CLRegion?, withError error:NSError) {
        if let region = region, flRegion = self.configuredRegions[region.identifier] {
            Logger.debug("region identifier '\(region.identifier)'")
            self.regionMonitorStatus[region.identifier] = false
            flRegion.regionPromise.failure(error)
        }
    }

    public func didStartMonitoringForRegion(region: CLRegion) {
        Logger.debug("region identifier \(region.identifier)")
        self.regionMonitorStatus[region.identifier] = true
        self.configuredRegions[region.identifier]?.regionPromise.success(.Start)
    }
}

