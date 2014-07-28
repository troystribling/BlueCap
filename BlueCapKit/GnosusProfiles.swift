//
//  GnosusProfiles.swift
//  BlueCap
//
//  Created by Troy Stribling on 7/25/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation
import CoreBluetooth
import BlueCapKit

public struct BlueCap {
    static func int16ValueFromStringValue(name:String, values:Dictionary<String,String>) -> Int16? {
        if let value = values[name]?.toInt() {
            if value < -32768 {
                return Int16(-32768)
            } else if value > 32767 {
                return Int16(32767)
            } else {
                return Int16(value)
            }
        } else {
            return nil
        }
    }
    static func uint16ValueFromStringValue(name:String, values:Dictionary<String,String>) -> UInt16? {
        if let value = values[name]?.toInt() {
            if value < 0 {
                return UInt16(0)
            } else if value > 65535 {
                return UInt16(65535)
            } else {
                return UInt16(value)
            }
        } else {
            return nil
        }
    }
    static func int8ValueFromStringValue(name:String, values:Dictionary<String,String>) -> Int8? {
        if let value = values[name]?.toInt() {
            if value < -128 {
                return Int8(-128)
            } else if value > 127 {
                return Int8(127)
            } else {
                return Int8(value)
            }
        } else {
            return nil
        }
    }
    static func uint8ValueFromStringValue(name:String, values:Dictionary<String,String>) -> UInt8? {
        if let value = values[name]?.toInt() {
            if value < 0 {
                return UInt8(0)
            } else if value > 255 {
                return UInt8(255)
            } else {
                return UInt8(value)
            }
        } else {
            return nil
        }
    }
}

public struct Gnosus {
  
    //***************************************************************************************************
    // Hello World Service
    //***************************************************************************************************
    struct HelloWorldService {
        static let uuid = "2f0a0000-69aa-f316-3e78-4194989a6c1a"
        static let name = "Gnosus Hello World"
        struct Greeting {
            static let uuid = "2f0a0001-69aa-f316-3e78-4194989a6c1a"
            static let name = "Hello World Greeting"
        }
        struct UpdatePeriod {
            static let uuid = "2f0a0002-69aa-f316-3e78-4194989a6c1a"
            static let name = "Hello World Update Period"
        }
    }

    //***************************************************************************************************
    // Location Service
    //***************************************************************************************************
    struct LocationService {
        static let uuid = "2f0a0001-69aa-f316-3e78-4194989a6c1a"
        static let name = "Gnosus Location"
        struct LatitudeAndLongitude {
            static let uuid = "2f0a0017-69aa-f316-3e78-4194989a6c1a"
            static let name = "Location Lattitude and Longitude"
        }
    }

    //***************************************************************************************************
    // Epoc Time Service
    //***************************************************************************************************
    struct EpocTimeService {
        static let uuid = "2f0a0002-69aa-f316-3e78-4194989a6c1a"
        static let name = "Gnosus Epoc Time"
        struct  Data {
            static let uuid = "2f0a0026-69aa-f316-3e78-4194989a6c1a"
            static let name = "Epoc Time Data"
        }
    }    
}

public class GnosusProfiles {
    
    public class func create() {
        
        let profileManager = ProfileManager.sharedInstance()
        
        //***************************************************************************************************
        // Hello World Service
        //***************************************************************************************************
        profileManager.addService(ServiceProfile(uuid:Gnosus.HelloWorldService.uuid, name:Gnosus.HelloWorldService.name){(serviceProfile:ServiceProfile) in
        })

        //***************************************************************************************************
        // Location Service
        //***************************************************************************************************
        profileManager.addService(ServiceProfile(uuid:Gnosus.LocationService.uuid, name:Gnosus.LocationService.name){(serviceProfile:ServiceProfile) in
        })

        //***************************************************************************************************
        // Epoc Time Service
        //***************************************************************************************************
        profileManager.addService(ServiceProfile(uuid:Gnosus.EpocTimeService.uuid, name:Gnosus.EpocTimeService.name){(serviceProfile:ServiceProfile) in
        })

    }
    
}
