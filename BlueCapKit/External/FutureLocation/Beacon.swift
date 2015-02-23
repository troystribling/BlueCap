//
//  Beacon.swift
//  BlueCap
//
//  Created by Troy Stribling on 9/19/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation
import CoreLocation

public class Beacon {
    
    private let clbeacon        : CLBeacon
    private let _discoveredAt   = NSDate()
    
    public var discoveredAt : NSDate {
        return self._discoveredAt
    }
    
    internal init(clbeacon:CLBeacon) {
        self.clbeacon = clbeacon
    }
    
    public var major : Int? {
        if let major = self.clbeacon.major {
            return major.integerValue
        } else {
            return nil
        }
    }
    
    public var minor : Int? {
        if let minor = self.clbeacon.minor {
            return minor.integerValue
        } else {
            return nil
        }
    }
    
    public var proximityUUID : NSUUID? {
        if let nsuuid = self.clbeacon.proximityUUID {
            return nsuuid
        } else {
            return nil
        }
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
