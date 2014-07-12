//
//  AnyCharacteristicProfile.swift
//  BlueCap
//
//  Created by Troy Stribling on 7/9/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation

class AnyCharacteristicProfile<AnyType:Deserialized> : CharacteristicProfile {

    var endianness : Endianness = .Little
    
    // APPLICATION INTERFACE
    init(uuid:String, name:String, fromEndianness endianness:Endianness) {
        super.init(uuid:uuid, name:name)
        self.endianness = endianness
    }
    
    convenience init(uuid:String, name:String, fromEndianness endianness:Endianness, profile:(characteristic:AnyCharacteristicProfile<AnyType>) -> ()) {
        self.init(uuid:uuid, name:name, fromEndianness:endianness)
        profile(characteristic:self)
    }
    
    override func stringValue(data:NSData) -> Dictionary<String, String>? {
        return [self.name:"\(self.deserialize(data))"]
    }
    
    override func anyValue(data:NSData) -> Any? {
        return self.deserialize(data)
    }
    
    override func dataValue(data:Dictionary<String, String>) -> NSData? {
        if let stringValue = data[self.name] {
            if let value = AnyType.fromString(stringValue) {
                return self.serialize(value)
            } else {
                return nil
            }
        } else {
            return nil
        }
    }

    override func dataValue(object: Any) -> NSData? {
        if let value = object as? AnyType.DeserializedType {
            return self.serialize(value)
        } else {
            return nil
        }
    }
    
    // PRIVATE INTERFACE
    func deserialize(data:NSData) -> AnyType.DeserializedType {
        switch self.endianness {
        case Endianness.Little:
            return AnyType.deserializeFromLittleEndian(data)
        case Endianness.Big:
            return AnyType.deserializeFromBigEndian(data)
        }
    }
    
    func serialize(value:AnyType.DeserializedType) -> NSData {
        switch self.endianness {
        case Endianness.Little:
            return NSData.serializeToLittleEndian(value)
        case Endianness.Big:
            return NSData.serializeToBigEndian(value)
        }
    }
}