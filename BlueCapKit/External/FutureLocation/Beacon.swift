//
//  Beacon.swift
//  BlueCap
//
//  Created by Troy Stribling on 9/19/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import Foundation
import CoreLocation

public class Beacon : BeaconWrappable {
    
    private let clbeacon        : CLBeacon
    private let _discoveredAt   = NSDate()
    
    public var discoveredAt : NSDate {
        return self._discoveredAt
    }
    
    internal init(clbeacon:CLBeacon) {
        self.clbeacon = clbeacon
    }
    
    public var major : Int {
        return self.clbeacon.major.integerValue
    }
    
    public var minor : Int {
        return self.clbeacon.minor.integerValue
    }
    
    public var proximityUUID : NSUUID {
        return self.clbeacon.proximityUUID
    }
    
    public var proximity : CLProximity {
        return self.clbeacon.proximity
    }
    
    public var accuracy : CLLocationAccuracy {
        return self.clbeacon.accuracy
    }
    
    public var rssi : Int {
        return self.clbeacon.rssi
    }
}
