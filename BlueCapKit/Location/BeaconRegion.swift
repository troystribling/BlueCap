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
    
    internal var _beacons       = [Beacon]()
    internal var beaconPromise  : StreamPromise<[Beacon]>

    internal  let clBeaconRegion : CLBeaconRegion
    
    public var beacons : [Beacon] {
        return sorted(self._beacons, {(b1:Beacon, b2:Beacon) -> Bool in
            switch b1.discoveredAt.compare(b2.discoveredAt) {
            case .OrderedSame:
                return true
            case .OrderedDescending:
                return false
            case .OrderedAscending:
                return true
            }
        })
    }
    
    public var proximityUUID : NSUUID? {
        return self.clBeaconRegion.proximityUUID
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
    
    internal init(region:CLBeaconRegion, capacity:Int? = nil) {
        self.clBeaconRegion = region
        if let capacity = capacity {
            self.beaconPromise = StreamPromise<[Beacon]>(capacity:capacity)
        } else {
            self.beaconPromise = StreamPromise<[Beacon]>()
        }
        super.init(region:region, capacity:capacity)
        self.notifyEntryStateOnDisplay = true
    }
    
    public convenience init(proximityUUID:NSUUID, identifier:String, capacity:Int? = nil) {
        self.init(region:CLBeaconRegion(proximityUUID:proximityUUID, identifier:identifier), capacity:capacity)
    }

    public convenience init(proximityUUID:NSUUID, identifier:String, major:UInt16, capacity:Int? = nil) {
        let beaconMajor : CLBeaconMajorValue = major
        let beaconRegion = CLBeaconRegion(proximityUUID:proximityUUID, major:beaconMajor, identifier:identifier)
        self.init(region:beaconRegion, capacity:capacity)
    }

    public convenience init(proximityUUID:NSUUID, identifier:String, major:UInt16, minor:UInt16, capacity:Int? = nil) {
        let beaconMinor : CLBeaconMinorValue = minor
        let beaconMajor : CLBeaconMajorValue = major
        let beaconRegion = CLBeaconRegion(proximityUUID:proximityUUID, major:beaconMajor, minor:beaconMinor, identifier:identifier)
        self.init(region:beaconRegion, capacity:capacity)
    }
    
    public func peripheralDataWithMeasuredPower(measuredPower:Int? = nil) -> [NSObject:AnyObject] {
        if let measuredPower = measuredPower {
            let dict = self.clBeaconRegion.peripheralDataWithMeasuredPower(NSNumber(integer:measuredPower)) as NSDictionary
            return dict as! [NSObject:AnyObject]
        } else {
            let dict = self.clBeaconRegion.peripheralDataWithMeasuredPower(nil) as NSDictionary
            return dict as! [NSObject:AnyObject]
        }
    }

}
