//
//  ServiceProfileUtils.swift
//  BlueCap
//
//  Created by Troy Stribling on 8/3/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

//import Foundation
//
//public struct BlueCap {
//    static func int16ValueFromStringValue(name:String, values:Dictionary<String,String>) -> Int16? {
//        if let value = values[name]?.toInt() {
//            if value < -32768 {
//                return Int16(-32768)
//            } else if value > 32767 {
//                return Int16(32767)
//            } else {
//                return Int16(value)
//            }
//        } else {
//            return nil
//        }
//    }
//    static func uint16ValueFromStringValue(name:String, values:Dictionary<String,String>) -> UInt16? {
//        if let value = values[name]?.toInt() {
//            if value < 0 {
//                return UInt16(0)
//            } else if value > 65535 {
//                return UInt16(65535)
//            } else {
//                return UInt16(value)
//            }
//        } else {
//            return nil
//        }
//    }
//    static func int8ValueFromStringValue(name:String, values:Dictionary<String,String>) -> Int8? {
//        if let value = values[name]?.toInt() {
//            if value < -128 {
//                return Int8(-128)
//            } else if value > 127 {
//                return Int8(127)
//            } else {
//                return Int8(value)
//            }
//        } else {
//            return nil
//        }
//    }
//    static func uint8ValueFromStringValue(name:String, values:Dictionary<String,String>) -> UInt8? {
//        if let value = values[name]?.toInt() {
//            if value < 0 {
//                return UInt8(0)
//            } else if value > 255 {
//                return UInt8(255)
//            } else {
//                return UInt8(value)
//            }
//        } else {
//            return nil
//        }
//    }
//}
//
