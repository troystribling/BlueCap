//
//  Int16Extensions.swift
//  BlueCap
//
//  Created by Troy Stribling on 7/8/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation

extension Int16 : DeserializeData {
    
    static func deserialize(data:NSData) -> Int16 {
        var value : Int16 = 0
        data.getBytes(&value, length:sizeof(Int16))
        return value
    }
    
    static func deserialize(data:NSData, start:Int) -> Int16 {
        var value : Int16 = 0
        data.getBytes(&value, range: NSMakeRange(start, sizeof(Int16)))
        return value
    }
    
}
