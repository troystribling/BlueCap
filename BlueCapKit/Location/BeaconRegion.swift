//
//  BeaconRegion.swift
//  BlueCap
//
//  Created by Troy Stribling on 9/14/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import UIKit
import CoreLocation

public class BeaconRegion : Region {
    
    internal var _beacons   = [Beacon]()
    
    public var rangedBeacons            : ((beacons:[Beacon]) -> ())?
    public var errorRangingBeacons      : ((error:NSError!) -> ())?

    internal var clBeaconRegion : CLBeaconRegion {
        return self._region as CLBeaconRegion
    }
    
    public var proximityUUID : NSUUID! {
        return (self._region as CLBeaconRegion).proximityUUID
    }
    
    public var major : Int? {
        if let _major = self.clBeaconRegion.major {
            return _major.integerValue
        } else {
            return nil
        }
    }
    
    public var minor : Int? {
        if let _minor = self.clBeaconRegion.minor {
            return _minor.integerValue
        } else {
            return nil
        }
    }
    
    public var notifyEntryStateOnDisplay : Bool {
        get {
            return self.clBeaconRegion.notifyEntryStateOnDisplay
        }
        set {
            self.clBeaconRegion.notifyEntryStateOnDisplay = newValue
        }
    }
    
    internal init(region:CLRegion, initializer:((beaconRegion:BeaconRegion) -> ())? = nil) {
        super.init(region:region)
        if let initializer = initializer {
            initializer(beaconRegion:self)
        }
    }
    
    public convenience init(proximityUUID:NSUUID, identifier:String, initializer:((beaconRegion:BeaconRegion) -> ())? = nil) {
        let beaconRegion = CLBeaconRegion(proximityUUID:proximityUUID, identifier:identifier)
        self.init(region:beaconRegion, initializer:initializer)
    }

    public convenience init(proximityUUID:NSUUID, identifier:String, major:CLBeaconMajorValue, initializer:((beaconMonitor:BeaconRegion) -> ())? = nil) {
        let beaconRegion = CLBeaconRegion(proximityUUID:proximityUUID, major:major, identifier:identifier)
        self.init(region:beaconRegion, initializer:initializer)
    }

    public convenience init(proximityUUID:NSUUID, identifier:String, major:CLBeaconMajorValue, minor:CLBeaconMinorValue, initializer:((beaconRegion:BeaconRegion) -> ())? = nil) {
        let beaconRegion = CLBeaconRegion(proximityUUID:proximityUUID, major:major, minor:minor, identifier:identifier)
        self.init(region:beaconRegion, initializer:initializer)
    }
    
    public func peripheralDataWithMeasuredPower(measuredPower:Int? = nil) -> NSMutableDictionary {
        if let measuredPower = measuredPower {
            return self.clBeaconRegion.peripheralDataWithMeasuredPower(NSNumber(integer:measuredPower))
        } else {
            return self.clBeaconRegion.peripheralDataWithMeasuredPower(nil)
        }
    }

}
