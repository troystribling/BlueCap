//
//  Region.swift
//  BlueCap
//
//  Created by Troy Stribling on 8/24/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import Foundation
import CoreLocation

let DEFAULT_REGION_RADIUS = 100.0

public enum RegionState {
    case Start, Inside, Outside
}

public class Region {
    
    // RegionWrappable
    public var regionPromise  : StreamPromise<RegionState>
    
    public var identifier : String {
        return self.clRegion.identifier
    }
    // RegionWrappable
    
    internal let clRegion : CLRegion
    
    public var notifyOnEntry : Bool {
        get {
            return self.clRegion.notifyOnEntry
        }
        set {
            self.clRegion.notifyOnEntry = newValue
        }
    }
    
    public var notifyOnExit : Bool {
        get {
            return self.clRegion.notifyOnExit
        }
        set {
            self.clRegion.notifyOnExit = newValue
        }
    }
    
    internal init(region:CLRegion, capacity:Int? = nil) {
        self.clRegion = region
        if let capacity = capacity {
            self.regionPromise = StreamPromise<RegionState>(capacity:capacity)
        } else {
            self.regionPromise = StreamPromise<RegionState>()
        }
    }

    public class func isMonitoringAvailableForClass() -> Bool {
        return CLLocationManager.isMonitoringAvailableForClass(CLRegion)
    }

}

