//
//  UInt16Extensions.swift
//  BlueCap
//
//  Created by Troy Stribling on 7/8/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation

extension UInt16 : DeserializeData {
    
    static func deserialize(data:NSData) -> UInt16 {
        var value : UInt16 = 0
        data.getBytes(&value, length:sizeof(UInt16))
        return value
    }
    
    static func deserialize(data:NSData, start:Int) -> UInt16 {
        var value : UInt16 = 0
        data.getBytes(&value, range: NSMakeRange(start, sizeof(UInt16)))
        return value
    }
    
}
