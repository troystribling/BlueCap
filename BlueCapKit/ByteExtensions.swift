//
//  ByteExtensions.swift
//  BlueCap
//
//  Created by Troy Stribling on 7/8/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation

extension Byte : Deserialized {
    
    static func deserialize(data:NSData) -> Byte {
        var value : Byte = 0
        data.getBytes(&value, length:sizeof(Byte))
        return value
    }
    
    static func deserialize(data:NSData, start:Int) -> Byte {
        var value : Byte = 0
        data.getBytes(&value, range: NSMakeRange(start, sizeof(Byte)))
        return value
    }
    
    static func deserializeFromLittleEndian(data:NSData) -> Byte {
        return deserialize(data)
    }
    
    static func deserializeFromLittleEndian(data:NSData) -> Byte[] {
        return []
    }
    
    static func deserializeFromLittleEndian(data:NSData, start:Int) -> Byte {
        return deserialize(data, start:start)
    }
    
    static func deserializeFromBigEndian(data:NSData) -> Byte {
        return deserialize(data)
    }
    
    static func deserializeFromBigEndian(data:NSData) -> Byte[] {
        return []
    }
    
    static func deserializeFromBigEndian(data:NSData, start:Int) -> Byte {
        return deserialize(data, start:start)
    }

}
