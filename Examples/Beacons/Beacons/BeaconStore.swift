//
//  BeaconStore.swift
//  BlueCap
//
//  Created by Troy Stribling on 9/16/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import Foundation
import BlueCapKit

class BeaconStore {
    
    class func getBeacon() -> UUID? {
        return UserDefaults.standard.string(forKey: "beacon").flatMap { UUID(uuidString: $0) }
    }
    
    class func setBeacon(_ uuid: UUID) {
        UserDefaults.standard.set(uuid.uuidString, forKey:"beacon")
    }
    
}
