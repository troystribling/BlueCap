//
//  BeaconManager.swift
//  BlueCap
//
//  Created by Troy Stribling on 8/22/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import Foundation
import CoreLocation

/////////////////////////////////////////////
// BeaconManagerImpl
public protocol BeaconManagerWrappable {

    typealias WrappedBeaconRegion

    var beaconRegions : [WrappedBeaconRegion] {get}
    
    func wrappedStartRangingBeaconsInRegion(beaconRegion:WrappedBeaconRegion)
    func wrappedStopRangingBeaconsInRegion(beaconRegion:WrappedBeaconRegion)
    
    func authorize(requestedAuthorization:CLAuthorizationStatus) -> Future<Void>
}

public protocol BeaconRegionWrappable {
    
    typealias WrappedBeacon
    
    var identifier     : String                         {get}
    var beaconPromise  : StreamPromise<[WrappedBeacon]> {get}
 
    func peripheralDataWithMeasuredPower(measuredPower:Int?) -> [NSObject:AnyObject]
}

public protocol BeaconWrappable {
}

extension BeaconRegion : BeaconRegionWrappable {
}

extension Beacon : BeaconWrappable {
}

public class BeaconManagerImpl<Wrapper where
                                Wrapper:BeaconManagerWrappable,
                                Wrapper.WrappedBeaconRegion:BeaconRegionWrappable,
                                Wrapper.WrappedBeaconRegion.WrappedBeacon:BeaconWrappable> {

    private var regionRangingStatus = [String:Bool]()

    public var isRanging : Bool {
        return self.regionRangingStatus.values.array.any{$0}
    }
    
    public init() {
    }
    
    public func isRangingRegion(identifier:String) -> Bool {
        if let status = self.regionRangingStatus[identifier] {
            return status
        } else {
            return false
        }
    }
    
    // control
    public func startRangingBeaconsInRegion(manager:Wrapper, authorization:CLAuthorizationStatus, beaconRegion:Wrapper.WrappedBeaconRegion) -> FutureStream<[Wrapper.WrappedBeaconRegion.WrappedBeacon]> {
        let authoriztaionFuture = manager.authorize(authorization)
        authoriztaionFuture.onSuccess {status in
            self.regionRangingStatus[beaconRegion.identifier] = true
            manager.wrappedStartRangingBeaconsInRegion(beaconRegion)
        }
        authoriztaionFuture.onFailure {error in
            beaconRegion.beaconPromise.failure(error)
        }
        return beaconRegion.beaconPromise.future
    }
    
    public func stopRangingBeaconsInRegion(manager:Wrapper, beaconRegion:Wrapper.WrappedBeaconRegion) {
        self.regionRangingStatus.removeValueForKey(beaconRegion.identifier)
        manager.wrappedStartRangingBeaconsInRegion(beaconRegion)
    }
    
    public func resumeRangingAllBeacons(manager:Wrapper) {
        for beaconRegion in manager.beaconRegions {
            self.regionRangingStatus[beaconRegion.identifier] = true
            manager.wrappedStartRangingBeaconsInRegion(beaconRegion)
        }
    }
    
    public func pauseRangingAllBeacons(manager:Wrapper) {
        for beaconRegion in manager.beaconRegions {
            self.regionRangingStatus[beaconRegion.identifier] = false
            manager.wrappedStopRangingBeaconsInRegion(beaconRegion)
        }
    }
    
    public func stopRangingAllBeacons(manager:Wrapper) {
        for beaconRegion in manager.beaconRegions {
            self.stopRangingBeaconsInRegion(manager, beaconRegion:beaconRegion)
        }
    }
    
    // CLLocationManagerDelegate
    public func didRangeBeacons(beacons:[Wrapper.WrappedBeaconRegion.WrappedBeacon], region:Wrapper.WrappedBeaconRegion) {
        Logger.debug(message:"region identifier = \(region.identifier)")
        region.beaconPromise.success(beacons)
    }
    
    public func didFailRangingBeaconsForRegion(region:Wrapper.WrappedBeaconRegion, error:NSError!) {
        Logger.debug(message:"region identifier \(region.identifier)")
        region.beaconPromise.failure(error)
    }

}
// BeaconManagerImpl
/////////////////////////////////////////////

