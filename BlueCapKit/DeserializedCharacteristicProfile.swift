//
//  DeserializedCharacteristicProfile.swift
//  BlueCap
//
//  Created by Troy Stribling on 7/9/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation

class DeserializedCharacteristicProfile<DeserializedType:Deserialized where DeserializedType == DeserializedType.SelfType> : CharacteristicProfile {

    var endianness : Endianness = .Little

    
    // APPLICATION INTERFACE
    init(uuid:String, name:String, profile:((characteristic:DeserializedCharacteristicProfile<DeserializedType>) -> ())? = nil) {
        super.init(uuid:uuid, name:name)
        if let runProfile = profile {
            runProfile(characteristic:self)
        }
    }

    convenience init(uuid:String, name:String, fromEndianness endianness:Endianness, profile:((characteristic:DeserializedCharacteristicProfile<DeserializedType>) -> ())? = nil) {
        self.init(uuid:uuid, name:name, profile:profile)
        self.endianness = endianness
    }

    override func stringValues(data:NSData) -> Dictionary<String, String>? {
        if let value = self.anyValue(data) as? DeserializedType {
            return [self.name:"\(value)"]
        } else {
            return nil
        }
    }
    
    override func anyValue(data:NSData) -> Any? {
        let deserializedValue = self.deserialize(data)
        Logger.debug("DeserializedCharacteristicProfile#anyValue: data = \(data.hexStringValue()), value = \(deserializedValue)")
        return deserializedValue
    }
    
    override func dataValue(data:Dictionary<String, String>) -> NSData? {
        if let stringValue = data[self.name] {
            if let value = DeserializedType.fromString(stringValue) {
                Logger.debug("DeserializedCharacteristicProfile#dataValue: data = \(data), value = \(value)")
                return self.serialize(value)
            } else {
                return nil
            }
        } else {
            return nil
        }
    }

    override func dataValue(object:Any) -> NSData? {
        if let value = object as? DeserializedType {
            Logger.debug("DeserializedCharacteristicProfile#dataValue: value = \(value)")
            return self.serialize(value)
        } else {
            return nil
        }
    }
    
    // PRIVATE INTERFACE
    func deserialize(data:NSData) -> DeserializedType {
        switch self.endianness {
        case Endianness.Little:
            return DeserializedType.deserializeFromLittleEndian(data)
        case Endianness.Big:
            return DeserializedType.deserializeFromBigEndian(data)
        }
    }
    
    func serialize(value:DeserializedType) -> NSData {
        switch self.endianness {
        case Endianness.Little:
            return NSData.serializeToLittleEndian(value)
        case Endianness.Big:
            return NSData.serializeToBigEndian(value)
        }
    }
    
}