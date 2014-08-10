//
//  MutableCharacteristic.swift
//  BlueCap
//
//  Created by Troy Stribling on 8/9/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation
import CoreBluetooth

public class MutableCharacteristic : NSObject {
    
    // PRIVATE
    private let profile : CharacteristicProfile!
    
    // INTERNAL
    internal let cbMutableChracteristic : CBMutableCharacteristic!
    
    // PUBLIC
    init(profile:CharacteristicProfile) {
        super.init()
        self.profile = profile
        self.cbMutableChracteristic = CBMutableCharacteristic(type:profile.uuid, properties:profile.properties, value:profile.initialValue, permissions:profile.permissions)
    }
    
}