//
//  NSDataExtensions.swift
//  BlueCap
//
//  Created by Troy Stribling on 6/29/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation

extension NSData {
    func hexStringValue() -> String {
        var dataBytes = Array<Byte>(count:self.length, repeatedValue:0x0)
        self.getBytes(&dataBytes, length:self.length)
        return dataBytes.reduce(""){(out:String, byte:Byte) in
            return out + NSString(format:"%02lx", byte)
        }
    }
}
