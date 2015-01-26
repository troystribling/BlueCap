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

    static let tag = "Gnos.us"
    
    //***************************************************************************************************
    // Hello World Service
    public struct HelloWorldService : ServiceConfigurable {
        
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

            // RawDeserializable
            public let period : UInt16
            public var rawValue : UInt16 {
                return self.period
            }
            public init?(rawValue:UInt16) {
                self.period = rawValue
            }

            // BLEConfigurable
            public static let uuid                      = "2f0a0002-69aa-f316-3e78-4194989a6c1a"
            public static let name                      = "Update Period"
            public static let permissions               = CBAttributePermissions.Readable | CBAttributePermissions.Writeable
            public static let properties                = CBCharacteristicProperties.Read | CBCharacteristicProperties.Write
            public static let initialValue : NSData?    = serialize(UInt16(5000))
            
            // StringDeserializable
            public static var stringValues : [String] {
                return []
            }
            public var stringValue : [String:String] {
                return [UpdatePeriod.name:"\(self.period)"]
            }
            public init?(stringValue:[String:String]) {
                if let strVal = stringValue[UpdatePeriod.name] {
                    if let value = UInt16(stringValue:strVal) {
                        self.period = value
                    } else {
                        return nil
                    }
                } else {
                    return nil
                }
            }

        }
    }

    //***************************************************************************************************
    // Location Service
    public struct LocationService : ServiceConfigurable {
        public static let uuid  = "2f0a0001-69aa-f316-3e78-4194989a6c1a"
        public static let name  = "Location"
        public static let tag   = "gnos.us"
        
//        public struct LatitudeAndLongitude : RawArrayDeserializable, CharacteristicConfigurable, StringDeserializable {
//            public static let uuid          = "2f0a0017-69aa-f316-3e78-4194989a6c1a"
//            public static let name          = "Location Lattitude and Longitude"
//            public static let permissions   = CBAttributePermissions.Readable | CBAttributePermissions.Writeable
//            public static let properties    = CBCharacteristicProperties.Read | CBCharacteristicProperties.Notify
//            public static let initialValue  = serialize("Hello")
//
//                var latitudeRaw     : Int16
//                var longitudeRaw    : Int16
//                var latitude        : Double
//                var longitude       : Double
//                static func fromRawValues(rawValues:[Int16]) -> Value? {
//                    if rawValues.count == 2 {
//                        let (latitiude, longitude) = self.valuesFromRaw(rawValues)
//                        return Value(latitudeRaw:rawValues[0], longitudeRaw:rawValues[1], latitude:latitiude, longitude:longitude)
//                    } else {
//                        return nil
//                    }
//                }
//                static func fromStrings(stringValues:Dictionary<String, String>) -> Value? {
//                    let latitudeRaw = BlueCap.int16ValueFromStringValue("latitudeRaw", values:stringValues)
//                    let longitudeRaw = BlueCap.int16ValueFromStringValue("longitudeRaw", values:stringValues)
//                    if latitudeRaw != nil && longitudeRaw != nil {
//                        let (latitiude, longitude) = self.valuesFromRaw([latitudeRaw!, longitudeRaw!])
//                        return Value(latitudeRaw:latitudeRaw!, longitudeRaw:longitudeRaw!, latitude:latitiude, longitude:longitude)
//                    } else {
//                        return nil
//                    }
//                }
//                static func valuesFromRaw(rawValues:[Int16]) -> (Double, Double) {
//                    return (100.0*Double(rawValues[0]), 100.0*Double(rawValues[1]))
//                }
//                var stringValues : Dictionary<String,String> {
//                    return ["latitudeRaw":"\(latitudeRaw)", "longitudeRaw":"\(longitudeRaw)", "latitude":"\(latitude)", "longitude":"\(longitude)"]
//                }
//                func toRawValues() -> [Int16] {
//                    return [latitudeRaw, longitudeRaw]
//                }
//        }
    }

}

public class GnosusProfiles {

    public class func create() {
        
        let profileManager = ProfileManager.sharedInstance
        
        // Hello World Service
        let helloWorldService = ConfiguredServiceProfile<Gnosus.HelloWorldService>()
        let greetingCharacteristic = StringCharacteristicProfile<Gnosus.HelloWorldService.Greeting>()
        let updateCharacteristic = RawDeserializedCharacteristicProfile<Gnosus.HelloWorldService.UpdatePeriod>()
        helloWorldService.addCharacteristic(greetingCharacteristic)
        helloWorldService.addCharacteristic(updateCharacteristic)
        profileManager.addService(helloWorldService)

        // Location Service
//        profileManager.addService(ServiceProfile(uuid:Gnosus.LocationService.uuid, name:Gnosus.LocationService.name){(serviceProfile) in
//            serviceProfile.tag = "Gnos.us"
//            serviceProfile.addCharacteristic(StructCharacteristicProfile<Gnosus.LocationService.LatitudeAndLongitude.Value>(uuid:Gnosus.LocationService.LatitudeAndLongitude.uuid, name:Gnosus.LocationService.LatitudeAndLongitude.name)
//                {(characteristicProfile) in
//                    characteristicProfile.initialValue = NSData.serialize(Gnosus.LocationService.LatitudeAndLongitude.Value.fromRawValues([3776, -12242])?.toRawValues())
//                    characteristicProfile.properties = CBCharacteristicProperties.Read | CBCharacteristicProperties.Write
//                })
//        })

    }
    
}
