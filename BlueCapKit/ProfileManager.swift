//
//  ProfileManager.swift
//  BlueCap
//
//  Created by Troy Stribling on 6/21/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation
import CoreBluetooth

class ProfileManager {
    
    var serviceProfiles = Dictionary<CBUUID, ServiceProfile>()
    
    var services : ServiceProfile[] {
        return Array(self.serviceProfiles.values)
    }
    
    // APPLICATION INTERFACE
    class func sharedInstance() -> ProfileManager {
        if !thisProfileManager {
            thisProfileManager = ProfileManager()
        }
        return thisProfileManager!
    }
    
    func addService(serviceProfile:ServiceProfile) -> ServiceProfile {
        Logger.debug("ProfileManager#createServiceProfile: name=\(serviceProfile.name), uuid=\(serviceProfile.uuid.UUIDString)")
        self.serviceProfiles[serviceProfile.uuid] = serviceProfile
        return serviceProfile
    }
}

var thisProfileManager : ProfileManager?