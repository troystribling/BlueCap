//
//  StringCharacteristicProfile.swift
//  BlueCap
//
//  Created by Troy Stribling on 7/26/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation
import CoreBluetooth

class StringCharacteristicProfile : CharacteristicProfile {
    
    var encoding : NSStringEncoding = NSUTF8StringEncoding
    
    // APPLICATION INTERFACE
    init(uuid:String, name:String, profile:((characteristic:StringCharacteristicProfile) -> ())? = nil) {
        super.init(uuid:uuid, name:name)
        if let runProfile = profile {
            runProfile(characteristic:self)
        }
    }
    
    convenience init(uuid: String, name: String, encoding:NSStringEncoding, profile:((characteristic:StringCharacteristicProfile) -> ())? = nil) {
        self.init(uuid:uuid, name:name, profile:profile)
        self.encoding = encoding
    }
    
    override func stringValues(data:NSData) -> Dictionary<String, String>? {
        let value = NSString(data:data, encoding:self.encoding)
        return [self.name:value]
    }
    
    override func anyValue(data:NSData) -> Any? {
        return NSString(data:data, encoding:self.encoding)
    }
    
    override func dataValue(data:Dictionary<String, String>) -> NSData? {
        if let value = data[self.name] {
            return self.dataValue(value)
        } else {
            return nil
        }
    }
    
    override func dataValue(object:Any) -> NSData? {
        if let value = object as? String {
            return value.dataUsingEncoding(self.encoding)
        } else {
            return nil
        }
    }
}
