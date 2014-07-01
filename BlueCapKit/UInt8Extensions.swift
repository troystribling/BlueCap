//
//  UInt8Extensions.swift
//  BlueCap
//
//  Created by Troy Stribling on 6/30/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation

extension UInt8 {
    
    func DataValue() -> NSData {
        var buffer = self
        return NSData(bytes:&buffer, length:1)
    }
    
}