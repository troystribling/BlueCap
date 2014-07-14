//
//  EnumCharacteristicProfile.swift
//  BlueCap
//
//  Created by Troy Stribling on 7/7/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation

class EnumCharacteristicProfile<EnumType:DeserializedEnum> : CharacteristicProfile {
    
    var endianness : Endianness = .Little

    var stringValues : [String] {
        return EnumType.stringValues()
    }
    
    // APPLICATION INTERFACE
    init(uuid:String, name:String, fromEndianness endianness:Endianness = .Little) {
        super.init(uuid:uuid, name:name)
        self.endianness = endianness
    }
    
    convenience init(uuid:String, name:String, fromEndianness endianness:Endianness, profile:(characteristic:EnumCharacteristicProfile<EnumType>) -> ()) {
        self.init(uuid:uuid, name:name, fromEndianness:endianness)
        profile(characteristic:self)
    }

    override func stringValues(data:NSData) -> Dictionary<String, String>? {
        if let valueNative = self.deserialize(data) as? EnumType.ValueType {
            if let value = EnumType.fromNative(valueNative) as? EnumType {
                return [self.name:value.stringValue]
            } else {
                return nil
            }
        } else {
            return nil
        }
    }

    override func anyValue(data:NSData) -> Any? {
        if let value = self.deserialize(data) as? EnumType.ValueType {
            return EnumType.fromNative(value) as? EnumType
        } else {
            return nil
        }
    }
    
    override func dataValue(data:Dictionary<String, String>) -> NSData? {
        if let dataString = data[self.name] {
            if let value = EnumType.fromString(dataString) as? EnumType {
                let valueNative = value.toNative()
                return self.serialize(valueNative)
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
    
    override func dataValue(object:Any) -> NSData? {
        if let value = object as? EnumType {
           return self.serialize(value.toNative())
        } else {
            return nil
        }
    }
    
    // PRIVATE INTERFACE
    func deserialize(data:NSData) -> EnumType.ValueType.SelfType {
        switch self.endianness {
        case Endianness.Little:
            return EnumType.ValueType.deserializeFromLittleEndian(data)
        case Endianness.Big:
            return EnumType.ValueType.deserializeFromBigEndian(data)
        }
    }
    
    func serialize(value:EnumType.ValueType) -> NSData {
        switch self.endianness {
        case Endianness.Little:
            return NSData.serializeToLittleEndian(value)
        case Endianness.Big:
            return NSData.serializeToBigEndian(value)
        }
    }
}
