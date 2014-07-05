//
//  AnyCharacteristicProfile.swift
//  BlueCap
//
//  Created by Troy Stribling on 6/29/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation
import CoreBluetooth

class AnyCharacteristicProfile : CharacteristicProfile {
    
    var serializeCallback               : ((obejct:Any) -> NSData)?
    var deserializeCallback             : ((data:NSData) -> Any)?
    var serializeStringCallback         : ((obejct:Dictionary<String, String>) -> NSData)?
    var stringValueCallback             : ((data:Any) -> Dictionary<String, String>)?
    
    // APPLICATION INTERFACE
    func serialize(serializeCallback:(obejct:Any) -> NSData) {
        self.serializeCallback = serializeCallback
    }
    
    func deserialize(deserializeCallback:(data:NSData) -> Any) {
        self.deserializeCallback = deserializeCallback
    }

    func serializeString(serializeStringCallback:(data:Dictionary<String, String>) -> NSData) {
        self.serializeStringCallback = serializeStringCallback
    }
    
    func stringValue(stringValueCallback:(data:(Any) -> Dictionary<String, String>)) {
        self.stringValueCallback = stringValueCallback
    }
    
    // INTERNAL INTERFACE
    
}