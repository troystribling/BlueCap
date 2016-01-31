//
//  BCProfileManager.swift
//  BlueCap
//
//  Created by Troy Stribling on 6/21/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import Foundation
import CoreBluetooth

public class BCProfileManager {
    
    // INTERNAL
    internal var serviceProfiles = [CBUUID: BCServiceProfile]()
    
    // PRIVATE
    private init() {
    }
    
    // PUBLIC
    public var services: [BCServiceProfile] {
        return Array(self.serviceProfiles.values)
    }
    
    public var service: [CBUUID: BCServiceProfile] {
        return self.serviceProfiles
    }

    public class var sharedInstance: BCProfileManager {
        struct StaticInstance {
            static var onceToken: dispatch_once_t  = 0
            static var instance: BCProfileManager?   = nil
        }
        dispatch_once(&StaticInstance.onceToken) {
            StaticInstance.instance = BCProfileManager()
        }
        return StaticInstance.instance!
    }
    
    public func addService(serviceProfile: BCServiceProfile) -> BCServiceProfile {
        Logger.debug("name=\(serviceProfile.name), uuid=\(serviceProfile.uuid.UUIDString)")
        self.serviceProfiles[serviceProfile.uuid] = serviceProfile
        return serviceProfile
    }
    
}
