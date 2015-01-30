//
//  ServiceProfileUtils.swift
//  BlueCap
//
//  Created by Troy Stribling on 8/3/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation

func int16ValueFromStringValue(name:String, values:[String:String]) -> Int16? {
    if let value = values[name]?.toInt() {
        if value < -32768 || value > 32767 {
            return nil
        } else {
            return Int16(value)
        }
    } else {
        return nil
    }
}

func uint16ValueFromStringValue(name:String, values:[String:String]) -> UInt16? {
    if let value = values[name]?.toInt() {
        if value < 0 || value > 65535 {
            return nil
        } else {
            return UInt16(value)
        }
    } else {
        return nil
    }
}

func int8ValueFromStringValue(name:String, values:[String:String]) -> Int8? {
    if let value = values[name]?.toInt() {
        if value < -128 || value > 127 {
            return nil
        } else {
            return Int8(value)
        }
    } else {
        return nil
    }
}

func uint8ValueFromStringValue(name:String, values:[String:String]) -> UInt8? {
    if let value = values[name]?.toInt() {
        if value < 0 || value > 255 {
            return nil
        } else {
            return UInt8(value)
        }
    } else {
        return nil
    }
}

