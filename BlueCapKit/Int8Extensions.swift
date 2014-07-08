//
//  Int8Extensions.swift
//  BlueCap
//
//  Created by Troy Stribling on 7/8/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation

extension Int8 : DeserializeData {
    
    static func deserialize(data:NSData) -> Int8 {
        var value : Int8 = 0
        data.getBytes(&value, length:sizeof(Int8))
        return value
    }
    
    static func deserialize(data:NSData, start:Int) -> Int8 {
        var value : Int8 = 0
        data.getBytes(&value, range: NSMakeRange(start, sizeof(Int8)))
        return value
    }
    
}
