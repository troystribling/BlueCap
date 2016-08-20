//
//  CharacteristicProfile.swift
//  BlueCap
//
//  Created by Troy Stribling on 6/21/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import Foundation
import CoreBluetooth

// MARK:  - CharacteristicProfile -
public class CharacteristicProfile {
    
    public let UUID: CBUUID
    public let name: String
    public let permissions: CBAttributePermissions
    public let properties: CBCharacteristicProperties
    public let initialValue: NSData?

    internal var afterDiscoveredPromise: StreamPromise<Characteristic>!

    public var stringValues: [String] {
        return []
    }
    
    public init(UUID: String,
                name: String,
                permissions: CBAttributePermissions = [CBAttributePermissions.readable, CBAttributePermissions.writeable],
                properties: CBCharacteristicProperties = [CBCharacteristicProperties.read, CBCharacteristicProperties.write, CBCharacteristicProperties.notify],
                initialValue:Data? = nil) {
        self.UUID = CBUUID(string: UUID)
        self.name = name
        self.permissions = permissions
        self.properties = properties
        self.initialValue = initialValue
    }
    
    public convenience init(UUID:String) {
        self.init(UUID:UUID, name:"Unknown")
    }
    
    public func afterDiscovered(capacity: Int? = nil) -> FutureStream<Characteristic> {
        guard let afterDiscoveredPromise = self.afterDiscoveredPromise else {
            self.afterDiscoveredPromise = StreamPromise<Characteristic>(capacity:capacity)
            return self.afterDiscoveredPromise.future
        }
        return afterDiscoveredPromise.future
    }

    public func propertyEnabled(property: CBCharacteristicProperties) -> Bool {
        return (self.properties.rawValue & property.rawValue) > 0
    }
    
    public func permissionEnabled(permission: CBAttributePermissions) -> Bool {
        return (self.permissions.rawValue & permission.rawValue) > 0
    }
        
    public func stringValue(data: NSData) -> [String:String]? {
        return [self.name:data.hexStringValue()]
    }
    
    public func dataFromStringValue(data: [String: String]) -> NSData? {
        return data[self.name].map{ $0.dataFromHexString() }
    }
    
}

// MARK: - RawCharacteristicProfile -
public final class RawCharacteristicProfile<DeserializedType>: CharacteristicProfile where
                                            DeserializedType: RawDeserializable,
                                            DeserializedType: StringDeserializable,
                                            DeserializedType: CharacteristicConfigurable,
                                            DeserializedType.RawType: Deserializable {
    
    public init() {
        super.init(UUID: DeserializedType.UUID,
            name: DeserializedType.name,
            permissions: DeserializedType.permissions,
            properties: DeserializedType.properties,
            initialValue: DeserializedType.initialValue as Data?)
    }
    
    public override var stringValues: [String] {
        return DeserializedType.stringValues
    }
    
    public override func stringValue(_ data: Data) -> [String:String]? {
        let value: DeserializedType? = SerDe.deserialize(data)
        return value.map{$0.stringValue}
    }
    
    public override func dataFromStringValue(_ data: Dictionary<String, String>) -> Data? {
        return DeserializedType(stringValue: data).flatmap{ SerDe.serialize($0) }
    }
    
}

// MARK: - RawArrayCharacteristicProfile -
public final class RawArrayCharacteristicProfile<DeserializedType>: CharacteristicProfile where
                                                 DeserializedType: RawArrayDeserializable,
                                                 DeserializedType: StringDeserializable,
                                                 DeserializedType: CharacteristicConfigurable,
                                                 DeserializedType.RawType: Deserializable {
    
    public init() {
        super.init(UUID: DeserializedType.UUID,
                   name: DeserializedType.name,
                   permissions: DeserializedType.permissions,
                   properties: DeserializedType.properties,
                   initialValue: DeserializedType.initialValue as Data?)
    }
    
    public override var stringValues: [String] {
        return DeserializedType.stringValues
    }
    
    public override func stringValue(_ data: Data) -> [String: String]? {
        let value : DeserializedType? = SerDe.deserialize(data)
        return value.map{$0.stringValue}
    }
    
    public override func dataFromStringValue(_ data: [String: String]) -> Data? {
        return DeserializedType(stringValue:data).flatmap{ SerDe.serialize($0) }
    }
    
}

