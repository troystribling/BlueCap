//
//  MutableCharacteristic.swift
//  BlueCap
//
//  Created by Troy Stribling on 8/9/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation
import CoreBluetooth

///////////////////////////////////////////
// MutableCharacteristicImpl
public protocol MutableCharacteristicWrappable {
    
    typealias RequestWrapper
    typealias ResultWrapper
  
    var uuid            : CBUUID            {get}
    var name            : String            {get}
    var value           : NSData!           {get}
    var stringValues    : [String]          {get}
    var stringValue     : [String:String]?  {get}

    func propertyEnabled(property:CBCharacteristicProperties) -> Bool
    func permissionEnabled(permission:CBAttributePermissions) -> Bool
    
    func dataFromStringValue(stringValue:[String:String]) -> NSData?
    
    func updateValueWithData(value:NSData)
    func respondToWrappedRequest(request:RequestWrapper, withResult result:ResultWrapper)
}

public protocol CBATTRequestWrappable {
    
}

public protocol CBATTErrorWrappable {
    
}

public final class MutableCharacteristicImpl<Wrapper where Wrapper:MutableCharacteristicWrappable,
                                                           Wrapper.RequestWrapper:CBATTRequestWrappable,
                                                           Wrapper.ResultWrapper:CBATTErrorWrappable> {
    
    internal var processWriteRequestPromise : StreamPromise<Wrapper.RequestWrapper>?
    
    public init() {
    }
    
    public func startRespondingToWriteRequests(capacity:Int? = nil) -> FutureStream<Wrapper.RequestWrapper> {
        if let capacity = capacity {
            self.processWriteRequestPromise = StreamPromise<Wrapper.RequestWrapper>(capacity:capacity)
        } else {
            self.processWriteRequestPromise = StreamPromise<Wrapper.RequestWrapper>()
        }
        return self.processWriteRequestPromise!.future
    }
    
    public func stopProcessingWriteRequests() {
        self.processWriteRequestPromise = nil
    }
    
    public func respondToRequest(characteristic:Wrapper, request:Wrapper.RequestWrapper, withResult result:Wrapper.ResultWrapper) {
        characteristic.respondToWrappedRequest(request, withResult:result)
    }
    
    
    public func updateValue<T:Deserializable>(characteristic:Wrapper, value:T) {
        return characteristic.updateValueWithData(Serde.serialize(value))
    }
    
    public func updateValue<T:RawDeserializable>(characteristic:Wrapper, value:T) {
        return characteristic.updateValueWithData(Serde.serialize(value))
    }
    
    public func updateValue<T:RawArrayDeserializable>(characteristic:Wrapper, value:T) {
        return characteristic.updateValueWithData(Serde.serialize(value))
    }
    
    public func updateValue<T:RawPairDeserializable>(characteristic:Wrapper, value:T) {
        return characteristic.updateValueWithData(Serde.serialize(value))
    }
    
    public func updateValue<T:RawArrayPairDeserializable>(characteristic:Wrapper, value:T) {
        return characteristic.updateValueWithData(Serde.serialize(value))
    }
    
    public func didRespondToWriteRequest(request:Wrapper.RequestWrapper) -> Bool {
        if let processWriteRequestPromise = self.processWriteRequestPromise {
            processWriteRequestPromise.success(request)
            return true
        } else {
            return false
        }
    }

}
// MutableCharacteristicImpl
///////////////////////////////////////////
extension CBATTRequest : CBATTRequestWrappable {
}

extension CBATTError : CBATTErrorWrappable {
}

public class MutableCharacteristic : MutableCharacteristicWrappable {

    var impl = MutableCharacteristicImpl<MutableCharacteristic>()
    
    // MutableCharacteristicImpl
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

    public var stringValues : [String] {
        return self.profile.stringValues
    }
    
    public func propertyEnabled(property:CBCharacteristicProperties) -> Bool {
        return (self.properties.rawValue & property.rawValue) > 0
    }
    
    public func permissionEnabled(permission:CBAttributePermissions) -> Bool {
        return (self.permissions.rawValue & permission.rawValue) > 0
    }

    public var stringValue : [String:String]? {
        if self.value != nil {
            return self.profile.stringValue(self.value)
        } else {
            return nil
        }
    }
    
    public func dataFromStringValue(stringValue:[String:String]) -> NSData? {
        return self.profile.dataFromStringValue(stringValue)
    }
    
    public func updateValueWithData(value:NSData) {
        self._value = value
        PeripheralManager.sharedInstance.cbPeripheralManager.updateValue(value, forCharacteristic:self.cbMutableChracteristic, onSubscribedCentrals:nil)
    }
    
    public func respondToWrappedRequest(request:CBATTRequest, withResult result:CBATTError) {
        PeripheralManager.sharedInstance.cbPeripheralManager.respondToRequest(request, withResult:result)
    }
    
    
    // MutableCharacteristicImpl

    private let profile                         : CharacteristicProfile!
    private var _value                          : NSData?
    
    internal let cbMutableChracteristic         : CBMutableCharacteristic!
    
    public var permissions : CBAttributePermissions {
        return self.cbMutableChracteristic.permissions
    }
    
    public var properties : CBCharacteristicProperties {
        return self.cbMutableChracteristic.properties
    }
    
    public class func withProfiles(profiles:[CharacteristicProfile]) -> [MutableCharacteristic] {
        return profiles.map{MutableCharacteristic(profile:$0)}
    }
    
    public init(profile:CharacteristicProfile) {
        self.profile = profile
        self._value = profile.initialValue
        self.cbMutableChracteristic = CBMutableCharacteristic(type:profile.uuid, properties:profile.properties, value:nil, permissions:profile.permissions)
    }

    public convenience init(uuid:String) {
        self.init(profile:CharacteristicProfile(uuid:uuid))
    }
    
    public func startRespondingToWriteRequests(capacity:Int? = nil) -> FutureStream<CBATTRequest> {
        return self.impl.startRespondingToWriteRequests(capacity:capacity)
    }
    
    public func stopProcessingWriteRequests() {
        self.impl.stopProcessingWriteRequests()
    }
    
    public func didRespondToWriteRequest(request:CBATTRequest) -> Bool  {
        return self.impl.didRespondToWriteRequest(request)
    }
    
    public func updateValueWithString(value:Dictionary<String, String>) {
        if let data = self.profile.dataFromStringValue(value) {
            self.updateValueWithData(data)
        } else {
            NSException(name:"Characteristic update error", reason: "invalid value '\(value)' for \(self.uuid.UUIDString)", userInfo: nil).raise()
        }
    }
    
    public func respondToRequest(request:CBATTRequest, withResult result:CBATTError) {
        self.impl.respondToRequest(self, request:request, withResult:result)
    }
    
    public func updateValue<T:Deserializable>(value:T) {
        return self.impl.updateValue(self, value:value)
    }

    public func updateValue<T:RawDeserializable>(value:T) {
        return self.impl.updateValue(self, value:value)
    }

    public func updateValue<T:RawArrayDeserializable>(value:T) {
        return self.impl.updateValue(self, value:value)
    }

    public func updateValue<T:RawPairDeserializable>(value:T) {
        return self.impl.updateValue(self, value:value)
    }

    public func updateValue<T:RawArrayPairDeserializable>(value:T) {
        return self.impl.updateValue(self, value:value)
    }

}