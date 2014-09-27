//
//  CLProximityExtension.swift
//  BlueCap
//
//  Created by Troy Stribling on 9/27/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation
import CoreLocation

public extension CLProximity {
    
    var stringValue : String {
        switch self {
        case .Unknown:
            return "Unknown"
        case .Immediate:
            return "Immediate"
        case .Near:
            return "Near"
        case .Far:
            return "Far"
        }
    }
}
