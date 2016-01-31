//
//  BCCharacteristicProfile.swift
//  BlueCap
//
//  Created by Troy Stribling on 6/21/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import Foundation
import CoreBluetooth

// MARK:  - BCCharacteristicProfile -
public class CharacteristicProfile {
    
    public let uuid: CBUUID
    public let name: String
    public let permissions: CBAttributePermissions
    public let properties: CBCharacteristicProperties
    public let initialValue: NSData?

    internal var afterDiscoveredPromise : StreamPromise<BCCharacteristic>!

    public var stringValues : [String] {
        return []
    }
    
    public init(uuid: String,
                name: String,
                permissions: CBAttributePermissions = [CBAttributePermissions.Readable, CBAttributePermissions.Writeable],
                properties: CBCharacteristicProperties = [CBCharacteristicProperties.Read, CBCharacteristicProperties.Write, CBCharacteristicProperties.Notify],
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
    
    public func afterDiscovered(capacity: Int?) -> FutureStream<BCCharacteristic> {
        guard let afterDiscoveredPromise = self.afterDiscoveredPromise else {
            self.afterDiscoveredPromise = StreamPromise<BCCharacteristic>(capacity:capacity)
            return self.afterDiscoveredPromise.future
        }
        return afterDiscoveredPromise.future
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

// MARK: - BCRawCharacteristicProfile -
public final class BCRawCharacteristicProfile<DeserializedType where
                                              DeserializedType: BCRawDeserializable,
                                              DeserializedType: BCStringDeserializable,
                                              DeserializedType: BCCharacteristicConfigurable,
                                              DeserializedType.RawType: BCDeserializable>: BCCharacteristicProfile {
    
    public init() {
        super.init(uuid:DeserializedType.uuid,
            name:DeserializedType.name,
            permissions:DeserializedType.permissions,
            properties:DeserializedType.properties,
            initialValue:DeserializedType.initialValue)
    }
    
    public override var stringValues: [String] {
        return DeserializedType.stringValues
    }
    
    public override func stringValue(data: NSData) -> [String:String]? {
        let value : DeserializedType? = BCSerde.deserialize(data)
        return value.map{$0.stringValue}
    }
    
    public override func dataFromStringValue(data:Dictionary<String, String>) -> NSData? {
        return DeserializedType(stringValue:data).flatmap{Serde.serialize($0)}
    }
    
}

// MARK: - BCRawArrayCharacteristicProfile -
public final class RawArrayCharacteristicProfile<DeserializedType where
                                                   DeserializedType: BCRawArrayDeserializable,
                                                   DeserializedType: BCStringDeserializable,
                                                   DeserializedType: BCCharacteristicConfigurable,
                                                   DeserializedType.RawType: BCDeserializable>: BCCharacteristicProfile {
    
    public init() {
        super.init(uuid:DeserializedType.uuid,
                   name:DeserializedType.name,
                   permissions:DeserializedType.permissions,
                   properties:DeserializedType.properties,
                   initialValue:DeserializedType.initialValue)
    }
    
    public override var stringValues: [String] {
        return DeserializedType.stringValues
    }
    
    public override func stringValue(data: NSData) -> [String: String]? {
        let value : DeserializedType? = BCSerde.deserialize(data)
        return value.map{$0.stringValue}
    }
    
    public override func dataFromStringValue(data: [String: String]) -> NSData? {
        return DeserializedType(stringValue:data).flatmap{Serde.serialize($0)}
    }
    
}

// MARK: - BCRawPairCharacteristicProfile -
public final class BCRawPairCharacteristicProfile<DeserializedType where
                                                  DeserializedType: BCRawPairDeserializable,
                                                  DeserializedType: BCStringDeserializable,
                                                  DeserializedType: BCCharacteristicConfigurable,
                                                  DeserializedType.RawType1: BCDeserializable,
                                                  DeserializedType.RawType2: BCDeserializable>: BCCharacteristicProfile {
    
    public init() {
        super.init(uuid:  DeserializedType.uuid,
            name: DeserializedType.name,
            permissions: DeserializedType.permissions,
            properties: DeserializedType.properties,
            initialValue: DeserializedType.initialValue)
    }
    
    public override var stringValues: [String] {
        return DeserializedType.stringValues
    }
    
    public override func stringValue(data: NSData) -> [String:String]? {
        let value : DeserializedType? = BCSerde.deserialize(data)
        return value.map{ $0.stringValue }
    }
    
    public override func dataFromStringValue(data:[String:String]) -> NSData? {
        return DeserializedType(stringValue:data).flatmap{ BCSerde.serialize($0) }
    }
    
}


// MARK: - BCRawArrayPairCharacteristicProfile -
public final class BCRawArrayPairCharacteristicProfile<DeserializedType where
                                                       DeserializedType: BCRawArrayPairDeserializable,
                                                       DeserializedType: BCStringDeserializable,
                                                       DeserializedType: BCCharacteristicConfigurable,
                                                       DeserializedType.RawType1: BCDeserializable,
                                                       DeserializedType.RawType2: BCDeserializable>: BCCharacteristicProfile {
    
    public init() {
        super.init(uuid: DeserializedType.uuid,
            name: DeserializedType.name,
            permissions: DeserializedType.permissions,
            properties: DeserializedType.properties,
            initialValue: DeserializedType.initialValue)
    }
    
    public override var stringValues: [String] {
        return DeserializedType.stringValues
    }
    
    public override func stringValue(data:NSData) -> [String: String]? {
        let value : DeserializedType? = BCSerde.deserialize(data)
        return value.map{ $0.stringValue }
    }
    
    public override func dataFromStringValue(data:[String:String]) -> NSData? {
        return DeserializedType(stringValue:data).flatmap{ BCSerde.serialize($0)}
    }
    
}

// MARK: - BCStringCharacteristicProfile -
public final class BCStringCharacteristicProfile<T: BCCharacteristicConfigurable>: BCCharacteristicProfile {
    
    public var encoding : NSStringEncoding
    
    public convenience init(encoding: NSStringEncoding = NSUTF8StringEncoding) {
        self.init(uuid: T.uuid, name: T.name, permissions: T.permissions, properties: T.properties, initialValue: T.initialValue, encoding: encoding)
    }
    
    public init(uuid: String,
                name: String,
                permissions: CBAttributePermissions = [CBAttributePermissions.Readable, CBAttributePermissions.Writeable],
                properties:CBCharacteristicProperties = [CBCharacteristicProperties.Read, CBCharacteristicProperties.Write, CBCharacteristicProperties.Notify],
                initialValue:NSData? = nil,
                encoding:NSStringEncoding = NSUTF8StringEncoding) {
        self.encoding = encoding
        super.init(uuid: uuid, name: name, permissions: permissions, properties: properties)
    }
    
    public override func stringValue(data: NSData) -> [String: String]? {
        let value: String? = BCSerde.deserialize(data, encoding: self.encoding)
        return value.map{ [self.name: $0] }
    }
    
    public override func dataFromStringValue(data:[String: String]) -> NSData? {
        return data[self.name].flatmap{ BCSerde.serialize($0, encoding:self.encoding) }
    }

}


