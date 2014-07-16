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
    
    let uuid            : CBUUID!
    let name            : String!
    var permissions     : CBAttributePermissions!
    var properties      : CBCharacteristicProperties!
    
    var afterDiscoveredCallback     : ((characteristic:Characteristic) -> ())?
    
    // APPLICATION INTERFACE
    init(uuid:String, name:String) {
        self.uuid = CBUUID.UUIDWithString(uuid)
        self.name = name
        self.permissions = CBAttributePermissions.Readable | CBAttributePermissions.Writeable
        self.properties = CBCharacteristicProperties.Read | CBCharacteristicProperties.Write | CBCharacteristicProperties.Notify
    }
    
    convenience init(uuid:String, name:String, profile:(characteristic:CharacteristicProfile) -> ()) {
        self.init(uuid:uuid, name:name)
        profile(characteristic:self)
    }
    
    func propertyEnabled(property:CBCharacteristicProperties) -> Bool {
        return (self.properties.toRaw() & property.toRaw()) > 0
    }
    
    func permissionEnabled(permission:CBAttributePermissions) -> Bool {
        return (self.permissions.toRaw() & permissions.toRaw()) > 0
    }
    
    // CALLBACKS
    func afterDiscovered(afterDiscoveredCallback:(characteristic:Characteristic) -> ()) {
        self.afterDiscoveredCallback = afterDiscoveredCallback
    }
    
    // INTERNAL INTERFACE
    func stringValues(data:NSData) -> Dictionary<String, String>? {
        return [self.name:data.hexStringValue()]
    }
    
    func anyValue(data:NSData) -> Any? {
        return data
    }
    
    func dataValue(object:Any) -> NSData? {
        return object as? NSData
    }
    
    func dataValue(data:Dictionary<String, String>) -> NSData? {
        if let stringVal = data[self.name] {
            return stringVal.dataFromHexString()
        } else {
            return NSData()
        }
    }
    
}