//
//  ServiceProfileUtils.swift
//  BlueCap
//
//  Created by Troy Stribling on 8/3/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import Foundation

func int16ValueFromStringValue(_ name:String, values: [String:String]) -> Int16? {
    if let value = values[name] {
        return Int16(value)
    } else {
        return nil
    }
}

func uint16ValueFromStringValue(_ name:String, values: [String:String]) -> UInt16? {
    if let value = values[name] {
        return UInt16(value)
    } else {
        return nil
    }
}

func int8ValueFromStringValue(_ name:String, values: [String:String]) -> Int8? {
    if let value = values[name] {
        return Int8(value)
    } else {
        return nil
    }
}

func uint8ValueFromStringValue(_ name:String, values: [String:String]) -> UInt8? {
    if let value = values[name] {
        return UInt8(value)
    } else {
        return nil
    }
}

