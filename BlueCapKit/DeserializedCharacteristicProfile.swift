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
    var afterReadCallback           : ((value:DeserializedType) -> DeserializedType?)?
    var beforeWriteCallback         : ((value:DeserializedType) -> DeserializedType?)?

    
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
        let deserializedValue = self.deserialize(data)
        if let afterReadCallback = self.afterReadCallback {
            if let alteredValue = afterReadCallback(value:deserializedValue) {
                return [self.name:"\(alteredValue)"]
            } else {
                return nil
            }
        } else {
            return [self.name:"\(deserializedValue)"]
        }
    }
    
    override func anyValue(data:NSData) -> Any? {
        let deserializedValue = self.deserialize(data)
        if let afterReadCallback = self.afterReadCallback {
            return afterReadCallback(value:deserializedValue)
        } else {
            return deserializedValue
        }
    }
    
    override func dataValue(data:Dictionary<String, String>) -> NSData? {
        if let stringValue = data[self.name] {
            if let value = DeserializedType.fromString(stringValue) {
                return self.applyBeforeWriteCallback(value)
            } else {
                return nil
            }
        } else {
            return nil
        }
    }

    override func dataValue(object:Any) -> NSData? {
        if let value = object as? DeserializedType {
            return self.applyBeforeWriteCallback(value)
        } else {
            return nil
        }
    }
    
    // CALLBACKS
    func afterRead(afterReadCallback:(value:DeserializedType) -> DeserializedType?) {
        self.afterReadCallback = afterReadCallback
    }
    
    func beforeWrite(beforeWriteCallback:(value:DeserializedType) -> DeserializedType?) {
        self.beforeWriteCallback = beforeWriteCallback
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
    
    func applyBeforeWriteCallback(value:DeserializedType) -> NSData? {
        if let beforeWriteCallback = self.beforeWriteCallback {
            if let alteredValue = beforeWriteCallback(value:value) {
                return self.serialize(alteredValue)
            } else {
                return nil
            }
        } else {
            return self.serialize(value)
        }
    }
}