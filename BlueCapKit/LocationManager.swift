//
//  LocationManager.swift
//  BlueCap
//
//  Created by Troy Stribling on 8/22/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation
import CoreLocation

class LocationManager : NSObject,  CLLocationManagerDelegate {

    class func sharedInstance() -> LocationManager {
        if thisLocationManager == nil {
            thisLocationManager = LocationManager()
        }
        return thisLocationManager!
    }
    
    // CLLocationManagerDelegate
    func locationManagerDidPauseLocationUpdates(_:CLLocationManager!) {
        
    }
    
}

var thisLocationManager : LocationManager?
