//
//  ServiceProfile.swift
//  BlueCap
//
//  Created by Troy Stribling on 6/21/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import Foundation
import CoreBluetooth

// MARK: - ServiceProfile -
public class ServiceProfile {
    
    internal var characteristicProfiles = [CBUUID: CharacteristicProfile]()

    public let UUID: CBUUID
    public let name: String
    public let tag: String
    
    public var characteristics: [CharacteristicProfile] {
        return Array(self.characteristicProfiles.values)
    }
    
    public var characteristic: [CBUUID: CharacteristicProfile] {
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

    public func addCharacteristic(characteristicProfile: CharacteristicProfile) {
        Logger.debug("name=\(characteristicProfile.name), uuid=\(characteristicProfile.UUID.UUIDString)")
        self.characteristicProfiles[characteristicProfile.UUID] = characteristicProfile
    }
    
}

public class ConfiguredServiceProfile<Config: ServiceConfigurable>: ServiceProfile {
    
    public init() {
        super.init(UUID: Config.UUID, name: Config.name, tag: Config.tag)
    }
    
}