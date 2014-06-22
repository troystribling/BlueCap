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
    
    var serializeNamedObjectCallback    : ((obejctName:String, data:AnyObject) -> NSData)?
    var serializeObjectCallback         : ((data:AnyObject) -> NSData)?
    var serializeStringCallback         : ((data:Dictionary<String, String>) -> NSData)?
    var deserializeDataCallback         : ((data:NSData) -> Dictionary<String, AnyObject>)?
    var stringValueCallback             : ((data:Dictionary<String, AnyObject>) -> Dictionary<String, String>)?
    var afterDiscoveredCallback         : ((characteristic:Characteristic) -> ())?
    
    var valueObjects            = Dictionary<String, AnyObject>()
    
    // APPLICATION INTERFACE
    init(uuid:String, name:String, profile:(characteristic:CharacteristicProfile) -> ()) {
        self.uuid = CBUUID.UUIDWithString(uuid)
        self.name = name
        profile(characteristic:self)
    }
    
    func setValue(objectValue:AnyObject, name:String) {
        self.valueObjects[name] = objectValue
    }
    
    func serializeNamedObject(serializeNamedObjectCallback:(objectName:String, data:AnyObject) -> NSData) {
        self.serializeNamedObjectCallback = serializeNamedObjectCallback
    }
    
    func serializeObject(serializeObjectCallback:(data:AnyObject) -> NSData) {
        self.serializeObjectCallback = serializeObjectCallback
    }
    
    func serializeString(serializeStringCallback:(data:Dictionary<String, String>) -> NSData) {
        self.serializeStringCallback = serializeStringCallback
    }
    
    func deserializeData(deserializeDataCallback:(data:NSData) -> Dictionary<String, AnyObject>) {
        self.deserializeDataCallback = deserializeDataCallback
    }
    
    func stringValue(stringValueCallback:(data:(Dictionary<String, AnyObject>) -> Dictionary<String, String>)) {
        self.stringValueCallback = stringValueCallback
    }
    
    func afterDiscovered(afterDiscoveredCallback:(characteristic:Characteristic) -> ()) {
        self.afterDiscoveredCallback = afterDiscoveredCallback
    }
}