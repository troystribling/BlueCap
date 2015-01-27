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

public struct Gnosus {

    //***************************************************************************************************
    // Hello World Service
    public struct HelloWorldService : ServiceConfigurable {
        
        // ServiceConfigurable
        public static let uuid = "2f0a0000-69aa-f316-3e78-4194989a6c1a"
        public static let name = "Hello World"
        public static let tag  = "gnos.us"
        
        public struct Greeting : CharacteristicConfigurable {

            // BLEConfigurable
            public static let uuid         = "2f0a0001-69aa-f316-3e78-4194989a6c1a"
            public static let name         = "Hello World Greeting"
            public static let permissions  = CBAttributePermissions.Readable | CBAttributePermissions.Writeable
            public static let properties   = CBCharacteristicProperties.Read | CBCharacteristicProperties.Notify
            public static let initialValue = serialize("Hello")
            
        }
        
        public struct UpdatePeriod : RawDeserializable, CharacteristicConfigurable, StringDeserializable {

            public let period : UInt16

            // CharacteristicConfigurable
            public static let uuid                      = "2f0a0002-69aa-f316-3e78-4194989a6c1a"
            public static let name                      = "Update Period"
            public static let permissions               = CBAttributePermissions.Readable | CBAttributePermissions.Writeable
            public static let properties                = CBCharacteristicProperties.Read | CBCharacteristicProperties.Write
            public static let initialValue : NSData?    = serialize(UInt16(5000))
            
            // RawDeserializable
            public var rawValue : UInt16 {
                return self.period
            }
            public init?(rawValue:UInt16) {
                self.period = rawValue
            }

            // StringDeserializable
            public static var stringValues : [String] {
                return []
            }
            public var stringValue : [String:String] {
                return [UpdatePeriod.name:"\(self.period)"]
            }
            public init?(stringValue:[String:String]) {
                if let value = uint16ValueFromStringValue(UpdatePeriod.name, stringValue) {
                    self.period = value
                } else {
                    return nil
                }
            }

        }
    }

    //***************************************************************************************************
    // Location Service
    public struct LocationService : ServiceConfigurable {

        // ServiceConfigurable
        public static let uuid  = "2f0a0001-69aa-f316-3e78-4194989a6c1a"
        public static let name  = "Location"
        public static let tag   = "gnos.us"
        
        public struct LatitudeAndLongitude : RawArrayDeserializable, CharacteristicConfigurable, StringDeserializable {

            private let rawLatitude     : Int16
            private let rawLongitude    : Int16
            public let latitude         : Double
            public let longitude        : Double

            // CharacteristicConfigurable
            public static let uuid          = "2f0a0017-69aa-f316-3e78-4194989a6c1a"
            public static let name          = "Lattitude and Longitude"
            public static let permissions   = CBAttributePermissions.Readable | CBAttributePermissions.Writeable
            public static let properties    = CBCharacteristicProperties.Read | CBCharacteristicProperties.Write
            public static let initialValue  = serialize(Gnosus.LocationService.LatitudeAndLongitude(rawValue:[3776, -12242]))

            // RawArrayDeserializable
            public var rawValue : [Int16] {
                return [rawLatitude, rawLongitude]
            }
            
            public init?(rawValue:[Int16]) {
                if rawValue.count == 2 {
                    self.rawLatitude = rawValue[0]
                    self.rawLongitude = rawValue[1]
                    self.latitude = 100.0*Double(self.rawLatitude)
                    self.longitude = 100.0*Double(self.rawLongitude)
                } else {
                    return nil
                }
            }
            
            // StringDeserializable
            public static var stringValues  : [String] {
                return []
            }
            
            public var stringValue  : [String:String] {
                return ["rawLatitude":"\(self.rawLatitude)",
                        "rawLongitude":"\(self.rawLongitude)",
                        "latitude":"\(self.latitude)",
                        "longitude":"\(self.longitude)"]
            }
            
            public init?(stringValue:[String:String]) {
                let lat = int16ValueFromStringValue("rawLatitude", stringValue)
                let lon = int16ValueFromStringValue("rawLongitude", stringValue)
                if lat != nil && lon != nil {
                    self.rawLatitude = lat!
                    self.rawLongitude = lon!
                    self.latitude = 100.0*Double(self.rawLatitude)
                    self.longitude = 100.0*Double(self.rawLongitude)
                } else {
                    return nil
                }
            }
            
        }
    }

}

public struct GnosusProfiles {

    public static func create() {
        
        let profileManager = ProfileManager.sharedInstance
        
        // Hello World Service
        let helloWorldService = ConfiguredServiceProfile<Gnosus.HelloWorldService>()
        let greetingCharacteristic = StringCharacteristicProfile<Gnosus.HelloWorldService.Greeting>()
        let updateCharacteristic = RawDeserializedCharacteristicProfile<Gnosus.HelloWorldService.UpdatePeriod>()
        helloWorldService.addCharacteristic(greetingCharacteristic)
        helloWorldService.addCharacteristic(updateCharacteristic)
        profileManager.addService(helloWorldService)

        // Location Service
        let locationService = ConfiguredServiceProfile<Gnosus.LocationService>()
        let latlonCharacteristic = RawArrayCharacteristicProfile<Gnosus.LocationService.LatitudeAndLongitude>()
        locationService.addCharacteristic(latlonCharacteristic)
        profileManager.addService(locationService)

    }
    
}
