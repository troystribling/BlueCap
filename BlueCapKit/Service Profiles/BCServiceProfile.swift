//
//  BCServiceProfile.swift
//  BlueCap
//
//  Created by Troy Stribling on 6/21/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import Foundation
import CoreBluetooth

// MARK: - BCServiceProfile -
public class BCServiceProfile {
    
    internal var characteristicProfiles = [CBUUID: BCCharacteristicProfile]()

    public let UUID: CBUUID
    public let name: String
    public let tag: String
    
    public var characteristics: [BCCharacteristicProfile] {
        return Array(self.characteristicProfiles.values)
    }
    
    public var characteristic: [CBUUID: BCCharacteristicProfile] {
        return self.characteristicProfiles
    }
    
    public init(UUID: String, name: String, tag: String = "Miscellaneous") {
        self.name = name
        self.UUID = CBUUID(string:UUID)
        self.tag = tag
    }
    
    public convenience init(UUID:String) {
        self.init(UUID:UUID, name:"Unknown")
    }

    public func addCharacteristic(characteristicProfile: BCCharacteristicProfile) {
        BCLogger.debug("name=\(characteristicProfile.name), uuid=\(characteristicProfile.UUID.UUIDString)")
        self.characteristicProfiles[characteristicProfile.UUID] = characteristicProfile
    }
    
}

public class BCConfiguredServiceProfile<Config: BCServiceConfigurable>: BCServiceProfile {
    
    public init() {
        super.init(UUID: Config.UUID, name: Config.name, tag: Config.tag)
    }
    
}