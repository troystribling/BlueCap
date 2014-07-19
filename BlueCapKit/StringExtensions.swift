//
//  StringExtensions.swift
//  BlueCap
//
//  Created by Troy Stribling on 6/29/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation

extension String {

    subscript(r: Range<Int>) -> String {
        get {
            let startIndex = advance(self.startIndex, r.startIndex)
            let endIndex = advance(startIndex, r.endIndex - r.startIndex)
            return self[Range(start: startIndex, end: endIndex)]
        }
    }
    
    var floatValue : Float {
        return (self as NSString).floatValue
    }
    
    func dataFromHexString() -> NSData {
        var bytes : [Byte] = []
        for i in 0..<(countElements(self)/2) {
            let stringBytes = self[2*i..<2*i+2]
            let byte = strtol(stringBytes.bridgeToObjectiveC().UTF8String, nil, 16)
            bytes += Byte(byte)
        }
        return NSData(bytes:bytes, length:bytes.count)
    }
    
}