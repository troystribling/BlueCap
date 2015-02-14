//
//  NSDataExtensions.swift
//  BlueCap
//
//  Created by Troy Stribling on 6/29/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation

extension NSData : Serializable {
    
    public class func fromString(value:String, encoding:NSStringEncoding = NSUTF8StringEncoding) -> NSData? {
        return value.dataUsingEncoding(encoding).map{NSData(data:$0)}
    }
    
    public class func serialize<T>(value:T) -> NSData {
        let values = [fromHostByteOrder(value)]
        return NSData(bytes:values, length:sizeof(T))
    }
    
    public class func serialize<T>(values:[T]) -> NSData {
        let littleValues = values.map{fromHostByteOrder($0)}
        return NSData(bytes:littleValues, length:sizeof(T)*littleValues.count)
    }

    public class func serialize<T1, T2>(values:(T1, T2)) -> NSData {
        let (values1, values2) = values
        let data = NSMutableData()
        data.setData(NSData.serialize(values1))
        data.appendData(NSData.serialize(values2))
        return data
    }

    public class func serialize<T1, T2>(values:([T1], [T2])) -> NSData {
        let (values1, values2) = values
        let data = NSMutableData()
        data.setData(NSData.serialize(values1))
        data.appendData(NSData.serialize(values2))
        return data
    }

    public func hexStringValue() -> String {
        var dataBytes = [UInt8](count:self.length, repeatedValue:0x0)
        self.getBytes(&dataBytes, length:self.length)
        var hexString = dataBytes.reduce(""){(out:String, dataByte:UInt8) in
            return out + (NSString(format:"%02lx", dataByte) as! String)
        }
        return hexString
    }
    
}
