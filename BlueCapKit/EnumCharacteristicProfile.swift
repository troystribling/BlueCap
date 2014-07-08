//
//  EnumCharacteristicProfile.swift
//  BlueCap
//
//  Created by Troy Stribling on 7/7/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation

protocol ProfileableEnumCharacteristic {
    typealias EnumType
    class func fromRaw(newValue:UInt8) -> EnumType?
    class func fromString(newValue:String) -> EnumType?
    var stringValue : String {get}
    func toRaw() -> UInt8
    
}

class EnumCharacteristicProfile<EnumType : ProfileableEnumCharacteristic> : CharacteristicProfile {
    
    var values : EnumType[]
    
    var value : EnumType {
        get {
            return self.values[0]
        }
        set(value) {
            self.value = value
        }
    }
    
    init(value:EnumType, uuid:String, name:String) {
        self.values = [value]
        super.init(uuid:uuid, name:name)
    }
    
    // APPLICATION INTERFACE
//    override func stringValue(data:NSData) -> Dictionary<String, String> {
//    }
//    
//    override func dataValue(data:Dictionary<String, String>) -> NSData {
//    }
//    
//    override func dataValue(object:Any) -> NSData {
//    }
    
}
