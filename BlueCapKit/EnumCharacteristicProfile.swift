//
//  EnumCharacteristicProfile.swift
//  BlueCap
//
//  Created by Troy Stribling on 7/7/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation

class EnumCharacteristicProfile<EnumType:DeserializedEnumStatic, DeserilaizedEnumInstance where EnumType.InstanceType:DeserializedEnumInstance> : CharacteristicProfile {
    
    var stringValues : String[] {
        return EnumType.stringValues()
    }
    
    // APPLICATION INTERFACE
    init(uuid: String, name: String) {
        super.init(uuid:uuid, name:name)
    }
    
    convenience init(uuid:String, name:String, profile:(characteristic:EnumCharacteristicProfile) -> ()) {
        self.init(uuid:uuid, name:name)
        profile(characteristic:self)
    }

    override func stringValues(data:NSData) -> Dictionary<String, String>? {
        let byteValue = Byte.deserialize(data)
        if let value = EnumType.fromRaw(byteValue) {
            return [self.name:value.stringValue]
        } else {
            return nil
        }
    }

    override func anyValue(data:NSData) -> Any? {
        let byteValue = Byte.deserialize(data)
        return EnumType.fromRaw(byteValue)
    }
    
    override func dataValue(data:Dictionary<String, String>) -> NSData? {
        if let dataString = data[self.name] {
            if let value = EnumType.fromString(dataString) {
                let valueRaw = value.toRaw()
                return NSData.serialize(valueRaw)
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
    
    override func dataValue(object:Any) -> NSData? {
        if let value = object as? EnumType.InstanceType {
           return NSData.serialize(value.toRaw())
        } else {
            return nil
        }
    }
    
}
