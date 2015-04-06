//
//  LocationRegionManager.swift
//  BlueCap
//
//  Created by Troy Stribling on 8/22/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation
import CoreLocation

/////////////////////////////////////////////
// RegionManagerImpl
public protocol RegionManagerWrappable {
    
    typealias WrappedRegion
    
    var regions : [WrappedRegion] {get}
    
    func region(identifier:String) -> WrappedRegion?
    func wrappedStartMonitoringForRegion(region:WrappedRegion)
    func wrappedStopMonitoringForRegion(region:WrappedRegion)
    
}

public protocol RegionWrappable {
    var regionPromise   : StreamPromise<RegionState> {get}
    var identifier      : String {get}
}

extension Region : RegionWrappable {
}

public class RegionManagerImpl<Wrapper where Wrapper:RegionManagerWrappable,
                               Wrapper:LocationManagerWrappable,
                               Wrapper.WrappedCLLocation:CLLocationWrappable,
                               Wrapper.WrappedRegion:RegionWrappable> : LocationManagerImpl<Wrapper> {
    
    internal var regionMonitorStatus = [String:Bool]()
    
    public var isMonitoring : Bool {
        return self.regionMonitorStatus.values.array.any{$0}
    }
    
    public override init() {
    }
    
    public func isMonitoringRegion(identifier:String) -> Bool {
        if let status = self.regionMonitorStatus[identifier] {
            return status
        } else {
            return false
        }
    }
    
    // control
    public func startMonitoringForRegion(manager:Wrapper, currentAuthorization:CLAuthorizationStatus, requestedAuthorization:CLAuthorizationStatus, region:Wrapper.WrappedRegion) -> FutureStream<RegionState> {
        let authoriztaionFuture = self.authorize(manager, currentAuthorization:currentAuthorization, requestedAuthorization:requestedAuthorization)
        authoriztaionFuture.onSuccess {status in
            self.regionMonitorStatus[region.identifier] = true
            manager.wrappedStartMonitoringForRegion(region)
        }
        authoriztaionFuture.onFailure {error in
            region.regionPromise.failure(error)
        }
        return region.regionPromise.future
    }
    
    public func stopMonitoringForRegion(manager:Wrapper, region:Wrapper.WrappedRegion) {
        self.regionMonitorStatus.removeValueForKey(region.identifier)
        manager.wrappedStopMonitoringForRegion(region)
    }
    
    public func resumeMonitoringAllRegions(manager:Wrapper) {
        for region in manager.regions {
            self.regionMonitorStatus[region.identifier] = true
            manager.wrappedStartMonitoringForRegion(region)
        }
    }
    
    public func pauseMonitoringAllRegions(manager:Wrapper) {
        for region in manager.regions {
            self.regionMonitorStatus[region.identifier] = false
            manager.wrappedStopMonitoringForRegion(region)
        }
    }
    
    public func stopMonitoringAllRegions(manager:Wrapper) {
        for region in manager.regions {
            self.stopMonitoringForRegion(manager, region:region)
        }
    }
    
    // CLLocationManagerDelegate
    public func didEnterRegion(region:Wrapper.WrappedRegion) {
        Logger.debug("RegionManagerImpl#didEnterRegion: \(region.identifier)")
        region.regionPromise.success(.Inside)
    }
    
    public func didExitRegion(region:Wrapper.WrappedRegion) {
        Logger.debug("RegionManagerImpl#didExitRegion: \(region.identifier)")
        region.regionPromise.success(.Outside)
    }
    
    public func didDetermineState(state:CLRegionState, forRegion region:Wrapper.WrappedRegion) {
        Logger.debug("RegionManagerImpl#didDetermineState: \(region.identifier)")
    }
    
    public func didFailMonitoringForRegion(region:Wrapper.WrappedRegion, error:NSError!) {
        Logger.debug("RegionManagerImpl#monitoringDidFailForRegion: \(region.identifier)")
        region.regionPromise.failure(error)
    }
    
    public func didStartMonitoringForRegion(region:Wrapper.WrappedRegion) {
        Logger.debug("RegionManagerImpl#didStartMonitoringForRegion: \(region.identifier)")
        region.regionPromise.success(.Start)
    }
}

