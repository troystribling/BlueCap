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
        return self.serviceProfiles.values.array
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
    
    public func service(uuid:CBUUID) -> ServiceProfile? {
        return self.serviceProfiles[uuid]
    }

}

var thisProfileManager : ProfileManager?