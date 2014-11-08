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
    
    // PRIVATE
    private let profile                         : CharacteristicProfile!
    private var _value                          : NSData!
    
    // INTERNAL
    internal let cbMutableChracteristic         : CBMutableCharacteristic!
    internal var processWriteRequestCallback    : ((request:CBATTRequest!)->())?
    
    // PUBLIC
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
    
    public var stringValues : Dictionary<String, String>? {
        if self.value != nil {
            return self.profile.stringValues(self.value)
        } else {
            return nil
        }
    }
    
    public var anyValue : Any? {
        if self.value != nil {
            return self.profile.anyValue(self.value)
        } else {
            return nil
        }
    }
    
    public var discreteStringValues : [String] {
        return self.profile.discreteStringValues
    }
    
    public func startProcessingWriteRequests(processWriteRequestCallback:(request:CBATTRequest!)->()) {
        self.processWriteRequestCallback = processWriteRequestCallback
    }
    
    public func stopProcessingWriteRequests() {
        self.processWriteRequestCallback = nil
    }
    
    public func respondToRequest(request:CBATTRequest, withResult result:CBATTError) {
        PeripheralManager.sharedInstance().cbPeripheralManager.respondToRequest(request, withResult:result)
    }
    
    public func propertyEnabled(property:CBCharacteristicProperties) -> Bool {
        return (self.properties.rawValue & property.rawValue) > 0
    }
    
    public func permissionEnabled(permission:CBAttributePermissions) -> Bool {
        return (self.permissions.rawValue & permission.rawValue) > 0
    }
    
    public func updateValue(value:NSData) {
        self._value = value
        PeripheralManager.sharedInstance().cbPeripheralManager.updateValue(value, forCharacteristic:self.cbMutableChracteristic, onSubscribedCentrals:nil)
    }
    
    public func updateValueWithString(value:Dictionary<String, String>) {
        if let data = self.profile.dataFromStringValue(value) {
            self.updateValue(data)
        } else {
            NSException(name:"Characteristic update error", reason: "invalid value '\(value)' for \(self.uuid.UUIDString)", userInfo: nil).raise()
        }
    }
    
    public func updateValueWithAny(value:Any) {
        if let data = self.profile.dataFromAnyValue(value) {
            self.updateValue(data)
        } else {
            NSException(name:"Characteristic update error", reason: "invalid value '\(value)' for \(self.uuid.UUIDString)", userInfo: nil).raise()
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
    
}