// MARK: - RawPairCharacteristicProfile -
public final class RawPairCharacteristicProfile<DeserializedType>: CharacteristicProfile where
                                                DeserializedType: RawPairDeserializable,
                                                DeserializedType: StringDeserializable,
                                                DeserializedType: CharacteristicConfigurable,
                                                DeserializedType.RawType1: Deserializable,
                                                DeserializedType.RawType2: Deserializable {
    
    public init() {
        super.init(UUID:  DeserializedType.UUID,
            name: DeserializedType.name,
            permissions: DeserializedType.permissions,
            properties: DeserializedType.properties,
            initialValue: DeserializedType.initialValue as Data?)
    }
    
    public override var stringValues: [String] {
        return DeserializedType.stringValues
    }
    
    public override func stringValue(_ data: Data) -> [String:String]? {
        let value : DeserializedType? = SerDe.deserialize(data)
        return value.map{ $0.stringValue }
    }
    
    public override func dataFromStringValue(_ data:[String:String]) -> Data? {
        return DeserializedType(stringValue:data).flatmap{ SerDe.serialize($0) }
    }
    
}


// MARK: - RawArrayPairCharacteristicProfile -
public final class RawArrayPairCharacteristicProfile<DeserializedType>: CharacteristicProfile where
                                                     DeserializedType: RawArrayPairDeserializable,
                                                     DeserializedType: StringDeserializable,
                                                     DeserializedType: CharacteristicConfigurable,
                                                     DeserializedType.RawType1: Deserializable,
                                                     DeserializedType.RawType2: Deserializable {
    
    public init() {
        super.init(UUID: DeserializedType.UUID,
            name: DeserializedType.name,
            permissions: DeserializedType.permissions,
            properties: DeserializedType.properties,
            initialValue: DeserializedType.initialValue as Data?)
    }
    
    public override var stringValues: [String] {
        return DeserializedType.stringValues
    }
    
    public override func stringValue(_ data:Data) -> [String: String]? {
        let value : DeserializedType? = SerDe.deserialize(data)
        return value.map{ $0.stringValue }
    }
    
    public override func dataFromStringValue(_ data:[String:String]) -> Data? {
        return DeserializedType(stringValue:data).flatmap{ SerDe.serialize($0)}
    }
    
}

// MARK: - StringCharacteristicProfile -
public final class StringCharacteristicProfile<T: CharacteristicConfigurable>: CharacteristicProfile {
    
    public var encoding : String.Encoding
    
    public convenience init(encoding: String.Encoding = String.Encoding.utf8) {
        self.init(UUID: T.UUID, name: T.name, permissions: T.permissions, properties: T.properties, initialValue: T.initialValue as Data?, encoding: encoding)
    }
    
    public init(UUID: String,
                name: String,
                permissions: CBAttributePermissions = [CBAttributePermissions.readable, CBAttributePermissions.writeable],
                properties:CBCharacteristicProperties = [CBCharacteristicProperties.read, CBCharacteristicProperties.write, CBCharacteristicProperties.notify],
                initialValue:Data? = nil,
                encoding:String.Encoding = String.Encoding.utf8) {
        self.encoding = encoding
        super.init(UUID: UUID, name: name, permissions: permissions, properties: properties)
    }
    
    public override func stringValue(_ data: Data) -> [String: String]? {
        let value: String? = SerDe.deserialize(data, encoding: self.encoding)
        return value.map{ [self.name: $0] }
    }
    
    public override func dataFromStringValue(_ data:[String: String]) -> Data? {
        return data[self.name].flatmap{ SerDe.serialize($0, encoding:self.encoding) }
    }

}


