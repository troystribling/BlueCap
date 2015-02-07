//
//  CharacteristicProfile.swift
//  BlueCap
//
//  Created by Troy Stribling on 6/21/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation
import CoreBluetooth

// CharacteristicProfile
public class CharacteristicProfile {
    
    public let uuid                     : CBUUID
    public let name                     : String
    public let permissions              : CBAttributePermissions
    public let properties               : CBCharacteristicProperties
    public let initialValue             : NSData?

    internal var afterDiscoveredPromise : StreamPromise<Characteristic>!

    public var stringValues : [String] {
        return []
    }
    
    public init(uuid:String,
                name:String,
                permissions:CBAttributePermissions=CBAttributePermissions.Readable | CBAttributePermissions.Writeable,
                properties:CBCharacteristicProperties = CBCharacteristicProperties.Read | CBCharacteristicProperties.Write | CBCharacteristicProperties.Notify,
                initialValue:NSData? = nil) {
        self.uuid = CBUUID(string:uuid)
        self.name = name
        self.permissions = permissions
        self.properties = properties
        self.initialValue = initialValue
    }
    
    public convenience init(uuid:String) {
        self.init(uuid:uuid, name:"Unknown")
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
        
    public func stringValue(data:NSData) -> [String:String]? {
        return [self.name:data.hexStringValue()]
    }
    
    public func dataFromStringValue(data:[String:String]) -> NSData? {
        return data[self.name].map{$0.dataFromHexString()}
    }
    
}

// RawCharacteristicProfile
public class RawCharacteristicProfile<DeserializedType where DeserializedType:RawDeserializable, DeserializedType:StringDeserializable, DeserializedType:CharacteristicConfigurable> : CharacteristicProfile {
    
    public init() {
        super.init(uuid:DeserializedType.uuid,
            name:DeserializedType.name,
            permissions:DeserializedType.permissions,
            properties:DeserializedType.properties,
            initialValue:DeserializedType.initialValue)
    }
    
    public override var stringValues : [String] {
        return DeserializedType.stringValues
    }
    
    public override func stringValue(data:NSData) -> [String:String]? {
        let value : DeserializedType? = Serde.deserialize(data)
        return value.map{$0.stringValue}
    }
    
    public override func dataFromStringValue(data:Dictionary<String, String>) -> NSData? {
        return DeserializedType(stringValue:data).flatmap{Serde.serialize($0)}
    }
    
}

// RawPairCharacteristicProfile
public class RawPairCharacteristicProfile<DeserializedType where DeserializedType:RawPairDeserializable, DeserializedType:StringDeserializable, DeserializedType:CharacteristicConfigurable> : CharacteristicProfile {
    
    public init() {
        super.init(uuid:DeserializedType.uuid,
            name:DeserializedType.name,
            permissions:DeserializedType.permissions,
            properties:DeserializedType.properties,
            initialValue:DeserializedType.initialValue)
    }
    
    public override var stringValues : [String] {
        return DeserializedType.stringValues
    }
    
    public override func stringValue(data:NSData) -> [String:String]? {
        let value : DeserializedType? = Serde.deserialize(data)
        return value.map{$0.stringValue}
    }
    
    public override func dataFromStringValue(data:[String:String]) -> NSData? {
        return DeserializedType(stringValue:data).flatmap{Serde.serialize($0)}
    }
    
}

// RawArrayCharacteristicProfile
public class RawArrayCharacteristicProfile<DeserializedType where DeserializedType:RawArrayDeserializable, DeserializedType:StringDeserializable, DeserializedType:CharacteristicConfigurable> : CharacteristicProfile {
    
    public init() {
        super.init(uuid:DeserializedType.uuid,
                   name:DeserializedType.name,
                   permissions:DeserializedType.permissions,
                   properties:DeserializedType.properties,
                   initialValue:DeserializedType.initialValue)
    }
    
    public override var stringValues : [String] {
        return DeserializedType.stringValues
    }
    
    public override func stringValue(data:NSData) -> [String:String]? {
        let value : DeserializedType? = Serde.deserialize(data)
        return value.map{$0.stringValue}
    }
    
    public override func dataFromStringValue(data:[String:String]) -> NSData? {
        return DeserializedType(stringValue:data).flatmap{Serde.serialize($0)}
    }
    
}

// RawArrayPairCharacteristicProfile
public class RawArrayPairCharacteristicProfile<DeserializedType where DeserializedType:RawArrayPairDeserializable, DeserializedType:StringDeserializable, DeserializedType:CharacteristicConfigurable> : CharacteristicProfile {
    
    public init() {
        super.init(uuid:DeserializedType.uuid,
            name:DeserializedType.name,
            permissions:DeserializedType.permissions,
            properties:DeserializedType.properties,
            initialValue:DeserializedType.initialValue)
    }
    
    public override var stringValues : [String] {
        return DeserializedType.stringValues
    }
    
    public override func stringValue(data:NSData) -> [String:String]? {
        let value : DeserializedType? = Serde.deserialize(data)
        return value.map{$0.stringValue}
    }
    
    public override func dataFromStringValue(data:[String:String]) -> NSData? {
        return DeserializedType(stringValue:data).flatmap{Serde.serialize($0)}
    }
    
}

// StringCharacteristicProfile
public class StringCharacteristicProfile<T:CharacteristicConfigurable> : CharacteristicProfile {
    
    public var encoding : NSStringEncoding
    
    public convenience init(encoding:NSStringEncoding = NSUTF8StringEncoding) {
        self.init(uuid:T.uuid, name:T.name, permissions:T.permissions, properties:T.properties, initialValue:T.initialValue, encoding:encoding)
    }
    
    public init(uuid:String,
                name:String,
                permissions:CBAttributePermissions=CBAttributePermissions.Readable | CBAttributePermissions.Writeable,
                properties:CBCharacteristicProperties = CBCharacteristicProperties.Read | CBCharacteristicProperties.Write | CBCharacteristicProperties.Notify,
                initialValue:NSData? = nil,
                encoding:NSStringEncoding = NSUTF8StringEncoding) {
        self.encoding = encoding
        super.init(uuid:uuid, name:name, permissions:permissions, properties:properties)
    }
    
    public override func stringValue(data:NSData) -> [String:String]? {
        let value : String? = Serde.deserialize(data, encoding:self.encoding)
        return value.map{[self.name:$0]}
    }
    
    public override func dataFromStringValue(data:[String:String]) -> NSData? {
        return data[self.name].flatmap{Serde.serialize($0, encoding:self.encoding)}
    }

}


