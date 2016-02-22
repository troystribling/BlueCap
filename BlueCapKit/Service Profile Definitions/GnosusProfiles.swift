//
//  GnosusProfiles.swift
//  BlueCap
//
//  Created by Troy Stribling on 7/25/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import Foundation
import CoreBluetooth

// MARK: - Gnosus -
public struct Gnosus {

    // MARK: - Hello World Service -
    public struct HelloWorldService: BCServiceConfigurable {
        
        // ServiceConfigurable
        public static let UUID = "2f0a0000-69aa-f316-3e78-4194989a6c1a"
        public static let name = "Hello World"
        public static let tag  = "gnos.us"
        
        public struct Greeting : BCCharacteristicConfigurable {

            // BLEConfigurable
            public static let UUID                                     = "2f0a0001-69aa-f316-3e78-4194989a6c1a"
            public static let name                                     = "Hello World Greeting"
            public static let permissions: CBAttributePermissions      = [.Readable, .Writeable]
            public static let properties: CBCharacteristicProperties   = [.Read, .Notify]
            public static let initialValue                             = BCSerDe.serialize("Hello")
            
        }
        
        public struct UpdatePeriod: BCRawDeserializable, BCCharacteristicConfigurable, BCStringDeserializable {

            public let period : UInt16

            // CharacteristicConfigurable
            public static let UUID                                      = "2f0a0002-69aa-f316-3e78-4194989a6c1a"
            public static let name                                      = "Update Period"
            public static let permissions: CBAttributePermissions       = [.Readable, .Writeable]
            public static let properties: CBCharacteristicProperties    = [.Read, .Write]
            public static let initialValue: NSData?                     = BCSerDe.serialize(UInt16(5000))
            
            // RawDeserializable
            public var rawValue: UInt16 {
                return self.period
            }
            public init?(rawValue: UInt16) {
                self.period = rawValue
            }

            // StringDeserializable
            public static var stringValues: [String] {
                return []
            }
            
            public var stringValue: [String: String] {
                return [UpdatePeriod.name:"\(self.period)"]
            }
            
            public init?(stringValue: [String: String]) {
                if let value = uint16ValueFromStringValue(UpdatePeriod.name, values:stringValue) {
                    self.period = value
                } else {
                    return nil
                }
            }

        }
    }

    // MARK: - Location Service -
    public struct LocationService: BCServiceConfigurable {

        // ServiceConfigurable
        public static let UUID  = "2f0a0001-69aa-f316-3e78-4194989a6c1a"
        public static let name  = "Location"
        public static let tag   = "gnos.us"
        
        public struct LatitudeAndLongitude : BCRawArrayDeserializable, BCCharacteristicConfigurable, BCStringDeserializable {

            private let latitudeRaw: Int16
            private let longitudeRaw: Int16
            public let latitude: Double
            public let longitude: Double

            public init?(latitude: Double, longitude: Double) {
                self.latitude = latitude
                self.longitude = longitude
                if let rawValues = LatitudeAndLongitude.rawFromValues([latitude, longitude]) {
                    (self.latitudeRaw, self.longitudeRaw) = rawValues
                } else {
                    return nil
                }
            }
            
            private static func valuesFromRaw(rawValues: [Int16]) -> (Double, Double) {
                return (100.0*Double(rawValues[0]), 100.0*Double(rawValues[1]))
            }
            
            private static func rawFromValues(values: [Double]) -> (Int16, Int16)? {
                let latitudeRaw = Int16(doubleValue: values[0]/100.0)
                let longitudeRaw = Int16(doubleValue: values[1]/100.0)
                if latitudeRaw != nil && longitudeRaw != nil {
                    return (latitudeRaw!, longitudeRaw!)
                } else {
                    return nil
                }
            }
            
            // CharacteristicConfigurable
            public static let UUID                                      = "2f0a0017-69aa-f316-3e78-4194989a6c1a"
            public static let name                                      = "Lattitude and Longitude"
            public static let permissions: CBAttributePermissions       = [.Readable, .Writeable]
            public static let properties: CBCharacteristicProperties    = [.Read, .Write]
            public static let initialValue: NSData?                     = BCSerDe.serialize(Gnosus.LocationService.LatitudeAndLongitude(latitude:37.752760, longitude:-122.413234)!)

            // RawArrayDeserializable
            public static let size = 4

            public var rawValue: [Int16] {
                return [self.latitudeRaw, self.longitudeRaw]
            }
            
            public init?(rawValue: [Int16]) {
                if rawValue.count == 2 {
                    self.latitudeRaw = rawValue[0]
                    self.longitudeRaw = rawValue[1]
                    (self.latitude, self.longitude) = LatitudeAndLongitude.valuesFromRaw(rawValue)
                } else {
                    return nil
                }
            }
            
            // StringDeserializable
            public static var stringValues: [String] {
                return []
            }
            
            public var stringValue: [String: String] {
                return ["latitudeRaw":"\(self.latitudeRaw)",
                        "longitudeRaw":"\(self.longitudeRaw)",
                        "latitude":"\(self.latitude)",
                        "longitude":"\(self.longitude)"]
            }
            
            public init?(stringValue: [String: String]) {
                let lat = int16ValueFromStringValue("latitudeRaw", values: stringValue)
                let lon = int16ValueFromStringValue("longitudeRaw", values: stringValue)
                if lat != nil && lon != nil {
                    self.latitudeRaw = lat!
                    self.longitudeRaw = lon!
                    (self.latitude, self.longitude) = LatitudeAndLongitude.valuesFromRaw([self.latitudeRaw, self.longitudeRaw])
                } else {
                    return nil
                }
            }
            
        }
    }

}

// MARK: - Profile Definition -
public struct GnosusProfiles {

    public static func create() {
        
        let profileManager = BCProfileManager.sharedInstance
        
        // Hello World Service
        let helloWorldService = BCConfiguredServiceProfile<Gnosus.HelloWorldService>()
        let greetingCharacteristic = BCStringCharacteristicProfile<Gnosus.HelloWorldService.Greeting>()
        let updateCharacteristic = BCRawCharacteristicProfile<Gnosus.HelloWorldService.UpdatePeriod>()
        helloWorldService.addCharacteristic(greetingCharacteristic)
        helloWorldService.addCharacteristic(updateCharacteristic)
        profileManager.addService(helloWorldService)

        // Location Service
        let locationService = BCConfiguredServiceProfile<Gnosus.LocationService>()
        let latlonCharacteristic = BCRawArrayCharacteristicProfile<Gnosus.LocationService.LatitudeAndLongitude>()
        locationService.addCharacteristic(latlonCharacteristic)
        profileManager.addService(locationService)

    }
    
}
