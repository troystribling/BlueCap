//
//  StructCharacteristicProfile.swift
//  BlueCap
//
//  Created by Troy Stribling on 7/11/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation

//public class StructCharacteristicProfile<StructType:DeserializedStruct where StructType.RawType == StructType.RawType.SelfType, StructType == StructType.SelfType> : CharacteristicProfile {
//    
//    public override init(uuid:String, name:String, initializer:((characteristicProfile:StructCharacteristicProfile<StructType>) -> ())? = nil) {
//        super.init(uuid:uuid, name:name)
//        if let runInitializer = initializer {
//            runInitializer(characteristicProfile:self)
//        }
//    }
//
//    public override func stringValues(data:NSData) -> Dictionary<String, String>? {
//        if let value = self.anyValue(data) as? StructType {
//            return value.stringValues
//        } else {
//            return nil
//        }
//    }
//    
//    public override func anyValue(data:NSData) -> Any? {
//        let values = self.deserialize(data)
//        if let value = StructType.fromRawValues(values) {
//            Logger.debug("StructCharacteristicProfile#anyValue: data = \(data.hexStringValue()), value = \(value.toRawValues())")
//            return value
//        } else {
//            return nil
//        }
//    }
//    
//    public override func dataFromStringValue(data:Dictionary<String, String>) -> NSData? {
//        if let value = StructType.fromStrings(data) {
//            Logger.debug("StructCharacteristicProfile#dataValue: data = \(data), value = \(value.toRawValues())")
//            return self.serialize(value.toRawValues())
//        } else {
//            return nil
//        }
//    }
//    
//    public override func dataFromAnyValue(object:Any) -> NSData? {
//        if let value = object as? StructType {
//            Logger.debug("StructCharacteristicProfile#dataValue: value = \(value.toRawValues())")
//            return self.serialize(value.toRawValues())
//        } else {
//            return nil
//        }
//    }
//    
//    // PRIVATE
//    private func deserialize(data:NSData) -> [StructType.RawType] {
//        return StructType.RawType.deserializeArrayFromLittleEndian(data)
//    }
//    
//    private func serialize(values:[StructType.RawType]) -> NSData {
//        return NSData.serializeArrayToLittleEndian(values)
//    }
//    
//}
