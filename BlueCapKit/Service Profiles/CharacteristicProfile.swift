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
    
    public let uuid: CBUUID
    public let name: String
    public let permissions: CBAttributePermissions
    public let properties: CBCharacteristicProperties
    public let initialValue: Data?

    public var stringValues: [String] {
        return []
    }
    
    public init(uuid: String,
                name: String,
                permissions: CBAttributePermissions = [.readable, .writeable],
                properties: CBCharacteristicProperties = [.read, .write, .notify],
                initialValue: Data? = nil) {
        self.uuid = CBUUID(string: uuid)
        self.name = name
        self.permissions = permissions
        self.properties = properties
        self.initialValue = initialValue
    }
    
    public convenience init(uuid: String) {
        self.init(uuid: uuid, name: "Unknown")
    }

    public func propertyEnabled(_ property: CBCharacteristicProperties) -> Bool {
        return (properties.rawValue & property.rawValue) > 0
    }
    
    public func permissionEnabled(_ permission: CBAttributePermissions) -> Bool {
        return (permissions.rawValue & permission.rawValue) > 0
    }
        
    public func stringValue(_ data: Data) -> [String : String]? {
        return [name: data.hexStringValue()]
    }
    
    public func data(fromString data: [String : String]) -> Data? {
        return data[name].map{ $0.dataFromHexString() }
    }
    
}

// MARK: - RawCharacteristicProfile -
public final class RawCharacteristicProfile<DeserializedType>: CharacteristicProfile where DeserializedType: RawDeserializable, DeserializedType: StringDeserializable,  DeserializedType: CharacteristicConfigurable, DeserializedType.RawType: Deserializable {
    
    public init() {
        super.init(uuid: DeserializedType.uuid,
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
        Logger.debug("\(String(describing: value))")
        return value.map { $0.stringValue }
    }
    
    public override func data(fromString data: [String: String]) -> Data? {
        return DeserializedType(stringValue: data).flatMap{ SerDe.serialize($0) }
    }
    
}

// MARK: - RawArrayCharacteristicProfile -
public final class RawArrayCharacteristicProfile<DeserializedType>: CharacteristicProfile where
                                                 DeserializedType: RawArrayDeserializable,
                                                 DeserializedType: StringDeserializable,
                                                 DeserializedType: CharacteristicConfigurable,
                                                 DeserializedType.RawType: Deserializable {
    
    public init() {
        super.init(uuid: DeserializedType.uuid,
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
    
    public override func data(fromString data: [String: String]) -> Data? {
        return DeserializedType(stringValue:data).flatMap{ SerDe.serialize($0) }
    }
    
}

// MARK: - RawPairCharacteristicProfile -
public final class RawPairCharacteristicProfile<DeserializedType>: CharacteristicProfile where DeserializedType: RawPairDeserializable, DeserializedType: StringDeserializable, DeserializedType: CharacteristicConfigurable, DeserializedType.RawType1: Deserializable, DeserializedType.RawType2: Deserializable {
    
    public init() {
        super.init(uuid:  DeserializedType.uuid,
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
    
    public override func data(fromString data: [String: String]) -> Data? {
        return DeserializedType(stringValue: data).flatMap{ SerDe.serialize($0) }
    }
    
}


// MARK: - RawArrayPairCharacteristicProfile -
public final class RawArrayPairCharacteristicProfile<DeserializedType>: CharacteristicProfile where DeserializedType: RawArrayPairDeserializable, DeserializedType: StringDeserializable, DeserializedType: CharacteristicConfigurable, DeserializedType.RawType1: Deserializable, DeserializedType.RawType2: Deserializable {
    
    public init() {
        super.init(uuid: DeserializedType.uuid,
            name: DeserializedType.name,
            permissions: DeserializedType.permissions,
            properties: DeserializedType.properties,
            initialValue: DeserializedType.initialValue as Data?)
    }
    
    public override var stringValues: [String] {
        return DeserializedType.stringValues
    }
    
    public override func stringValue(_ data:Data) -> [String : String]? {
        let value : DeserializedType? = SerDe.deserialize(data)
        return value.map{ $0.stringValue }
    }
    
    public override func data(fromString stringValue: [String : String]) -> Data? {
        return DeserializedType(stringValue: stringValue).flatMap{ SerDe.serialize($0) }
    }
    
}

// MARK: - StringCharacteristicProfile -
public final class StringCharacteristicProfile<T: CharacteristicConfigurable>: CharacteristicProfile {
    
    public var encoding : String.Encoding
    
    public convenience init(encoding: String.Encoding = String.Encoding.utf8) {
        self.init(uuid: T.uuid, name: T.name, permissions: T.permissions, properties: T.properties, initialValue: T.initialValue as Data?, encoding: encoding)
    }
    
    public init(uuid: String,
                name: String,
                permissions: CBAttributePermissions = [CBAttributePermissions.readable, CBAttributePermissions.writeable],
                properties:CBCharacteristicProperties = [CBCharacteristicProperties.read, CBCharacteristicProperties.write, CBCharacteristicProperties.notify],
                initialValue:Data? = nil,
                encoding:String.Encoding = String.Encoding.utf8) {
        self.encoding = encoding
        super.init(uuid: uuid, name: name, permissions: permissions, properties: properties)
    }
    
    public override func stringValue(_ data: Data) -> [String: String]? {
        let value: String? = SerDe.deserialize(data, encoding: self.encoding)
        return value.map{ [self.name: $0] }
    }
    
    public override func data(fromString data: [String: String]) -> Data? {
        return data[self.name].flatMap{ SerDe.serialize($0, encoding:self.encoding) }
    }

}


