//
//  DeserializedCharacteristicProfile.swift
//  BlueCap
//
//  Created by Troy Stribling on 7/9/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation

public class DeserializedCharacteristicProfile<DeserializedType:Deserializable where DeserializedType == DeserializedType.SelfType> : CharacteristicProfile {

    public override func dataFromStringValue(data:Dictionary<String, String>) -> NSData? {
        if let stringValue = data[self.name] {
            if let value = DeserializedType.fromString(stringValue) {
                Logger.debug("DeserializedCharacteristicProfile#dataValue: data = \(data), value = \(value)")
                return NSData.serializeToLittleEndian(value)
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
    
    public override func stringValue(data:NSData) -> Dictionary<String, String> {
        let value = DeserializedType.deserializeFromLittleEndian(data)
        return [self.name:"\(value)"]
    }
    
}