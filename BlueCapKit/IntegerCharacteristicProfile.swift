//
//  IntegerCharacteristicProfile.swift
//  BlueCap
//
//  Created by Troy Stribling on 7/9/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation

enum Endianness {
    case Little
    case Big
}

class IntegerCharacteristicProfile<IntegerType:Deserialized> : CharacteristicProfile {

    var endianness : Endianness
    
    init(uuid:String, name:String, fromEndianness endianness:Endianness) {
        self.endianness = endianness
        super.init(uuid:uuid, name:name)
    }
    
    // APPLICATION INTERFACE
    override func stringValue(data:NSData) -> Dictionary<String, String>? {
        return [self.name:"\(self.deserialize(data))"]
    }
    
//    override func anyValue(data:NSData) -> Any {
//        
//    }
//    
//    override func dataValue(data:Dictionary<String, String>) -> NSData? {
//        if let value = data[self.name] {
//            if let intValue = value.toInt() {
//                if let integerTypeValue = intValue as? IntegerType {
//                    
//                } else {
//                    return nil
//                }
//            } else {
//                return nil
//            }
//        } else {
//            return nil
//        }
//    }

//    override func dataValue(object: Any) -> NSData? {
//        
//    }
    
    // PRIVATE INTERFACE
    func deserialize(data:NSData) -> IntegerType.DeserializedType {
        switch self.endianness {
        case Endianness.Little:
            return IntegerType.deserializeFromLittleEndian(data)
        case Endianness.Big:
            return IntegerType.deserializeFromBigEndian(data)
        }
    }
    
    func serialize(value:IntegerType) -> NSData {
        switch self.endianness {
        case Endianness.Little:
            return NSData.serializeToLittleEndian(value)
        case Endianness.Big:
            return NSData.serializeToBigEndian(value)
        }
    }
}