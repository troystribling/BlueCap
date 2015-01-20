//
//  DeserializedCharacteristicProfile.swift
//  BlueCap
//
//  Created by Troy Stribling on 7/9/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation

//public class DeserializedCharacteristicProfile<DeserializedType:Deserializable where DeserializedType == DeserializedType.SelfType> : CharacteristicProfile {
//
//    public override init(uuid:String, name:String, initializer:((characteristicProfile:DeserializedCharacteristicProfile<DeserializedType>) -> ())? = nil) {
//        super.init(uuid:uuid, name:name)
//        if let runInitializer = initializer {
//            runInitializer(characteristicProfile:self)
//        }
//    }
//
//    public override func anyValue(data:NSData) -> Any? {
//        let deserializedValue = self.deserialize(data)
//        Logger.debug("DeserializedCharacteristicProfile#anyValue: data = \(data.hexStringValue()), value = \(deserializedValue)")
//        return deserializedValue
//    }
//    
//    public override func dataFromStringValue(data:Dictionary<String, String>) -> NSData? {
//        if let stringValue = data[self.name] {
//            if let value = DeserializedType.fromString(stringValue) {
//                Logger.debug("DeserializedCharacteristicProfile#dataValue: data = \(data), value = \(value)")
//                return self.serialize(value)
//            } else {
//                return nil
//            }
//        } else {
//            return nil
//        }
//    }
//    
//    public override func dataFromAnyValue(object:Any) -> NSData? {
//        if let value = object as? DeserializedType {
//            Logger.debug("DeserializedCharacteristicProfile#dataValue: value = \(value)")
//            return self.serialize(value)
//        } else {
//            return nil
//        }
//    }
//    
//    // INTERNAL
//    public override func stringValues(data:NSData) -> Dictionary<String, String>? {
//        if let value = self.anyValue(data) as? DeserializedType {
//            return [self.name:"\(value)"]
//        } else {
//            return nil
//        }
//    }
//    
//    // PRIVATE
//    private func deserialize(data:NSData) -> DeserializedType {
//        return DeserializedType.deserializeFromLittleEndian(data)
//    }
//    
//    private func serialize(value:DeserializedType) -> NSData {
//        return NSData.serializeToLittleEndian(value)
//    }
//    
//}