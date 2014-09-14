//
//  RegionMonitor.swift
//  BlueCap
//
//  Created by Troy Stribling on 8/24/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation
import CoreLocation

let DEFAULT_REGION_RADIUS = 100.0

public class RegionMonitor {
    
    private let _region : CLCircularRegion
    
    public var enterRegion              : (() -> ())?
    public var exitRegion               : (() -> ())?
    public var startMonitoringRegion    : (() -> ())?
    public var regionStateChanged       : ((state:CLRegionState) -> ())?
    public var errorMonitoringRegion    : ((error:NSError!) -> ())?
    
    internal var region : CLCircularRegion {
        return self._region
    }
    
    public init(region:CLCircularRegion, initializer:((regionMonitor:RegionMonitor) -> ())? = nil) {
        self._region = region
        if let initializer = initializer {
            initializer(regionMonitor:self)
        }
    }
    
    public convenience init(center:CLLocationCoordinate2D, radius:CLLocationDistance, identifier:String, initializer:((regionMonitor:RegionMonitor) -> ())? = nil) {
        let circularRegion = CLCircularRegion(center:center, radius:radius, identifier:identifier)
        self.init(region:circularRegion, initializer:initializer)
    }
    
    public convenience init(center:CLLocationCoordinate2D, identifier:String, initializer:((regionMonitor:RegionMonitor) -> ())? = nil) {
        let circularRegion = CLCircularRegion(center:center, radius:DEFAULT_REGION_RADIUS, identifier:identifier)
        self.init(region:circularRegion, initializer:initializer)
    }

}

