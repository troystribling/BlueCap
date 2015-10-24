//
//  MutableCharacteristic.swift
//  BlueCap
//
//  Created by Troy Stribling on 8/9/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import Foundation
import CoreBluetooth

///////////////////////////////////////////
// MutableCharacteristicImpl
public protocol MutableCharacteristicWrappable : class {
    
    typealias RequestWrapper
    typealias ResultWrapper
  
    var uuid            : CBUUID            {get}
    var name            : String            {get}
    var value           : NSData?           {get set}
    var stringValues    : [String]          {get}
    var stringValue     : [String:String]?  {get}

    func propertyEnabled(property:CBCharacteristicProperties) -> Bool
    func permissionEnabled(permission:CBAttributePermissions) -> Bool
    
    func dataFromStringValue(stringValue:[String:String]) -> NSData?
    
    func updateValueWithData(value:NSData) -> Bool
    func respondToWrappedRequest(request:RequestWrapper, withResult result:ResultWrapper)
}

public protocol CBATTRequestWrappable {
    
}

public protocol CBATTErrorWrappable {
    
}

public class MutableCharacteristicImpl<Wrapper where Wrapper:MutableCharacteristicWrappable,
                                                     Wrapper.RequestWrapper:CBATTRequestWrappable,
                                                     Wrapper.ResultWrapper:CBATTErrorWrappable> {
    
    internal var processWriteRequestPromise : StreamPromise<Wrapper.RequestWrapper>?

    private var _hasSubscriber   = false
    private var _isUpdating      = false

    
    public var hasSubscriber : Bool {
        return self._hasSubscriber
    }

    public var isUpdating : Bool {
        return self._isUpdating
    }

    public init() {
    }
    
    public func startRespondingToWriteRequests(capacity:Int? = nil) -> FutureStream<Wrapper.RequestWrapper> {
        self.processWriteRequestPromise = StreamPromise<Wrapper.RequestWrapper>(capacity:capacity)
        return self.processWriteRequestPromise!.future
    }
    
    public func stopRespondingToWriteRequests() {
        self.processWriteRequestPromise = nil
    }
    
    public func respondToRequest(characteristic:Wrapper, request:Wrapper.RequestWrapper, withResult result:Wrapper.ResultWrapper) {
        characteristic.respondToWrappedRequest(request, withResult:result)
    }
    
    public func updateValueWithData(characteristic:Wrapper, value:NSData) -> Bool  {
        characteristic.value = value
        if self._isUpdating &&
                (characteristic.propertyEnabled(.Notify)                    ||
                 characteristic.propertyEnabled(.Indicate)                  ||
                 characteristic.propertyEnabled(.NotifyEncryptionRequired)  ||
                 characteristic.propertyEnabled(.IndicateEncryptionRequired)) {
            self._isUpdating = characteristic.updateValueWithData(value)
        }
        return self._isUpdating
    }
    
    public func updateValue<T:Deserializable>(characteristic:Wrapper, value:T) -> Bool  {
        return self.updateValueWithData(characteristic, value:Serde.serialize(value))
    }
    
    public func updateValue<T:RawDeserializable>(characteristic:Wrapper, value:T) -> Bool  {
        return self.updateValueWithData(characteristic, value:Serde.serialize(value))
    }
    
    public func updateValue<T:RawArrayDeserializable>(characteristic:Wrapper, value:T) -> Bool  {
        return self.updateValueWithData(characteristic, value:Serde.serialize(value))
    }
    
    public func updateValue<T:RawPairDeserializable>(characteristic:Wrapper, value:T) -> Bool  {
        return self.updateValueWithData(characteristic, value:Serde.serialize(value))
    }
    
    public func updateValue<T:RawArrayPairDeserializable>(characteristic:Wrapper, value:T) -> Bool  {
        return self.updateValueWithData(characteristic, value:Serde.serialize(value))
    }
    
    public func didRespondToWriteRequest(request:Wrapper.RequestWrapper) -> Bool {
        if let processWriteRequestPromise = self.processWriteRequestPromise {
            processWriteRequestPromise.success(request)
            return true
        } else {
            return false
        }
    }

    public func didSubscribeToCharacteristic() {
        self._hasSubscriber = true
        self._isUpdating = true
    }
    
    public func didUnsubscribeFromCharacteristic() {
        self._hasSubscriber = false
        self._isUpdating = false
    }
    
    public func peripheralManagerIsReadyToUpdateSubscribers() {
        if self._hasSubscriber {
            self._isUpdating = true
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

    // MutableCharacteristicWrappable
    public var value : NSData?

    public var uuid : CBUUID {
        return self.profile.uuid
    }
    
    public var name : String {
        return self.profile.name
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
        if let value = self.value {
            return self.profile.stringValue(value)
        } else {
            return nil
        }
    }
    
    public func dataFromStringValue(stringValue:[String:String]) -> NSData? {
        return self.profile.dataFromStringValue(stringValue)
    }
    
    public func updateValueWithData(value:NSData) -> Bool  {
        return PeripheralManager.sharedInstance.cbPeripheralManager.updateValue(value, forCharacteristic:self.cbMutableChracteristic, onSubscribedCentrals:nil)
    }
    
    public func respondToWrappedRequest(request:CBATTRequest, withResult result:CBATTError) {
        PeripheralManager.sharedInstance.cbPeripheralManager.respondToRequest(request, withResult:result)
    }
    // MutableCharacteristicWrappable

    private let profile                         : CharacteristicProfile!
    internal let cbMutableChracteristic         : CBMutableCharacteristic!
    
    public var permissions : CBAttributePermissions {
        return self.cbMutableChracteristic.permissions
    }
    
    public var properties : CBCharacteristicProperties {
        return self.cbMutableChracteristic.properties
    }
    
    public var hasSubscriber : Bool {
        return self.impl.hasSubscriber
    }
    
    public class func withProfiles(profiles:[CharacteristicProfile]) -> [MutableCharacteristic] {
        return profiles.map{MutableCharacteristic(profile:$0)}
    }
    
    public init(profile:CharacteristicProfile) {
        self.profile = profile
        self.value = profile.initialValue
        self.cbMutableChracteristic = CBMutableCharacteristic(type:profile.uuid, properties:profile.properties, value:nil, permissions:profile.permissions)
    }

    public init(uuid:String, properties:CBCharacteristicProperties, permissions:CBAttributePermissions, value:NSData?) {
        self.profile = CharacteristicProfile(uuid:uuid)
        self.value = value
        self.cbMutableChracteristic = CBMutableCharacteristic(type:self.profile.uuid, properties:properties, value:nil, permissions:permissions)
    }

    public convenience init(uuid:String) {
        self.init(profile:CharacteristicProfile(uuid:uuid))
    }
    
    public func startRespondingToWriteRequests(capacity:Int? = nil) -> FutureStream<CBATTRequest> {
        return self.impl.startRespondingToWriteRequests(capacity)
    }
    
    public func stopRespondingToWriteRequests() {
        self.impl.stopRespondingToWriteRequests()
    }
    
    public func didRespondToWriteRequest(request:CBATTRequest) -> Bool  {
        return self.impl.didRespondToWriteRequest(request)
    }
    
    public func didSubscribeToCharacteristic() {
        self.impl.didSubscribeToCharacteristic()
    }
    
    public func didUnsubscribeFromCharacteristic() {
        self.impl.didUnsubscribeFromCharacteristic()
    }

    public func peripheralManagerIsReadyToUpdateSubscribers() {
        self.impl.peripheralManagerIsReadyToUpdateSubscribers()
    }

    public func updateValueWithString(value:Dictionary<String, String>) -> Bool {
        if let data = self.profile.dataFromStringValue(value) {
            return self.updateValueWithData(data)
        } else {
            NSException(name:"Characteristic update error", reason: "invalid value '\(value)' for \(self.uuid.UUIDString)", userInfo: nil).raise()
            return false
        }
    }
    
    public func respondToRequest(request:CBATTRequest, withResult result:CBATTError) {
        self.impl.respondToRequest(self, request:request, withResult:result)
    }
    
    public func updateValue<T:Deserializable>(value:T) -> Bool {
        return self.impl.updateValue(self, value:value)
    }

    public func updateValue<T:RawDeserializable>(value:T) -> Bool  {
        return self.impl.updateValue(self, value:value)
    }

    public func updateValue<T:RawArrayDeserializable>(value:T) -> Bool  {
        return self.impl.updateValue(self, value:value)
    }

    public func updateValue<T:RawPairDeserializable>(value:T) -> Bool  {
        return self.impl.updateValue(self, value:value)
    }

    public func updateValue<T:RawArrayPairDeserializable>(value:T) -> Bool  {
        return self.impl.updateValue(self, value:value)
    }

}