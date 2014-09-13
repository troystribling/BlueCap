//
//  ServiceProfile.swift
//  BlueCap
//
//  Created by Troy Stribling on 6/21/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation
import CoreBluetooth

public class ServiceProfile {
    
    // INTERNAL
    internal var characteristicProfiles = Dictionary<CBUUID, CharacteristicProfile>()

    // PUBLIC
    public let uuid : CBUUID
    public let name : String
    public var tag  = "Miscellaneous"
    
    public var characteristics : [CharacteristicProfile] {
        return self.characteristicProfiles.values.array
    }
    
    public init(uuid:String, name:String, profile:(service:ServiceProfile) -> ()) {
        self.name = name
        self.uuid = CBUUID.UUIDWithString(uuid)
        profile(service:self)
    }
    
    public func addCharacteristic( characteristicProfile:CharacteristicProfile) {
        Logger.debug("ServiceProfile#createCharateristic: name=\(characteristicProfile.name), uuid=\(characteristicProfile.uuid.UUIDString)")
        self.characteristicProfiles[characteristicProfile.uuid] = characteristicProfile
    }
    
}