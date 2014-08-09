//
//  ProfileManager.swift
//  BlueCap
//
//  Created by Troy Stribling on 6/21/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation
import CoreBluetooth

public class ProfileManager {
    
    // INTERNAL
    internal var serviceProfiles = Dictionary<CBUUID, ServiceProfile>()
    
    // PRIVATE
    private init() {
    }
    
    // PUBLIC
    public var services : [ServiceProfile] {
        return Array(self.serviceProfiles.values)
    }
    
    public class func sharedInstance() -> ProfileManager {
        if thisProfileManager == nil {
            thisProfileManager = ProfileManager()
        }
        return thisProfileManager!
    }
    
    public func addService(serviceProfile:ServiceProfile) -> ServiceProfile {
        Logger.debug("ProfileManager#createServiceProfile: name=\(serviceProfile.name), uuid=\(serviceProfile.uuid.UUIDString)")
        self.serviceProfiles[serviceProfile.uuid] = serviceProfile
        return serviceProfile
    }
}

var thisProfileManager : ProfileManager?