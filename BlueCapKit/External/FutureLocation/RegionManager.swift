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

    // MARK: Serialized Properties
    internal var regionMonitorStatus = SerialIODictionary<String, Bool>(LocationManager.ioQueue)
    internal var configuredRegions = SerialIODictionary<String, Region>(LocationManager.ioQueue)
    fileprivate var requestStateForRegionPromises = SerialIODictionary<String, Promise<CLRegionState>>(LocationManager.ioQueue)

    fileprivate var _isMonitoring = false

    // MARK: Configure
    public var maximumRegionMonitoringDistance: CLLocationDistance {
        return self.clLocationManager.maximumRegionMonitoringDistance
    }

    public var regions: [Region] {
        return self.configuredRegions.values
    }

    public func region(_ identifier: String) -> Region? {
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
    public fileprivate(set) var isMonitoring : Bool {
        get {
            return LocationManager.ioQueue.sync { return self._isMonitoring}
        }
        set {
            LocationManager.ioQueue.sync { self._isMonitoring = newValue }
        }
    }

    public func isMonitoringRegion(_ identifier: String) -> Bool {
        return self.regionMonitorStatus[identifier] ?? false
    }

    public func startMonitoring(forRegion region: Region, authorization: CLAuthorizationStatus = .authorizedWhenInUse, context: ExecutionContext = QueueContext.main) -> FutureStream<RegionState> {
        let authoriztaionFuture = self.authorize(authorization)
        authoriztaionFuture.onSuccess(context: context) {status in
            self.configuredRegions[region.identifier] = region
            self.clLocationManager.startMonitoringForRegion(region.clRegion)
        }
        authoriztaionFuture.onFailure(context: context) {error in
            region.regionPromise.failure(error)
        }
        return region.regionPromise.stream
    }

    public func stopMonitoringForRegion(_ region: Region) {
        self.regionMonitorStatus.removeValueForKey(region.identifier)
        self.configuredRegions.removeValueForKey(region.identifier)
        self.clLocationManager.stopMonitoringForRegion(region.clRegion)
        self.updateIsMonitoring(false)
    }

    public func stopMonitoringAllRegions() {
        for region in self.regions {
            self.stopMonitoringForRegion(region)
        }
    }

    public func requestState(forRegion region: Region) -> Future<CLRegionState> {
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
    
    public func locationManager(_:CLLocationManager, monitoringDidFailForRegion region: CLRegion?, withError error: Error) {
        self.monitoringDidFailForRegion(region, withError: error)
    }
    
    public func locationManager(_: CLLocationManager, didStartMonitoringForRegion region: CLRegion) {
        self.didStartMonitoringForRegion(region)
    }

    public func didEnterRegion(_ region: CLRegion) {
        Logger.debug("region identifier \(region.identifier)")
        self.configuredRegions[region.identifier]?.regionPromise.success(.inside)
    }

    public func didExitRegion(_ region: CLRegion) {
        Logger.debug("region identifier \(region.identifier)")
        self.configuredRegions[region.identifier]?.regionPromise.success(.outside)
    }

    public func didDetermineState(_ state: CLRegionState, forRegion region: CLRegion) {
        Logger.debug("region identifier \(region.identifier)")
        self.requestStateForRegionPromises[region.identifier]?.success(state)
        self.requestStateForRegionPromises.removeValueForKey(region.identifier)
    }

    public func monitoringDidFailForRegion(_ region: CLRegion?, withError error: Error) {
        if let region = region, let flRegion = self.configuredRegions[region.identifier] {
            Logger.debug("region identifier '\(region.identifier)'")
            self.regionMonitorStatus[region.identifier] = false
            self.updateIsMonitoring(false)
            flRegion.regionPromise.failure(error)
        }
    }

    public func didStartMonitoringForRegion(_ region: CLRegion) {
        Logger.debug("region identifier \(region.identifier)")
        self.updateIsMonitoring(true)
        self.regionMonitorStatus[region.identifier] = true
        self.configuredRegions[region.identifier]?.regionPromise.success(.start)
    }

    // MARK: Utilities
    func updateIsMonitoring(_ value: Bool) {
        let regionCount = self.regionMonitorStatus.values.filter{$0}.count
        if value {
            self.isMonitoring = true
        } else {
            if regionCount == 0 {
                self.isMonitoring = false
            }
        }
    }

}

