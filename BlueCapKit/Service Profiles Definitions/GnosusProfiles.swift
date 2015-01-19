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

//public struct Gnosus {
//  
//    //***************************************************************************************************
//    // Hello World Service
//    //***************************************************************************************************
//    struct HelloWorldService {
//        static let uuid = "2f0a0000-69aa-f316-3e78-4194989a6c1a"
//        static let name = "Gnosus Hello World"
//        struct Greeting {
//            static let uuid = "2f0a0001-69aa-f316-3e78-4194989a6c1a"
//            static let name = "Hello World Greeting"
//        }
//        struct UpdatePeriod {
//            static let uuid = "2f0a0002-69aa-f316-3e78-4194989a6c1a"
//            static let name = "Hello World Update Period"
//        }
//    }
//
//    //***************************************************************************************************
//    // Location Service
//    //***************************************************************************************************
//    struct LocationService {
//        static let uuid = "2f0a0001-69aa-f316-3e78-4194989a6c1a"
//        static let name = "Gnosus Location"
//        struct LatitudeAndLongitude {
//            static let uuid = "2f0a0017-69aa-f316-3e78-4194989a6c1a"
//            static let name = "Location Lattitude and Longitude"
//            struct Value : DeserializedStruct {
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
//            }
//        }
//    }
//
//}
//
//public class GnosusProfiles {
//    
//    public class func create() {
//        
//        let profileManager = ProfileManager.sharedInstance
//        
//        //***************************************************************************************************
//        // Hello World Service
//        //***************************************************************************************************
//        profileManager.addService(ServiceProfile(uuid:Gnosus.HelloWorldService.uuid, name:Gnosus.HelloWorldService.name){(serviceProfile) in
//            serviceProfile.tag = "Gnos.us"
//            // Greeting
//            serviceProfile.addCharacteristic(StringCharacteristicProfile(uuid:Gnosus.HelloWorldService.Greeting.uuid, name:Gnosus.HelloWorldService.Greeting.name)
//                {(characteristicProfile) in
//                    characteristicProfile.initialValue = "Hello".dataUsingEncoding(NSUTF8StringEncoding)
//                    characteristicProfile.properties = CBCharacteristicProperties.Read | CBCharacteristicProperties.Notify
//                })
//            // Update Period
//            serviceProfile.addCharacteristic(DeserializedCharacteristicProfile<UInt16>(uuid:Gnosus.HelloWorldService.UpdatePeriod.uuid, name:Gnosus.HelloWorldService.name)
//                {(characteristicProfile) in
//                    characteristicProfile.initialValue = NSData.serialize(UInt16(5000))
//                    characteristicProfile.properties = CBCharacteristicProperties.Read | CBCharacteristicProperties.Write
//                })
//        })
//
//        //***************************************************************************************************
//        // Location Service
//        //***************************************************************************************************
//        profileManager.addService(ServiceProfile(uuid:Gnosus.LocationService.uuid, name:Gnosus.LocationService.name){(serviceProfile) in
//            serviceProfile.tag = "Gnos.us"
//            serviceProfile.addCharacteristic(StructCharacteristicProfile<Gnosus.LocationService.LatitudeAndLongitude.Value>(uuid:Gnosus.LocationService.LatitudeAndLongitude.uuid, name:Gnosus.LocationService.LatitudeAndLongitude.name)
//                {(characteristicProfile) in
//                    characteristicProfile.initialValue = NSData.serialize(Gnosus.LocationService.LatitudeAndLongitude.Value.fromRawValues([3776, -12242])?.toRawValues())
//                    characteristicProfile.properties = CBCharacteristicProperties.Read | CBCharacteristicProperties.Write
//                })
//        })
//
//    }
//    
//}
