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
    
    func serviceProfile(uuid:String, name:String, profile:(service:ServiceProfile) -> ()) -> ServiceProfile {
        Logger.debug("ProfileManager#createServiceProfile: name=\(name), uuid=\(uuid)")
        let serviceProfile = ServiceProfile(uuid:uuid, name:name, profile:profile)
        self.serviceProfiles[CBUUID.UUIDWithString(uuid)] = serviceProfile
        return serviceProfile
    }
}

var thisProfileManager : ProfileManager?