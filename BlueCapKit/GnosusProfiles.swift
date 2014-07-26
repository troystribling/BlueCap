//
//  GnosusProfiles.swift
//  BlueCap
//
//  Created by Troy Stribling on 7/25/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation
import CoreBluetooth
import BlueCapKit

struct Gnosus {
  
    //***************************************************************************************************
    // Hello World Service
    //***************************************************************************************************
    struct HelloWorld {
        static let uuid = "2f0a0000-69aa-f316-3e78-4194989a6c1a"
        static let name = "Gnosus Hello World"
        struct Greeting {
            static let uuid = "2f0a0001-69aa-f316-3e78-4194989a6c1a"
            static let name = "Hello World Greeting"
        }
        struct UpdatePeriod {
            static let uuid = "2f0a0002-69aa-f316-3e78-4194989a6c1a"
            static let name = "Hello World Update Period"
        }
    }

    //***************************************************************************************************
    // Location Service
    //***************************************************************************************************
    struct Location {
        static let uuid = "2f0a0001-69aa-f316-3e78-4194989a6c1a"
        static let name = "Gnosus Location"
        struct LatitudeAndLongitude {
            static let uuid = "2f0a0017-69aa-f316-3e78-4194989a6c1a"
            static let name = "Location Lattitude and Longitude"
        }
    }

    //***************************************************************************************************
    // Epoc Time Service
    //***************************************************************************************************
    struct EpocTime {
        static let uuid = "2f0a0002-69aa-f316-3e78-4194989a6c1a"
        static let name = "Gnosus Epoc Time"
        struct Seconds {
            static let uuid = "2f0a0026-69aa-f316-3e78-4194989a6c1a"
            static let name = "Epoc Time Seconds"
        }
    }

}

class GnosusProfiles {
    
    class func create() {
        
        let profileManager = ProfileManager.sharedInstance()
        
    }
}
