//
//  EnumCharacteristicProfile.swift
//  BlueCap
//
//  Created by Troy Stribling on 7/7/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation

class EnumCharacteristicProfile<EnumType:DeserializedEnum where EnumType.RawType == EnumType.RawType.SelfType, EnumType == EnumType.SelfType> : CharacteristicProfile {
    
    // PUBLIC
    public var endianness : Endianness = .Little

    public override var discreteStringValues : [String] {
        return EnumType.stringValues()
    }

    public override func stringValues(data:NSData) -> Dictionary<String, String>? {
        if let value = self.anyValue(data) as? EnumType {
            return [self.name:value.stringValue]
        } else {
            return nil
        }
    }
    
    public override func anyValue(data:NSData) -> Any? {
        let valueRaw = self.deserialize(data)
        Logger.debug("EnumCharacteristicProfile#anyValue: data = \(data.hexStringValue()), raw value = \(valueRaw)")
        if let value =  EnumType.fromRaw(valueRaw) {
            return value
        } else {
            return nil
        }
    }
    
    public override func dataFromStringValue(data:Dictionary<String, String>) -> NSData? {
        Logger.debug("EnumCharacteristicProfile#dataValueString: data = \(data)")
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
    
    public override func dataFromAnyValue(object:Any) -> NSData? {
        if let value = object as? EnumType {
            Logger.debug("EnumCharacteristicProfile#dataValue: data = \(value.toRaw())")
            return self.serialize(value.toRaw())
        } else {
            return nil
        }
    }
    
    // INTERNAL
    internal init(uuid:String, name:String, initializer:((characteristicProfile:EnumCharacteristicProfile<EnumType>) -> ())? = nil) {
        super.init(uuid:uuid, name:name)
        if let runInitializer = initializer {
            runInitializer(characteristicProfile:self)
        }
    }
    
    // PRIVATE
    private func deserialize(data:NSData) -> EnumType.RawType {
        switch self.endianness {
        case Endianness.Little:
            return EnumType.RawType.deserializeFromLittleEndian(data)
        case Endianness.Big:
            return EnumType.RawType.deserializeFromBigEndian(data)
        }
    }
    
    private func serialize(value:EnumType.RawType) -> NSData {
        switch self.endianness {
        case Endianness.Little:
            return NSData.serializeToLittleEndian(value)
        case Endianness.Big:
            return NSData.serializeToBigEndian(value)
        }
    }
    
}
