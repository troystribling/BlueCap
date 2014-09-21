//
//  Region.swift
//  BlueCap
//
//  Created by Troy Stribling on 8/24/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation
import CoreLocation

let DEFAULT_REGION_RADIUS = 100.0

public class Region {
    
    internal let _region : CLRegion
    
    public var enterRegion              : (() -> ())?
    public var exitRegion               : (() -> ())?
    public var startMonitoringRegion    : (() -> ())?
    public var regionStateChanged       : ((state:CLRegionState) -> ())?
    public var errorMonitoringRegion    : ((error:NSError!) -> ())?
    
    public var idenitifier : String {
        return self._region.identifier
    }
    
    public var notifyOnEntry : Bool {
        get {
            return self._region.notifyOnEntry
        }
        set {
            self._region.notifyOnEntry = newValue
        }
    }
    
    public var notifyOnExit : Bool {
        get {
            return self._region.notifyOnExit
        }
        set {
            self._region.notifyOnExit = newValue
        }
    }
    
    internal var region : CLRegion {
        return self._region
    }
    
    private init(region:CLRegion, initializer:((region:Region) -> ())? = nil) {
        self._region = region
        if let initializer = initializer {
            initializer(region:self)
        }
    }
    
    internal init(region:CLRegion) {
        self._region = region
    }
    
    public convenience init(center:CLLocationCoordinate2D, radius:CLLocationDistance, identifier:String, initializer:((region:Region) -> ())? = nil) {
        let circularRegion = CLCircularRegion(center:center, radius:radius, identifier:identifier)
        self.init(region:circularRegion, initializer:initializer)
    }
    
    public convenience init(center:CLLocationCoordinate2D, identifier:String, initializer:((region:Region) -> ())? = nil) {
        let circularRegion = CLCircularRegion(center:center, radius:DEFAULT_REGION_RADIUS, identifier:identifier)
        self.init(region:circularRegion, initializer:initializer)
    }

}

