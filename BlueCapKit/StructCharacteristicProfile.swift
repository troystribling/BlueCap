//
//  StructCharacteristicProfile.swift
//  BlueCap
//
//  Created by Troy Stribling on 7/11/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation

class StructCharacteristicProfile<StructType:DeserializedStructStatic where StructType.StructType:DeserializedStructInstance, StructType.ValueType:Deserialized> : CharacteristicProfile {
    
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
    
    override func stringValue(data:NSData) -> Dictionary<String, String>? {
        return nil
    }
    
    override func anyValue(data:NSData) -> Any? {
        return nil
    }
    
    override func dataValue(data:Dictionary<String, String>) -> NSData? {
        return nil
    }
    
    override func dataValue(object:Any) -> NSData? {
        return nil
    }
    
    // PRIVATE INTERFACE
    func deserialize(data:NSData) -> StructType.ValueType.DeserializedType[] {
        switch self.endianness {
        case Endianness.Little:
            return StructType.ValueType.deserializeFromLittleEndian(data)
        case Endianness.Big:
            return StructType.ValueType.deserializeFromBigEndian(data)
        }
    }
    
    func serialize(values:StructType.ValueType[]) -> NSData {
        switch self.endianness {
        case Endianness.Little:
            return NSData.serializeToLittleEndian(values)
        case Endianness.Big:
            return NSData.serializeToBigEndian(values)
        }
    }

}
