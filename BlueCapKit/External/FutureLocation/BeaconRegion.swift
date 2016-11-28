//
//  BeaconRegion.swift
//  BlueCap
//
//  Created by Troy Stribling on 9/14/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import Foundation
import CoreLocation

public class BeaconRegion : Region {
    
    internal let beaconPromise: StreamPromise<[Beacon]>
    
    internal var _beacons = [Beacon]()
    internal let clBeaconRegion: CLBeaconRegion
    
    public var beacons: [Beacon] {
        return self._beacons.sorted() {(b1: Beacon, b2: Beacon) -> Bool in
            switch b1.discoveredAt.compare(b2.discoveredAt as Date) {
            case .orderedSame:
                return true
            case .orderedDescending:
                return false
            case .orderedAscending:
                return true
            }
        }
    }
    
    public var proximityUUID: UUID? {
        return self.clBeaconRegion.proximityUUID
    }
    
    public var major : Int? {
        if let _major = self.clBeaconRegion.major {
            return _major.intValue
        } else {
            return nil
        }
    }
    
    public var minor: Int? {
        if let _minor = self.clBeaconRegion.minor {
            return _minor.intValue
        } else {
            return nil
        }
    }
    
    public var notifyEntryStateOnDisplay: Bool {
        get {
            return self.clBeaconRegion.notifyEntryStateOnDisplay
        }
        set {
            self.clBeaconRegion.notifyEntryStateOnDisplay = newValue
        }
    }
    
    public init(region: CLBeaconRegion, capacity: Int = Int.max) {
        self.clBeaconRegion = region
        self.beaconPromise = StreamPromise<[Beacon]>(capacity: capacity)
        super.init(region:region, capacity: capacity)
        self.notifyEntryStateOnDisplay = true
    }
    
    public convenience init(proximityUUID: UUID, identifier: String, capacity: Int = Int.max) {
        self.init(region:CLBeaconRegion(proximityUUID: proximityUUID, identifier: identifier), capacity: capacity)
    }

    public convenience init(proximityUUID: UUID, identifier: String, major: UInt16, capacity: Int = Int.max) {
        let beaconMajor : CLBeaconMajorValue = major
        let beaconRegion = CLBeaconRegion(proximityUUID: proximityUUID, major: beaconMajor, identifier: identifier)
        self.init(region: beaconRegion, capacity: capacity)
    }

    public convenience init(proximityUUID: UUID, identifier: String, major: UInt16, minor: UInt16, capacity: Int = Int.max) {
        let beaconMinor : CLBeaconMinorValue = minor
        let beaconMajor : CLBeaconMajorValue = major
        let beaconRegion = CLBeaconRegion(proximityUUID:proximityUUID, major:beaconMajor, minor:beaconMinor, identifier:identifier)
        self.init(region:beaconRegion, capacity:capacity)
    }
    
    public override class func isMonitoringAvailableForClass() -> Bool {
        return CLLocationManager.isMonitoringAvailable(for: CLBeaconRegion.self)
    }

    public func peripheralDataWithMeasuredPower(_ measuredPower: Int?) -> [String : AnyObject] {
        let power: [NSObject : AnyObject]
        if let measuredPower = measuredPower {
            power = self.clBeaconRegion.peripheralData(withMeasuredPower: NSNumber(value: measuredPower)) as [NSObject:AnyObject]
        } else {
            power = self.clBeaconRegion.peripheralData(withMeasuredPower: nil) as [NSObject : AnyObject]
        }

        var result = [String : AnyObject]()
        for key in power.keys {
            if let keyPower = power[key], let key = key as? String {
                result[key] = keyPower
            }
        }
        return result
    }

}
