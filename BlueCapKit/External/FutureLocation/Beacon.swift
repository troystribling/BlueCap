//
//  Beacon.swift
//  BlueCap
//
//  Created by Troy Stribling on 9/19/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import Foundation
import CoreLocation

// MARK: - CLBeaconInjectable -
public protocol CLBeaconInjectable {
    var proximityUUID: UUID { get }
    var major: NSNumber { get }
    var minor: NSNumber { get }
    var proximity: CLProximity { get }
    var accuracy: CLLocationAccuracy { get }
    var rssi: Int { get }
}

extension CLBeacon: CLBeaconInjectable {}

// MARK: - Beacon -
public class Beacon {
    
    fileprivate let clBeacon: CLBeaconInjectable
    fileprivate let _discoveredAt = NSDate()
    
    public var discoveredAt : NSDate {
        return self._discoveredAt
    }
    
    internal init(clBeacon: CLBeaconInjectable) {
        self.clBeacon = clBeacon
    }
    
    public var major : Int {
        return self.clBeacon.major.intValue
    }
    
    public var minor : Int {
        return self.clBeacon.minor.intValue
    }
    
    public var proximityUUID : UUID {
        return self.clBeacon.proximityUUID
    }
    
    public var proximity : CLProximity {
        return self.clBeacon.proximity
    }
    
    public var accuracy : CLLocationAccuracy {
        return self.clBeacon.accuracy
    }
    
    public var rssi : Int {
        return self.clBeacon.rssi
    }
}
