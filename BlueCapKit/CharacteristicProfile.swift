//
//  CharacteristicProfile.swift
//  BlueCap
//
//  Created by Troy Stribling on 6/21/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation
import CoreBluetooth

public class CharacteristicProfile {
    
    // INTERNAL
    internal var afterDiscoveredCallback : ((characteristic:Characteristic) -> ())?

    // PUBLIC
    public let uuid                     : CBUUID!
    public let name                     : String!
    public var permissions              : CBAttributePermissions!
    public var properties               : CBCharacteristicProperties!
    public var initialValue             : NSData?
    
    public var discreteStringValues : [String] {
        return []
    }
    
    public init(uuid:String, name:String, initializer:((characteristicProfile:CharacteristicProfile) -> ())? = nil) {
        self.uuid = CBUUID.UUIDWithString(uuid)
        self.name = name
        self.permissions = CBAttributePermissions.Readable | CBAttributePermissions.Writeable
        self.properties = CBCharacteristicProperties.Read | CBCharacteristicProperties.Write | CBCharacteristicProperties.Notify
        if let runInializer = initializer {
            runInializer(characteristicProfile:self)
        }
    }
    
    public func propertyEnabled(property:CBCharacteristicProperties) -> Bool {
        return (self.properties.toRaw() & property.toRaw()) > 0
    }
    
    public func permissionEnabled(permission:CBAttributePermissions) -> Bool {
        return (self.permissions.toRaw() & permissions.toRaw()) > 0
    }
    
    public func afterDiscovered(afterDiscoveredCallback:(characteristic:Characteristic) -> ()) {
        self.afterDiscoveredCallback = afterDiscoveredCallback
    }
    
    // INTERNAL
    internal func stringValues(data:NSData) -> Dictionary<String, String>? {
        return [self.name:data.hexStringValue()]
    }
    
    internal func anyValue(data:NSData) -> Any? {
        return data
    }
    
    internal func dataValue(object:Any) -> NSData? {
        return object as? NSData
    }
    
    internal func dataValue(data:Dictionary<String, String>) -> NSData? {
        if let stringVal = data[self.name] {
            return stringVal.dataFromHexString()
        } else {
            return NSData()
        }
    }
    
}