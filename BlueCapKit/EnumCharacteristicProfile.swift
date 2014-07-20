//
//  EnumCharacteristicProfile.swift
//  BlueCap
//
//  Created by Troy Stribling on 7/7/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation

class EnumCharacteristicProfile<EnumType:DeserializedEnum where EnumType.RawType == EnumType.RawType.SelfType, EnumType == EnumType.SelfType> : CharacteristicProfile {
    
    var endianness : Endianness = .Little

    override var discreteStringValues : [String] {
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
        if let value = self.anyValue(data) as? EnumType {
            return [self.name:value.stringValue]
        } else {
            return nil
        }
    }

    override func anyValue(data:NSData) -> Any? {
        let valueRaw = self.deserialize(data)
        Logger.debug("EnumCharacteristicProfile#anyValue: data = \(data.hexStringValue()), raw value = \(valueRaw)")
        if let value =  EnumType.fromRaw(valueRaw) {
            return value
        } else {
            return nil
        }
    }
    
    override func dataValue(data:Dictionary<String, String>) -> NSData? {
        if let dataString = data[self.name] {
            Logger.debug("EnumCharacteristicProfile#dataValue: data = \(data)")
            if let value = EnumType.fromString(dataString) {
                return self.serialize(value.toRaw())
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
    
    override func dataValue(object:Any) -> NSData? {
        if let value = object as? EnumType {
            Logger.debug("EnumCharacteristicProfile#dataValue: data = \(value.toRaw())")
            return self.serialize(value.toRaw())
        } else {
            return nil
        }
    }
    
    
    // PRIVATE INTERFACE
    func deserialize(data:NSData) -> EnumType.RawType {
        switch self.endianness {
        case Endianness.Little:
            return EnumType.RawType.deserializeFromLittleEndian(data)
        case Endianness.Big:
            return EnumType.RawType.deserializeFromBigEndian(data)
        }
    }
    
    func serialize(value:EnumType.RawType) -> NSData {
        switch self.endianness {
        case Endianness.Little:
            return NSData.serializeToLittleEndian(value)
        case Endianness.Big:
            return NSData.serializeToBigEndian(value)
        }
    }
    
}
