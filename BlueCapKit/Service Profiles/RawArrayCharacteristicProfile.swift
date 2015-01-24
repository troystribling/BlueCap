//
//  RawArrayCharacteristicProfile.swift
//  BlueCap
//
//  Created by Troy Stribling on 7/11/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation

public class RawArrayCharacteristicProfile<DeserializedType where DeserializedType:RawArrayDeserializable, DeserializedType:StringDeserializable, DeserializedType:BLEConfigurable> : CharacteristicProfile {
    
    public init() {
        super.init(uuid:DeserializedType.uuid, name:DeserializedType.name, permissions:DeserializedType.permissions, properties:DeserializedType.properties)
    }
    
    public override var stringValues : [String] {
        return DeserializedType.stringValues
    }
    
    public override func stringValue(data:NSData) -> Dictionary<String, String>? {
        let value : DeserializedType? = deserialize(data)
        return value.map{$0.stringValue}
    }
    
    public override func dataFromStringValue(data:Dictionary<String, String>) -> NSData? {
        return DeserializedType(stringValue:data).map{serialize($0)}
    }
    
}
