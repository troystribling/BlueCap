//
//  EnumCharacteristicProfile.swift
//  BlueCap
//
//  Created by Troy Stribling on 7/7/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation

protocol ProfileableEnumStatic {
    typealias EnumType
    class func fromRaw(newValue:Byte) -> EnumType?
    class func fromString(newValue:String) -> EnumType?
    class func stringValues() -> String[]
    
}

protocol ProfileableEnumInstance {
    var stringValue : String {get}
    func toRaw() -> Byte
}

class EnumCharacteristicProfile<EnumType:ProfileableEnumStatic where EnumType.EnumType:ProfileableEnumInstance> : CharacteristicProfile {
    
    var stringValues : String[] {
        return EnumType.stringValues()
    }
    
    init(uuid:String, name:String) {
        super.init(uuid:uuid, name:name)
    }
    
    // APPLICATION INTERFACE
    override func stringValue(data:NSData) -> Dictionary<String, String>? {
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
        if let value = object as? EnumType.EnumType {
           return NSData.serialize(value.toRaw())
        } else {
            return nil
        }
    }
    
    
}
