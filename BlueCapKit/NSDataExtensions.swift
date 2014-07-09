//
//  NSDataExtensions.swift
//  BlueCap
//
//  Created by Troy Stribling on 6/29/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation

extension NSData : Serialized {

    class func serialize<SerializedType>(value:SerializedType) -> NSData {
        return NSData(bytes:[value], length:sizeof(SerializedType))
    }
    
    class func serialize<SerializedType>(values:SerializedType[]) -> NSData {
        return NSData(bytes:values, length:values.count*sizeof(SerializedType))
    }
    
    class func serializeToLittleEndian<SerializedType>(value:SerializedType) -> NSData {
        return NSData(bytes:[hostToLittleEndian(value)], length:sizeof(SerializedType))
    }
    
    class func serializeToLittleEndian<SerializedType>(values:SerializedType[]) -> NSData {
        let littleValues = values.map{value in hostToLittleEndian(value)}
        return NSData(bytes:littleValues, length:sizeof(SerializedType)*littleValues.count)
    }
    
    class func serializeToBigEndian<SerializedType>(value:SerializedType) -> NSData {
        return NSData(bytes:[hostToBigEndian(value)], length:sizeof(SerializedType))
    }
    
    class func serializeToBigEndian<SerializedType>(values:SerializedType[]) -> NSData {
        let bigValues = values.map{value in hostToBigEndian(value)}
        return NSData(bytes:bigValues, length:sizeof(SerializedType)*bigValues.count)
    }

    func hexStringValue() -> String {
        var dataBytes = Array<Byte>(count:self.length, repeatedValue:0x0)
        self.getBytes(&dataBytes, length:self.length)
        var hexString = dataBytes.reduce(""){(out:String, dataByte:Byte) in
            out +  NSString(format:"%02lx", dataByte)
        }
        return hexString
    }
    
}
