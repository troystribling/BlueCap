//
//  RegionMonitor.swift
//  BlueCap
//
//  Created by Troy Stribling on 8/24/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation
import CoreLocation

public class RegionMonitor {
    
    private var _region : CLRegion
    
    public var enterRegion              : (() -> ())?
    public var exitRegion               : (() -> ())?
    public var startMonitoringRegion    : (() -> ())?
    public var regionStateChanged       : ((state:CLRegionState) -> ())?
    public var errorMonitoringRegion    : ((error:NSError!) -> ())?
    
    public var region : CLRegion {
        return self._region
    }
    
    public init(region:CLRegion, initializer:((regionMonitor:RegionMonitor) -> ())? = nil) {
        self._region = region
        if let initializer = initializer {
            initializer(regionMonitor:self)
        }
    }
}

