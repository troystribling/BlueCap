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
    
    private static var __once: () = {
            StaticInstance.instance = ProfileManager()
        }()
    
    // INTERNAL
    internal var _services = [CBUUID: ServiceProfile]()
    
    // PRIVATE
    fileprivate init() {
    }
    
    // PUBLIC
    public var services: [CBUUID: ServiceProfile] {
        return self._services
    }

    public class var sharedInstance: ProfileManager {
        struct StaticInstance {
            static var onceToken: Int  = 0
            static var instance: ProfileManager?   = nil
        }
        _ = ProfileManager.__once
        return StaticInstance.instance!
    }
    
    public func addService(_ serviceProfile: ServiceProfile) {
        Logger.debug("name=\(serviceProfile.name), UUID=\(serviceProfile.UUID.uuidString)")
        self._services[serviceProfile.UUID] = serviceProfile
    }
    
}
