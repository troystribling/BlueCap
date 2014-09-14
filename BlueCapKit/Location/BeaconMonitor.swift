//
//  BeaconMonitor.swift
//  BlueCap
//
//  Created by Troy Stribling on 9/14/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import UIKit
import CoreLocation

public class BeaconMonitor {
    
    private let _region : CLBeaconRegion
    
    public var rangedBeacons            : ((beacons:[CLBeacon]) -> ())?
    public var errorRangingBeacons      : ((error:NSError!) -> ())?
    public var regionStateChanged       : ((state:CLRegionState) -> ())?

    internal var region : CLBeaconRegion {
        return self._region
    }

    public var proximityUUID : NSUUID! {
        return self._region.proximityUUID
    }
    
    public var major : Int? {
        if let _major = self._region.major {
            return _major.integerValue
        } else {
            return nil
        }
    }
    
    public var minor : Int? {
        if let _minor = self._region.minor {
            return _minor.integerValue
        } else {
            return nil
        }
    }
    
    public var notifyEntryStateOnDisplay : Bool {
        get {
            return self._region.notifyEntryStateOnDisplay
        }
        set {
            self._region.notifyEntryStateOnDisplay = newValue
        }
    }
    
    public init(region:CLBeaconRegion, initializer:((beaconMonitor:BeaconMonitor) -> ())?) {
        self._region = region
        if let initializer = initializer {
            initializer(beaconMonitor:self)
        }
    }
    
    public convenience init(proximityUUID:NSUUID, identifier:String, initializer:((beaconMonitor:BeaconMonitor) -> ())?) {
        let beaconRegion = CLBeaconRegion(proximityUUID:proximityUUID, identifier:identifier)
        self.init(region:beaconRegion, initializer)
    }

    public convenience init(proximityUUID:NSUUID, identifier:String, major:CLBeaconMajorValue, initializer:((beaconMonitor:BeaconMonitor) -> ())?) {
        let beaconRegion = CLBeaconRegion(proximityUUID:proximityUUID, major:major, identifier:identifier)
        self.init(region:beaconRegion, initializer)
    }

    public convenience init(proximityUUID:NSUUID, identifier:String, major:CLBeaconMajorValue, minor:CLBeaconMinorValue, initializer:((beaconMonitor:BeaconMonitor) -> ())?) {
        let beaconRegion = CLBeaconRegion(proximityUUID:proximityUUID, major:major, minor:minor, identifier:identifier)
        self.init(region:beaconRegion, initializer)
    }
    
    public func peripheralDataWithMeasuredPower(measuredPower:Int? = nil) -> NSMutableDictionary {
        if let measuredPower = measuredPower {
            return self._region.peripheralDataWithMeasuredPower(NSNumber(integer:measuredPower))
        } else {
            return self._region.peripheralDataWithMeasuredPower(nil)
        }
    }

}
