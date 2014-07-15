//
//  EnumCharacteristicProfile.swift
//  BlueCap
//
//  Created by Troy Stribling on 7/7/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation

class EnumCharacteristicProfile<EnumType:DeserializedEnum where EnumType.NativeType == EnumType.NativeType.SelfType, EnumType == EnumType.SelfType> : CharacteristicProfile {
    
    var endianness : Endianness = .Little

    var stringValues : [String] {
        return EnumType.stringValues()
    }
    
    // APPLICATION INTERFACE
    init(uuid:String, name:String, profile:((characteristic:EnumCharacteristicProfile<EnumType>) -> ())? = nil) {
        super.init(uuid:uuid, name:name)
        if let runProfile = profile {
            runProfile(characteristic:self)
        }
    }

    convenience init(uuid:String, name:String, fromEndianness endianness:Endianness, profile:((characteristic:EnumCharacteristicProfile<EnumType>) -> ())? = nil) {
        self.init(uuid:uuid, name:name, profile:profile)
        self.endianness = endianness
    }

    override func stringValues(data:NSData) -> Dictionary<String, String>? {
        let valueNative = self.deserialize(data)
        if let value = EnumType.fromNative(valueNative) {
            return [self.name:value.stringValue]
        } else {
            return nil
        }
    }

    override func anyValue(data:NSData) -> Any? {
        let value = self.deserialize(data)
        return EnumType.fromNative(value)
    }
    
    override func dataValue(data:Dictionary<String, String>) -> NSData? {
        if let dataString = data[self.name] {
            if let value = EnumType.fromString(dataString) {
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
    func deserialize(data:NSData) -> EnumType.NativeType {
        switch self.endianness {
        case Endianness.Little:
            return EnumType.NativeType.deserializeFromLittleEndian(data)
        case Endianness.Big:
            return EnumType.NativeType.deserializeFromBigEndian(data)
        }
    }
    
    func serialize(value:EnumType.NativeType) -> NSData {
        switch self.endianness {
        case Endianness.Little:
            return NSData.serializeToLittleEndian(value)
        case Endianness.Big:
            return NSData.serializeToBigEndian(value)
        }
    }
}