// RegionManagerImpl
/////////////////////////////////////////////

public class RegionManager : LocationManager, RegionManagerWrappable {

    let regionImpl = RegionManagerImpl<RegionManager>()

    // RegionManagerWrappable
    public var regions : [Region] {
        return self.configuredRegions.values.array
    }

    public func region(identifier:String) -> Region? {
        let regions = self.configuredRegions.keys.array.filter{$0.identifier == identifier}
        if let region = regions.first {
            return self.configuredRegions[region]
        } else {
            return nil
        }
    }
    
    public func wrappedStartMonitoringForRegion(region:Region) {
        self.configuredRegions[region.clRegion] = region
        self.clLocationManager.startMonitoringForRegion(region.clRegion)
    }
    
    public func wrappedStopMonitoringForRegion(region:Region) {
        self.configuredRegions.removeValueForKey(region.clRegion)
        self.clLocationManager.stopMonitoringForRegion(region.clRegion)
    }
    // RegionManagerWrappable
    
    internal var configuredRegions : [CLRegion:Region] = [:]
    
    public var maximumRegionMonitoringDistance : CLLocationDistance {
        return self.clLocationManager.maximumRegionMonitoringDistance
    }

    public var isMonitoring : Bool {
        return self.regionImpl.isMonitoring
    }

    public class var sharedInstance : RegionManager {
        struct Static {
            static let instance = RegionManager()
        }
        return Static.instance
    }
    
    public override init() {
        super.init()
    }
    
    public func isMonitoringRegion(identifier:String) -> Bool {
        return self.regionImpl.isMonitoringRegion(identifier)
    }

    // control
    public func startMonitoringForRegion(region:Region, authorization:CLAuthorizationStatus = .AuthorizedAlways) -> FutureStream<RegionState> {
        return self.regionImpl.startMonitoringForRegion(self, currentAuthorization:LocationManager.authorizationStatus(), requestedAuthorization:authorization, region:region)
    }

    public func stopMonitoringForRegion(region:Region) {
        self.regionImpl.stopMonitoringForRegion(self, region:region)
    }
    
    public func resumeMonitoringAllRegions() {
        self.regionImpl.resumeMonitoringAllRegions(self)
    }
    
    public func pauseMonitoringAllRegions() {
        self.regionImpl.pauseMonitoringAllRegions(self)
    }

    public func stopMonitoringAllRegions() {
        self.regionImpl.stopMonitoringAllRegions(self)
    }

    // CLLocationManagerDelegate
    public func locationManager(_:CLLocationManager!, didEnterRegion region:CLRegion!) {
        Logger.debug("RegionManager#didEnterRegion: \(region.identifier)")
        if let bcregion = self.configuredRegions[region] {
           self.regionImpl.didEnterRegion(bcregion)
        }
    }
    
    public func locationManager(_:CLLocationManager!, didExitRegion region:CLRegion!) {
        Logger.debug("RegionManager#didExitRegion: \(region.identifier)")
        if let bcregion = self.configuredRegions[region] {
            self.regionImpl.didExitRegion(bcregion)
        }
    }
    
    public func locationManager(_:CLLocationManager!, didDetermineState state:CLRegionState, forRegion region:CLRegion!) {
        Logger.debug("RegionManager#didDetermineState: \(region.identifier)")
        if let bcregion = self.configuredRegions[region] {
            self.regionImpl.didDetermineState(state, forRegion:bcregion)
        }
    }
    
    public func locationManager(_:CLLocationManager!, monitoringDidFailForRegion region:CLRegion!, withError error:NSError!) {
        Logger.debug("RegionManager#monitoringDidFailForRegion: \(region.identifier)")
        if let bcregion = self.configuredRegions[region] {
            self.regionImpl.didFailMonitoringForRegion(bcregion, error:error)
        }
    }
    
    public func locationManager(_:CLLocationManager!, didStartMonitoringForRegion region:CLRegion!) {
        Logger.debug("RegionManager#didStartMonitoringForRegion: \(region.identifier)")
        if let bcregion = self.configuredRegions[region] {
            self.regionImpl.didStartMonitoringForRegion(bcregion)
        }
    }
}
