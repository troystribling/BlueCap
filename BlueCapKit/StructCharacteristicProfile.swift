//
//  StructCharacteristicProfile.swift
//  BlueCap
//
//  Created by Troy Stribling on 7/11/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation

class StructCharacteristicProfile<StructType:DeserializedStructStatic> : CharacteristicProfile {
    
    var endianness : Endianness = .Little
    
    // APPLICATION INTERFACE
    init(uuid:String, name:String, fromEndianness endianness:Endianness) {
        super.init(uuid:uuid, name:name)
        self.endianness = endianness
    }
    
    convenience init(uuid:String, name:String, fromEndianness endianness:Endianness, profile:(characteristic:StructCharacteristicProfile<StructType>) -> ()) {
        self.init(uuid:uuid, name:name, fromEndianness:endianness)
        profile(characteristic:self)
    }
    
    override func stringValues(data:NSData) -> Dictionary<String, String>? {
        if let value = self.structFromData(data) {
            return value.stringValues
        } else {
            return nil
        }
    }
    
    override func anyValue(data:NSData) -> Any? {
        return self.structFromData(data)
    }
    
    override func dataValue(data:Dictionary<String, String>) -> NSData? {
        if let value = StructType.fromStrings(data) {
            return self.serialize(value.arrayValue())
        } else {
            return nil
        }
    }
    
    override func dataValue(object:Any) -> NSData? {
        if let value = object as? StructType.InstanceType {
            return self.serialize(value.arrayValue())
        } else {
            return nil
        }
    }
    
    // PRIVATE INTERFACE
    func deserialize(data:NSData) -> StructType.InstanceType.ValueType.DeserializedType[] {
        switch self.endianness {
        case Endianness.Little:
            return StructType.InstanceType.ValueType.deserializeFromLittleEndian(data)
        case Endianness.Big:
            return StructType.InstanceType.ValueType.deserializeFromBigEndian(data)
        }
    }
    
    func serialize(values:StructType.InstanceType.ValueType.DeserializedType[]) -> NSData {
        switch self.endianness {
        case Endianness.Little:
            return NSData.serializeToLittleEndian(values)
        case Endianness.Big:
            return NSData.serializeToBigEndian(values)
        }
    }
    
    func structFromData(data:NSData) -> StructType.InstanceType? {
        let values = self.deserialize(data)
        return StructType.fromArray(values)
    }

}
