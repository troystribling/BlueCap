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
            struct Value : DeserializedStruct {
                static func fromRawValues(rawValues:[Int16]) -> Value? {
                    return nil                    
                }
                static func fromStrings(stringValues:Dictionary<String, String>) -> Value? {
                    return nil
                }
                var stringValues : Dictionary<String,String> {
                    return [:]
                }
                func toRawValues() -> [Int16] {
                    return [0]
                }
            }
        }
    }

}

public class GnosusProfiles {
    
    public class func create() {
        
        let profileManager = ProfileManager.sharedInstance()
        
        //***************************************************************************************************
        // Hello World Service
        //***************************************************************************************************
        profileManager.addService(ServiceProfile(uuid:Gnosus.HelloWorldService.uuid, name:Gnosus.HelloWorldService.name){(serviceProfile) in
            // Greeting
            serviceProfile.addCharacteristic(StringCharacteristicProfile(uuid:Gnosus.HelloWorldService.Greeting.uuid, name:Gnosus.HelloWorldService.Greeting.name)
                {(characteristicProfile) in
                })
            // Update Period
            serviceProfile.addCharacteristic(DeserializedCharacteristicProfile<UInt16>(uuid:Gnosus.HelloWorldService.UpdatePeriod.uuid, name:Gnosus.HelloWorldService.name)
                {(characteristicProfile) in
                })
        })

        //***************************************************************************************************
        // Location Service
        //***************************************************************************************************
        profileManager.addService(ServiceProfile(uuid:Gnosus.LocationService.uuid, name:Gnosus.LocationService.name){(serviceProfile) in
        })

    }
    
}
