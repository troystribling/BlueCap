//
//  StructCharacteristicProfile.swift
//  BlueCap
//
//  Created by Troy Stribling on 7/11/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation

class StructCharacteristicProfile<StructType:DeserializedStruct where StructType.RawType == StructType.RawType.SelfType, StructType == StructType.SelfType> : CharacteristicProfile {
    
    var endianness : Endianness = .Little
    var afterReadCallback           : ((value:StructType) -> StructType?)?
    var beforeWriteCallback         : ((value:StructType) -> StructType?)?

    // APPLICATION INTERFACE
    init(uuid:String, name:String, profile:((characteristic:StructCharacteristicProfile<StructType>) -> ())? = nil) {
        super.init(uuid:uuid, name:name)
        if let runProfile = profile {
            runProfile(characteristic:self)
        }
    }

    convenience init(uuid:String, name:String, fromEndianness endianness:Endianness, profile:((characteristic:StructCharacteristicProfile<StructType>) -> ())? = nil) {
        self.init(uuid:uuid, name:name, profile:profile)
        self.endianness = endianness
    }
    
    override func stringValues(data:NSData) -> Dictionary<String, String>? {
        if let value = self.structFromData(data) {
            if let afterReadCallback = self.afterReadCallback {
                return afterReadCallback(value: value)?.stringValues
            } else {
                return value.stringValues
            }
        } else {
            return nil
        }
    }
    
    override func anyValue(data:NSData) -> Any? {
        if let value = self.structFromData(data) {
            if let afterReadCallback = self.afterReadCallback {
                return afterReadCallback(value:value)
            } else {
                return value
            }
        } else {
            return nil
        }
    }
    
    override func dataValue(data:Dictionary<String, String>) -> NSData? {
        if let value = StructType.fromStrings(data) {
            return self.applyBeforeWriteCallback(value)
        } else {
            return nil
        }
    }
    
    override func dataValue(object:Any) -> NSData? {
        if let value = object as? StructType {
            return self.applyBeforeWriteCallback(value)
        } else {
            return nil
        }
    }
    
    // CALLBACKS
    func afterRead(afterReadCallback:(value:StructType) -> StructType?) {
        self.afterReadCallback = afterReadCallback
    }
    
    func beforeWrite(beforeWriteCallback:(value:StructType) -> StructType?) {
        self.beforeWriteCallback = beforeWriteCallback
    }
    

    // PRIVATE INTERFACE
    func deserialize(data:NSData) -> [StructType.RawType] {
        switch self.endianness {
        case Endianness.Little:
            return StructType.RawType.deserializeFromLittleEndian(data)
        case Endianness.Big:
            return StructType.RawType.deserializeFromBigEndian(data)
        }
    }
    
    func serialize(values:[StructType.RawType]) -> NSData {
        switch self.endianness {
        case Endianness.Little:
            return NSData.serializeToLittleEndian(values)
        case Endianness.Big:
            return NSData.serializeToBigEndian(values)
        }
    }
    
    func structFromData(data:NSData) -> StructType? {
        let values = self.deserialize(data)
        return StructType.fromRawValues(values)
    }

    func applyBeforeWriteCallback(value:StructType) -> NSData? {
        if let beforeWriteCallback = self.beforeWriteCallback {
            if let alteredValue = beforeWriteCallback(value:value) {
                return self.serialize(alteredValue.toRawValues())
            } else {
                return nil
            }
        } else {
            return self.serialize(value.toRawValues())
        }
    }

}
