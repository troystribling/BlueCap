//
//  DeserializedCharacteristicProfile.swift
//  BlueCap
//
//  Created by Troy Stribling on 7/9/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation

public class DeserializedCharacteristicProfile<DeserializedType:Deserializable> : CharacteristicProfile {

    public override var stringValues : [String] {
        return []
    }
    
    public override func stringValue(data:NSData) -> Dictionary<String, String>? {
        let value : DeserializedType? = deserialize(data)
        return value.map{[self.name:"\($0)"]}
    }

    public override func dataFromStringValue(data:[String:String]) -> NSData? {
        return data[self.name].flatmap{DeserializedType.fromString($0)}.map{serialize($0)}
    }
    
}