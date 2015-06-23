//
//  ServiceProfileUtils.swift
//  BlueCap
//
//  Created by Troy Stribling on 8/3/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import Foundation

func int16ValueFromStringValue(name:String, _ values:[String:String]) -> Int16? {
    guard let value = Int(values[name]!) else {
        return nil
    }
    
    if value < -32768 || value > 32767 {
        return nil
    } else {
        return Int16(value)
    }
}

func uint16ValueFromStringValue(name:String, _ values:[String:String]) -> UInt16? {
    guard let value = Int(values[name]!) else {
        return nil
    }
    
    if value < 0 || value > 65535 {
        return nil
    } else {
        return UInt16(value)
    }
}

func int8ValueFromStringValue(name:String, _ values:[String:String]) -> Int8? {
    guard let value = Int(values[name]!) else {
        return nil
    }
    
    if value < -128 || value > 127 {
        return nil
    } else {
        return Int8(value)
    }
}

func uint8ValueFromStringValue(name:String, _ values:[String:String]) -> UInt8? {
    guard let value = Int(values[name]!) else {
        return nil
    }
    
    if value < 0 || value > 255 {
        return nil
    } else {
        return UInt8(value)
    }
}

