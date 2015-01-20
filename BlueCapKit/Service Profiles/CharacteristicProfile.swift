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
    public let permissions              : CBAttributePermissions
    public let properties               : CBCharacteristicProperties
    public var initialValue             : NSData?

    internal var afterDiscoveredPromise : StreamPromise<Characteristic>!

    public var discreteStringValues : [String] {
        return []
    }
    
    public init(uuid:String, name:String,
        permissions:CBAttributePermissions=CBAttributePermissions.Readable | CBAttributePermissions.Writeable,
        properties:CBCharacteristicProperties = CBCharacteristicProperties.Read | CBCharacteristicProperties.Write | CBCharacteristicProperties.Notify) {
        self.uuid = CBUUID(string:uuid)
        self.name = name
        self.permissions = permissions
        self.properties = properties
    }
    
    public func afterDiscovered(capacity:Int?) -> FutureStream<Characteristic> {
        if let capacity = capacity {
            self.afterDiscoveredPromise = StreamPromise<Characteristic>(capacity:capacity)
        } else {
            self.afterDiscoveredPromise = StreamPromise<Characteristic>()
        }
        return self.afterDiscoveredPromise.future
    }

    public func propertyEnabled(property:CBCharacteristicProperties) -> Bool {
        return (self.properties.rawValue & property.rawValue) > 0
    }
    
    public func permissionEnabled(permission:CBAttributePermissions) -> Bool {
        return (self.permissions.rawValue & permission.rawValue) > 0
    }
        
    public func stringValue(data:NSData) -> Dictionary<String, String> {
        return [self.name:data.hexStringValue()]
    }
    
    public func dataFromStringValue(data:Dictionary<String, String>) -> NSData? {
        if let stringVal = data[self.name] {
            return stringVal.dataFromHexString()
        } else {
            return nil
        }
    }
    
}