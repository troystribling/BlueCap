//
//  ProfileManager.swift
//  BlueCap
//
//  Created by Troy Stribling on 6/21/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation

class ProfileManager {
    
    var serviceProfiles = Dictionary<String, ServiceProfile>()
    
    var services : ServiceProfile[] {
        return Array(self.serviceProfiles.values)
    }
    
    // APPLICATION INTERFACE
    func sharedInstance() -> ProfileManager {
        if !thisProfileManager {
            thisProfileManager = ProfileManager()
        }
        return thisProfileManager!
    }
    
    func createServiceProfile(uuid:String, name:String, profile:(service:ServiceProfile) -> ()) -> ServiceProfile {
        Logger.debug("ProfileManager#createServiceProfile: name=\(name), uuid=\(uuid)")
        let serviceProfile = ServiceProfile(uuid:uuid, name:name, profile:profile)
        self.serviceProfiles[uuid] = serviceProfile
        return serviceProfile
    }
}

var thisProfileManager : ProfileManager?