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
    
    var serializeObjectCallback         : ((obejct:Any) -> NSData)?
    var serializeStringCallback         : ((obejct:Dictionary<String, String>) -> NSData)?
    var deserializeDataCallback         : ((data:NSData) -> Any)?
    var stringValueCallback             : ((data:Any) -> Dictionary<String, String>)?
    
    // APPLICATION INTERFACE
    func serializeObject(serializeObjectCallback:(obejct:Any) -> NSData) {
        self.serializeObjectCallback = serializeObjectCallback
    }
    
    func serializeString(serializeStringCallback:(data:Dictionary<String, String>) -> NSData) {
        self.serializeStringCallback = serializeStringCallback
    }
    
    func deserializeData(deserializeDataCallback:(data:NSData) -> Any) {
        self.deserializeDataCallback = deserializeDataCallback
    }
    
    func stringValue(stringValueCallback:(data:(Any) -> Dictionary<String, String>)) {
        self.stringValueCallback = stringValueCallback
    }
    
    // INTERNAL INTERFACE
    
}