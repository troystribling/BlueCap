//
//  CircularRegion.swift
//  BlueCap
//
//  Created by Troy Stribling on 10/6/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation
import CoreLocation

public class CircularRegion : Region {

    internal var clCircularRegion : CLCircularRegion {
        return self._region as CLCircularRegion
    }
    
    public var center : CLLocationCoordinate2D {
        return self.clCircularRegion.center
    }

    public var radius : CLLocationDistance {
        return self.clCircularRegion.radius
    }

    internal init(region:CLRegion, initializer:((circularRegion:CircularRegion) -> ())? = nil) {
        super.init(region:region)
        if let initializer = initializer {
            initializer(circularRegion:self)
        }
    }

    public convenience init(center:CLLocationCoordinate2D, radius:CLLocationDistance, identifier:String, initializer:((region:CircularRegion) -> ())? = nil) {
        let circularRegion = CLCircularRegion(center:center, radius:radius, identifier:identifier)
        self.init(region:circularRegion, initializer:initializer)
    }
    
    public convenience init(center:CLLocationCoordinate2D, identifier:String, initializer:((region:CircularRegion) -> ())? = nil) {
        let circularRegion = CLCircularRegion(center:center, radius:DEFAULT_REGION_RADIUS, identifier:identifier)
        self.init(region:circularRegion, initializer:initializer)
    }
    
    public func containsCoordinate(coordinate:CLLocationCoordinate2D) -> Bool {
        return self.clCircularRegion.containsCoordinate(coordinate)
    }
    
}