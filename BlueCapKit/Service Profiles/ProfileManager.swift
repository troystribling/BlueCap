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
    
    public private(set) var services = [CBUUID : ServiceProfile]()

    public func addService(_ serviceProfile: ServiceProfile) {
        Logger.debug("name=\(serviceProfile.name), uuid=\(serviceProfile.uuid.uuidString)")
        self.services[serviceProfile.uuid] = serviceProfile
    }

    public init() {}

}
