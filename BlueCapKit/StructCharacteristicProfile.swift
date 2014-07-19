//
//  StructCharacteristicProfile.swift
//  BlueCap
//
//  Created by Troy Stribling on 7/11/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation

class StructCharacteristicProfile<StructType:DeserializedStruct where StructType.RawType == StructType.RawType.SelfType, StructType == StructType.SelfType> : CharacteristicProfile {
    
    var endianness : Endianness = .Little

    // APPLICATION INTERFACE
    init(uuid:String, name:String, profile:((characteristic:StructCharacteristicProfile<StructType>) -> ())? = nil) {
        super.init(uuid:uuid, name:name)
        if let runProfile = profile {
            runProfile(characteristic:self)
        }
    }

    convenience init(uuid:String, name:String, fromEndianness endianness:Endianness, profile:((characteristic:StructCharacteristicProfile<StructType>) -> ())? = nil) {
        self.init(uuid:uuid, name:name, profile:profile)
        self.endianness = endianness
    }
    
    override func stringValues(data:NSData) -> Dictionary<String, String>? {
        if let value = self.anyValue(data) as? StructType {
            return value.stringValues
        } else {
            return nil
        }
    }
    
    override func anyValue(data:NSData) -> Any? {
        let values = self.deserialize(data)
        if let value = StructType.fromRawValues(values) {
            Logger.debug("StructCharacteristicProfile#anyValue: data = \(data.hexStringValue()), value = \(value.toRawValues())")
            return value
        } else {
            return nil
        }
    }
    
    override func dataValue(data:Dictionary<String, String>) -> NSData? {
        if let value = StructType.fromStrings(data) {
            Logger.debug("StructCharacteristicProfile#dataValue: data = \(data), value = \(value.toRawValues())")
            return self.serialize(value.toRawValues())
        } else {
            return nil
        }
    }
    
    override func dataValue(object:Any) -> NSData? {
        if let value = object as? StructType {
            Logger.debug("StructCharacteristicProfile#dataValue: value = \(value.toRawValues())")
            return self.serialize(value.toRawValues())
        } else {
            return nil
        }
    }
    
    // PRIVATE INTERFACE
    func deserialize(data:NSData) -> [StructType.RawType] {
        switch self.endianness {
        case Endianness.Little:
            return StructType.RawType.deserializeFromLittleEndian(data)
        case Endianness.Big:
            return StructType.RawType.deserializeFromBigEndian(data)
        }
    }
    
    func serialize(values:[StructType.RawType]) -> NSData {
        switch self.endianness {
        case Endianness.Little:
            return NSData.serializeToLittleEndian(values)
        case Endianness.Big:
            return NSData.serializeToBigEndian(values)
        }
    }
    
}
