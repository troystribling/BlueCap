//
//  NSDataExtensions.swift
//  BlueCap
//
//  Created by Troy Stribling on 6/29/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation

extension NSData : Serializable {
    
    public class func serializeToLittleEndian<SerializedType>(value:SerializedType) -> NSData {
        let values = [hostToLittleEndian(value)]
        return NSData(bytes:values, length:sizeof(SerializedType))
    }
    
    public class func serializeArrayToLittleEndian<SerializedType>(values:[SerializedType]) -> NSData {
        let littleValues = values.map{hostToLittleEndian($0)}
        return NSData(bytes:littleValues, length:sizeof(SerializedType)*littleValues.count)
    }

    public class func serializePairToLittleEndian<SerializedType1, SerializedType2>(values:(SerializedType1, SerializedType2)) -> NSData {
        let (values1, values2) = values
        let data = NSMutableData()
        data.setData(NSData.serializeToLittleEndian(values1))
        data.appendData(NSData.serializeToLittleEndian(values2))
        return data
    }

    public class func serializeArrayPairToLittleEndian<SerializedType1, SerializedType2>(values:([SerializedType1], [SerializedType2])) -> NSData {
        let (values1, values2) = values
        let data = NSMutableData()
        data.setData(NSData.serializeArrayToLittleEndian(values1))
        data.appendData(NSData.serializeArrayToLittleEndian(values2))
        return data
    }

    public func hexStringValue() -> String {
        var dataBytes = Array<Byte>(count:self.length, repeatedValue:0x0)
        self.getBytes(&dataBytes, length:self.length)
        var hexString = dataBytes.reduce(""){(out:String, dataByte:Byte) in
            out +  NSString(format:"%02lx", dataByte)
        }
        return hexString
    }
    
}
