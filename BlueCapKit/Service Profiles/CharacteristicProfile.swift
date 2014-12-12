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
    
    // PUBLIC
    public let uuid                     : CBUUID
    public let name                     : String
    public var permissions              : CBAttributePermissions
    public var properties               : CBCharacteristicProperties
    public var initialValue             : NSData?

    internal var afterDiscoveredPromise : StreamPromise<Characteristic>!

    public var discreteStringValues : [String] {
        return []
    }
    
    public var afterDiscovered : FutureStream<Characteristic> {
        self.afterDiscoveredPromise = StreamPromise<Characteristic>()
        return self.afterDiscoveredPromise.futureStream
    }

    public init(uuid:String, name:String, initializer:((characteristicProfile:CharacteristicProfile) -> ())? = nil) {
        self.uuid = CBUUID(string:uuid)
        self.name = name
        self.permissions = CBAttributePermissions.Readable | CBAttributePermissions.Writeable
        self.properties = CBCharacteristicProperties.Read | CBCharacteristicProperties.Write | CBCharacteristicProperties.Notify
        if let runInializer = initializer {
            runInializer(characteristicProfile:self)
        }
    }
    
    public func propertyEnabled(property:CBCharacteristicProperties) -> Bool {
        return (self.properties.rawValue & property.rawValue) > 0
    }
    
    public func permissionEnabled(permission:CBAttributePermissions) -> Bool {
        return (self.permissions.rawValue & permission.rawValue) > 0
    }
        
    public func stringValues(data:NSData) -> Dictionary<String, String>? {
        return [self.name:data.hexStringValue()]
    }
    
    public func anyValue(data:NSData) -> Any? {
        return data
    }
    
    public func dataFromStringValue(data:Dictionary<String, String>) -> NSData? {
        if let stringVal = data[self.name] {
            return stringVal.dataFromHexString()
        } else {
            return NSData()
        }
    }

    public func dataFromAnyValue(object:Any) -> NSData? {
        return object as? NSData
    }
    
}