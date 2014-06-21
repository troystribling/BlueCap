//
//  CharacteristicProfile.swift
//  BlueCap
//
//  Created by Troy Stribling on 6/21/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation
import CoreBluetooth

class CharacteristicProfile {
    
    let uuid : CBUUID!
    let name : String!
    
    init(uuid:String, name:String, profile:(characteristic:CharacteristicProfile) -> ()) {
        self.uuid = CBUUID.UUIDWithString(uuid)
        self.name = name
        profile(characteristic:self)
    }
}