//
//  CharacteristicProfile.swift
//  BlueCap
//
//  Created by Troy Stribling on 6/21/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation
import CoreBluetooth

class CharacteristicProfile<T> {
    
    let uuid : CBUUID!
    let name : String!
    
    var serializeObjectCallback         : ((obejct:T) -> NSData)?
    var serializeStringCallback         : ((obejct:Dictionary<String, String>) -> NSData)?
    var deserializeDataCallback         : ((data:NSData) -> T)?
    var stringValueCallback             : ((data:T) -> Dictionary<String, String>)?
    var afterDiscoveredCallback         : ((characteristic:Characteristic) -> ())?
    
    // APPLICATION INTERFACE
    init(uuid:String, name:String, profile:(characteristic:CharacteristicProfile) -> ()) {
        self.uuid = CBUUID.UUIDWithString(uuid)
        self.name = name
        profile(characteristic:self)
    }

    func serializeObject(serializeObjectCallback:(obejct:T) -> NSData) {
        self.serializeObjectCallback = serializeObjectCallback
    }
    
    func serializeString(serializeStringCallback:(data:Dictionary<String, String>) -> NSData) {
        self.serializeStringCallback = serializeStringCallback
    }
    
    func deserializeData(deserializeDataCallback:(data:NSData) -> T) {
        self.deserializeDataCallback = deserializeDataCallback
    }
    
    func stringValue(stringValueCallback:(data:(T) -> Dictionary<String, String>)) {
        self.stringValueCallback = stringValueCallback
    }
    
    func afterDiscovered(afterDiscoveredCallback:(characteristic:Characteristic) -> ()) {
        self.afterDiscoveredCallback = afterDiscoveredCallback
    }

    //
    // INTERNAL INTERFACE
    func deserializeData(data:NSData) -> T {
    }
    
}