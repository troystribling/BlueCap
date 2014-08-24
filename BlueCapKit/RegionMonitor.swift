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
    
    public var enterRegion              : (() -> ())?
    public var exitRegion               : (() -> ())?
    public var startMonitoringRegion    : (() -> ())?
    public var regionStateChanged       : ((state:CLRegionState) -> ())?
    public var errorMonitoringRegion    : ((error:NSError!) -> ())?
    
    init(initializer:(monitor:RegionMonitor) -> ()) {
        initializer(monitor:self)
    }
}

