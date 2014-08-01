//
//  PairStructCharacteristicProfile.swift
//  BlueCap
//
//  Created by Troy Stribling on 8/1/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation

public class PairStructCharacteristicProfile<StructType:DeserializedPairStruct where StructType.RawType1 == StructType.RawType1.SelfType,
                                                                                     StructType.RawType2 == StructType.RawType2.SelfType,
                                                                                     StructType == StructType.SelfType> : CharacteristicProfile {
    
    // PRIVATE
    private var endianness : (Endianness, Endianness) = (.Little, .Little)
    
    // PUBLIC
    public init(uuid:String, name:String, profile:((characteristic:PairStructCharacteristicProfile<StructType>) -> ())? = nil) {
        super.init(uuid:uuid, name:name)
        if let runProfile = profile {
            runProfile(characteristic:self)
        }
    }
    
    public convenience init(uuid:String, name:String, fromEndianness endianness:(Endianness, Endianness), profile:((characteristic:PairStructCharacteristicProfile<StructType>) -> ())? = nil) {
        self.init(uuid:uuid, name:name, profile:profile)
        self.endianness = endianness
    }
    
    public override func stringValues(data:NSData) -> Dictionary<String, String>? {
        if let value = self.anyValue(data) as? StructType {
            return value.stringValues
        } else {
            return nil
        }
    }
    
    // INTERNAL
    internal override func anyValue(data:NSData) -> Any? {
        let values = self.deserialize(data)
        if let value = StructType.fromRawValues(values) {
            Logger.debug("StructCharacteristicProfile#anyValue: data = \(data.hexStringValue()), value = \(value.toRawValues())")
            return value
        } else {
            return nil
        }
    }
    
    internal override func dataValue(data:Dictionary<String, String>) -> NSData? {
        if let value = StructType.fromStrings(data) {
            Logger.debug("StructCharacteristicProfile#dataValue: data = \(data), value = \(value.toRawValues())")
            return self.serialize(value.toRawValues())
        } else {
            return nil
        }
    }
    
    internal override func dataValue(object:Any) -> NSData? {
        if let value = object as? StructType {
            Logger.debug("StructCharacteristicProfile#dataValue: value = \(value.toRawValues())")
            return self.serialize(value.toRawValues())
        } else {
            return nil
        }
    }
    
    // PRIVATE
    private func deserialize(data:NSData) -> ([StructType.RawType1], [StructType.RawType2]) {
        switch self.endianness {
        case (Endianness.Little, Endianness.Little):
            return (StructType.RawType1.deserializeFromLittleEndian(data), StructType.RawType2.deserializeFromLittleEndian(data))
        case (Endianness.Big, Endianness.Little):
            return (StructType.RawType1.deserializeFromBigEndian(data), StructType.RawType2.deserializeFromLittleEndian(data))
        case (Endianness.Little, Endianness.Big):
            return (StructType.RawType1.deserializeFromLittleEndian(data), StructType.RawType2.deserializeFromBigEndian(data))
        case (Endianness.Big, Endianness.Big):
            return (StructType.RawType1.deserializeFromBigEndian(data), StructType.RawType2.deserializeFromBigEndian(data))
        }
    }
    
    private func serialize(rawValues:([StructType.RawType1], [StructType.RawType2])) -> NSData {
        let (rawValues1, rawValues2) = rawValues
        switch self.endianness {
        case (Endianness.Little, Endianness.Little):
            let data = NSMutableData()
            data.setData(NSData.serializeToLittleEndian(rawValues1))
            data.appendData(NSData.serializeToLittleEndian(rawValues2))
            return data
        case (Endianness.Big, Endianness.Little):
            let data = NSMutableData()
            data.setData(NSData.serializeToBigEndian(rawValues1))
            data.appendData(NSData.serializeToLittleEndian(rawValues2))
            return data
        case (Endianness.Little, Endianness.Big):
            let data = NSMutableData()
            data.setData(NSData.serializeToLittleEndian(rawValues1))
            data.appendData(NSData.serializeToBigEndian(rawValues2))
            return data
        case (Endianness.Big, Endianness.Big):
            let data = NSMutableData()
            data.setData(NSData.serializeToBigEndian(rawValues1))
            data.appendData(NSData.serializeToBigEndian(rawValues2))
            return data
        }
    }
    
}
