//
//  MutableCharacteristic.swift
//  BlueCap
//
//  Created by Troy Stribling on 8/9/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation
import CoreBluetooth

public class MutableCharacteristic : NSObject {
    
    private let profile                         : CharacteristicProfile!
    private var _value                          : NSData!
    
    internal let cbMutableChracteristic         : CBMutableCharacteristic!
    internal var processWriteRequestPromise     : StreamPromise<CBATTRequest>?
    
    public var permissions : CBAttributePermissions {
        return self.cbMutableChracteristic.permissions
    }
    
    public var properties : CBCharacteristicProperties {
        return self.cbMutableChracteristic.properties
    }
    
    public var uuid : CBUUID {
        return self.profile.uuid
    }
    
    public var name : String {
        return self.profile.name
    }
    
    public var value : NSData! {
        get {
            return self._value
        }
        set {
            self._value = newValue
        }
    }
    
    public var stringValue : Dictionary<String, String>? {
        if self.value != nil {
            return self.profile.stringValue(self.value)
        } else {
            return nil
        }
    }
    
    public class func withProfiles(profiles:[CharacteristicProfile]) -> [MutableCharacteristic] {
        return profiles.map{MutableCharacteristic(profile:$0)}
    }
    
    public init(profile:CharacteristicProfile) {
        super.init()
        self.profile = profile
        self._value = self.profile.initialValue
        self.cbMutableChracteristic = CBMutableCharacteristic(type:profile.uuid, properties:profile.properties, value:nil, permissions:profile.permissions)
    }
    
    public var discreteStringValues : [String] {
        return self.profile.discreteStringValues
    }
    
    public func startProcessingWriteRequests(capacity:Int? = nil) -> FutureStream<CBATTRequest> {
        if let capacity = capacity {
            self.processWriteRequestPromise = StreamPromise<CBATTRequest>(capacity:capacity)
        } else {
            self.processWriteRequestPromise = StreamPromise<CBATTRequest>()
        }
        return self.processWriteRequestPromise!.future
    }
    
    public func stopProcessingWriteRequests() {
        self.processWriteRequestPromise = nil
    }
    
    public func respondToRequest(request:CBATTRequest, withResult result:CBATTError) {
        PeripheralManager.sharedInstance.cbPeripheralManager.respondToRequest(request, withResult:result)
    }
    
    public func propertyEnabled(property:CBCharacteristicProperties) -> Bool {
        return (self.properties.rawValue & property.rawValue) > 0
    }
    
    public func permissionEnabled(permission:CBAttributePermissions) -> Bool {
        return (self.permissions.rawValue & permission.rawValue) > 0
    }
    
    public func updateValueWithData(value:NSData) {
        self._value = value
        PeripheralManager.sharedInstance.cbPeripheralManager.updateValue(value, forCharacteristic:self.cbMutableChracteristic, onSubscribedCentrals:nil)
    }
    
    public func updateValueWithString(value:Dictionary<String, String>) {
        if let data = self.profile.dataFromStringValue(value) {
            self.updateValueWithData(data)
        } else {
            NSException(name:"Characteristic update error", reason: "invalid value '\(value)' for \(self.uuid.UUIDString)", userInfo: nil).raise()
        }
    }
    
    public func updateValue<T:Deserializable>(value:T) {
        self.updateValueWithData(serialize(value))
    }

    public func updateValue<T:RawDeserializable>(value:T) {
        self.updateValueWithData(serialize(value))
    }

    public func updateValue<T:RawArrayDeserializable>(value:T) {
        self.updateValueWithData(serialize(value))
    }

    public func updateValue<T:RawPairDeserializable>(value:T) {
        self.updateValueWithData(serialize(value))
    }

    public func updateValue<T:RawArrayPairDeserializable>(value:T) {
        self.updateValueWithData(serialize(value))
    }

}