public class BeaconManager : RegionManager, BeaconManagerWrappable {
    
    let beaconImpl = BeaconManagerImpl<BeaconManager>()
    
    // BeaconManagerWrappable
    public var beaconRegions : [BeaconRegion] {
        return self.configuredBeaconRegions.values.array
    }
    
    public func wrappedStartRangingBeaconsInRegion(beaconRegion:BeaconRegion) {
        self.configuredBeaconRegions[beaconRegion.clBeaconRegion] = beaconRegion
        self.clLocationManager.startRangingBeaconsInRegion(beaconRegion.clBeaconRegion)
    }
    
    public func wrappedStopRangingBeaconsInRegion(beaconRegion:BeaconRegion) {
        self.configuredBeaconRegions.removeValueForKey(beaconRegion.clBeaconRegion)
        self.clLocationManager.stopRangingBeaconsInRegion(beaconRegion.clBeaconRegion)
    }

    // BeaconManagerWrappable
    internal var configuredBeaconRegions    : [CLBeaconRegion:BeaconRegion]     = [:]

    public class func isRangingAvailable() -> Bool {
        return CLLocationManager.isRangingAvailable()
    }
    
    public var isRanging : Bool {
        return self.beaconImpl.isRanging
    }
    
    public override init() {
        super.init()
    }

    public override class var sharedInstance : BeaconManager {
        struct Static {
            static let instance = BeaconManager()
        }
        return Static.instance
    }
    
    public func beaconRegion(identifier:String) -> BeaconRegion? {
        let regions = self.configuredBeaconRegions.keys.array.filter{$0.identifier == identifier}
        if let region = regions.first {
            return self.configuredBeaconRegions[region]
        } else {
            return nil
        }
    }

    public func isRangingRegion(identifier:String) -> Bool {
        return self.beaconImpl.isRangingRegion(identifier)
    }

    // control
    public func startRangingBeaconsInRegion(beaconRegion:BeaconRegion, authorization:CLAuthorizationStatus? = nil) -> FutureStream<[Beacon]> {
        if let authorization = authorization {
            return self.beaconImpl.startRangingBeaconsInRegion(self, authorization:authorization, beaconRegion:beaconRegion)
        } else {
            return self.beaconImpl.startRangingBeaconsInRegion(self, authorization:LocationManager.authorizationStatus(), beaconRegion:beaconRegion)
        }
    }

    public func stopRangingBeaconsInRegion(beaconRegion:BeaconRegion) {
        self.beaconImpl.stopRangingBeaconsInRegion(self, beaconRegion:beaconRegion)
    }
    
    public func resumeRangingAllBeacons() {
        self.beaconImpl.resumeRangingAllBeacons(self)
    }
    
    public func pauseRangingAllBeacons() {
        self.beaconImpl.pauseRangingAllBeacons(self)
    }

    public func stopRangingAllBeacons() {
        self.beaconImpl.stopRangingAllBeacons(self)
    }

    public func requestStateForRegion(beaconMonitor:BeaconRegion) {
        self.clLocationManager.requestStateForRegion(beaconMonitor.clRegion)
    }
    
    // CLLocationManagerDelegate
    public func locationManager(_:CLLocationManager!, didRangeBeacons beacons:[AnyObject]!, inRegion region:CLBeaconRegion!) {
        Logger.debug(message: "region identifier \(region.identifier)")
        if let beaconRegion = self.configuredBeaconRegions[region] {
            let bcbeacons = beacons.map{Beacon(clbeacon:($0 as! CLBeacon))}
            beaconRegion._beacons = bcbeacons
            self.beaconImpl.didRangeBeacons(bcbeacons, region:beaconRegion)
        }
    }
    
    public func locationManager(_:CLLocationManager!, rangingBeaconsDidFailForRegion region:CLBeaconRegion!, withError error:NSError!) {
        Logger.debug(message:"region identifier \(region.identifier)")
        if let beaconRegion = self.configuredBeaconRegions[region] {
            self.beaconImpl.didFailRangingBeaconsForRegion(beaconRegion, error:error)
        }
    }
    
}
