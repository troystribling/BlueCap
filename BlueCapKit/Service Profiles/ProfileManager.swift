//
//  ProfileManager.swift
//  BlueCap
//
//  Created by Troy Stribling on 6/21/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import Foundation
import CoreBluetooth

public class ProfileManager {
    
    // INTERNAL
    internal var serviceProfiles = [CBUUID:ServiceProfile]()
    
    // PRIVATE
    private init() {
    }
    
    // PUBLIC
    public var services : [ServiceProfile] {
        return Array(self.serviceProfiles.values)
    }
    
    public var service : [CBUUID:ServiceProfile] {
        return self.serviceProfiles
    }

    public class var sharedInstance : ProfileManager {
        struct StaticInstance {
            static var onceToken : dispatch_once_t  = 0
            static var instance : ProfileManager?   = nil
        }
        dispatch_once(&StaticInstance.onceToken) {
            StaticInstance.instance = ProfileManager()
        }
        return StaticInstance.instance!
    }
    
    public func addService(serviceProfile:ServiceProfile) -> ServiceProfile {
        Logger.debug("name=\(serviceProfile.name), uuid=\(serviceProfile.uuid.UUIDString)")
        self.serviceProfiles[serviceProfile.uuid] = serviceProfile
        return serviceProfile
    }
    
}
