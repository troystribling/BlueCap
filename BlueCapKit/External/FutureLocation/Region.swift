//
//  FLRegion.swift
//  BlueCap
//
//  Created by Troy Stribling on 8/24/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import Foundation
import CoreLocation

let DEFAULT_REGION_RADIUS = 100.0

public enum RegionState {
    case start, inside, outside
}

public class Region {
    
    public let regionPromise  : StreamPromise<RegionState>
    
    public var identifier : String {
        return self.clRegion.identifier
    }

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
    
    public init(region: CLRegion, capacity:Int = Int.max) {
        self.clRegion = region
        self.regionPromise = StreamPromise(capacity: capacity)
    }

    public class func isMonitoringAvailableForClass() -> Bool {
        return CLLocationManager.isMonitoringAvailable(for: CLRegion.self)
    }

}

