//
//  EnumCharacteristicProfile.swift
//  BlueCap
//
//  Created by Troy Stribling on 7/7/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation

class EnumCharacteristicProfile<EnumType:DeserializedEnum where EnumType.RawType == EnumType.RawType.SelfType, EnumType == EnumType.SelfType> : CharacteristicProfile {
    
    var endianness : Endianness = .Little
    var afterReadCallback           : ((value:EnumType) -> EnumType?)?
    var beforeWriteCallback         : ((value:EnumType) -> EnumType?)?

    var stringValues : [String] {
        return EnumType.stringValues()
    }
    
    // APPLICATION INTERFACE
    init(uuid:String, name:String, profile:((characteristic:EnumCharacteristicProfile<EnumType>) -> ())? = nil) {
        super.init(uuid:uuid, name:name)
        if let runProfile = profile {
            runProfile(characteristic:self)
        }
    }

    convenience init(uuid:String, name:String, fromEndianness endianness:Endianness, profile:((characteristic:EnumCharacteristicProfile<EnumType>) -> ())? = nil) {
        self.init(uuid:uuid, name:name, profile:profile)
        self.endianness = endianness
    }

    override func stringValues(data:NSData) -> Dictionary<String, String>? {
        let valueRaw = self.deserialize(data)
        if let value = EnumType.fromRaw(valueRaw) {
            if let afterReadCallback = self.afterReadCallback {
                if let alteredValue = afterReadCallback(value:value) {
                    return [self.name:alteredValue.stringValue]
                } else {
                    return nil
                }
            } else {
                return [self.name:value.stringValue]
            }
        } else {
            return nil
        }
    }

    override func anyValue(data:NSData) -> Any? {
        let value = self.deserialize(data)
        return EnumType.fromRaw(value)
    }
    
    override func dataValue(data:Dictionary<String, String>) -> NSData? {
        if let dataString = data[self.name] {
            if let value = EnumType.fromString(dataString) {
                let valueNative = value.toRaw()
                return self.serialize(valueNative)
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
    
    override func dataValue(object:Any) -> NSData? {
        if let value = object as? EnumType {
           return self.serialize(value.toRaw())
        } else {
            return nil
        }
    }
    
    // CALLBACKS
    func afterRead(afterReadCallback:(value:EnumType) -> EnumType?) {
        self.afterReadCallback = afterReadCallback
    }
    
    func beforeWrite(beforeWriteCallback:(value:EnumType) -> EnumType?) {
        self.beforeWriteCallback = beforeWriteCallback
    }

    // PRIVATE INTERFACE
    func deserialize(data:NSData) -> EnumType.RawType {
        switch self.endianness {
        case Endianness.Little:
            return EnumType.RawType.deserializeFromLittleEndian(data)
        case Endianness.Big:
            return EnumType.RawType.deserializeFromBigEndian(data)
        }
    }
    
    func serialize(value:EnumType.RawType) -> NSData {
        switch self.endianness {
        case Endianness.Little:
            return NSData.serializeToLittleEndian(value)
        case Endianness.Big:
            return NSData.serializeToBigEndian(value)
        }
    }
    
    func applyBeforeWriteCallback(value:EnumType) -> NSData? {
        if let beforeWriteCallback = self.beforeWriteCallback {
            if let alteredValue = beforeWriteCallback(value:value) {
                return self.serialize(alteredValue.toRaw())
            } else {
                return nil
            }
        } else {
            return self.serialize(value.toRaw())
        }
    }

}
