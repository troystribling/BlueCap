//
//  Characteristic.swift
//  BlueCap
//
//  Created by Troy Stribling on 6/8/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import Foundation
import CoreBluetooth

// MARK: - IO Parameters -
struct WriteParameters {
    let value: NSData
    let timeout: Double
    let type: CBCharacteristicWriteType
}

struct ReadParameters {
    let timeout: Double
}

// MARK: - Characteristic -
public class Characteristic : NSObject {

    private static var CBCharacteristicIsNotifyingKVOContext = UInt8()

    // MARK: Properties
    static let ioQueue      = Queue("us.gnos.blueCap.characteristic.io")
    static let timeoutQueue = Queue("us.gnos.blueCap.characteristic.timeout")

    private var _notificationStateChangedPromise: Promise<Characteristic>?
    private var _notificationUpdatePromise: StreamPromise<(characteristic: Characteristic, data: NSData?)>?

    internal var readPromises    = SerialIOArray<Promise<Characteristic>>(Characteristic.ioQueue)
    internal var writePromises   = SerialIOArray<Promise<Characteristic>>(Characteristic.ioQueue)
    private var readParameters  = SerialIOArray<ReadParameters>(Characteristic.ioQueue)
    private var writeParameters = SerialIOArray<WriteParameters>(Characteristic.ioQueue)
    
    private weak var _service: Service?
    
    private let profile: CharacteristicProfile

    private var _reading = false
    private var _writing = false
    private var _readSequence = 0
    private var _writeSequence = 0
    private var _isNotifying = false
    private let defaultTimeout  = 10.0

    internal let cbCharacteristic: CBCharacteristicInjectable

    private var notificationStateChangedPromise: Promise<Characteristic>? {
        get {
            return Characteristic.ioQueue.sync { return self._notificationStateChangedPromise }
        }
        set {
            Characteristic.ioQueue.sync { self._notificationStateChangedPromise = newValue }
        }
    }

    private var notificationUpdatePromise: StreamPromise<(characteristic: Characteristic, data: NSData?)>? {
        get {
            return Characteristic.ioQueue.sync { return self._notificationUpdatePromise }
        }
        set {
            Characteristic.ioQueue.sync { self._notificationUpdatePromise = newValue }
        }
    }

    private var reading: Bool {
        get {
            return Characteristic.ioQueue.sync { return self._reading }
        }
        set {
            Characteristic.ioQueue.sync{self._reading = newValue}
        }
    }

    private var writing: Bool {
        get {
            return Characteristic.ioQueue.sync { return self._writing }
        }
        set {
            Characteristic.ioQueue.sync{ self._writing = newValue }
        }
    }

    private var readSequence: Int {
        get {
            return Characteristic.ioQueue.sync { return self._readSequence }
        }
        set {
            Characteristic.ioQueue.sync{ self._readSequence = newValue }
        }
    }

    private var writeSequence: Int {
        get {
            return Characteristic.ioQueue.sync { return self._writeSequence }
        }
        set {
            Characteristic.ioQueue.sync{ self._writeSequence = newValue }
        }
    }
    
    public var UUID: CBUUID {
        return self.cbCharacteristic.UUID
    }
    
    public var name: String {
        return self.profile.name
    }
    
    public private(set) var isNotifying: Bool {
        get {
            return Characteristic.ioQueue.sync { return self._isNotifying }
        }
        set {
            Characteristic.ioQueue.sync{ self._isNotifying = newValue }
        }
    }
    
    public var afterDiscoveredPromise: StreamPromise<Characteristic>? {
        return self.profile.afterDiscoveredPromise
    }
    
    public var canNotify: Bool {
        return self.propertyEnabled(.Notify) ||
               self.propertyEnabled(.Indicate) ||
               self.propertyEnabled(.NotifyEncryptionRequired) ||
               self.propertyEnabled(.IndicateEncryptionRequired)
    }
    
    public var canRead: Bool {
        return self.propertyEnabled(.Read)
    }
    
    public var canWrite: Bool {
        return self.propertyEnabled(.Write) || self.propertyEnabled(.WriteWithoutResponse)
    }
    
    public var service: Service? {
        return self._service
    }
    
    public var dataValue: NSData? {
        return self.cbCharacteristic.value
    }
    
    public var stringValues: [String] {
        return self.profile.stringValues
    }

    public var stringValue: [String:String]? {
        return self.stringValue(self.dataValue)
    }
    
    public var properties: CBCharacteristicProperties {
        return self.cbCharacteristic.properties
    }

    // MARK: Initializers
    internal init(cbCharacteristic: CBCharacteristicInjectable, service: Service) {
        self.cbCharacteristic = cbCharacteristic
        self._service = service
        if let serviceProfile = ProfileManager.sharedInstance.services[service.UUID] {
            Logger.debug("creating characteristic for service profile: \(service.name):\(service.UUID)")
            if let characteristicProfile = serviceProfile.characteristicProfiles[cbCharacteristic.UUID] {
                Logger.debug("charcteristic profile found creating characteristic: \(characteristicProfile.name):\(characteristicProfile.UUID.UUIDString)")
                self.profile = characteristicProfile
            } else {
                Logger.debug("no characteristic profile found. Creating characteristic with UUID: \(service.UUID.UUIDString)")
                self.profile = CharacteristicProfile(UUID: service.UUID.UUIDString)
            }
        } else {
            Logger.debug("no service profile found. Creating characteristic with UUID: \(service.UUID.UUIDString)")
            self.profile = CharacteristicProfile(UUID: service.UUID.UUIDString)
        }
        super.init()
    }

    // MARK: Data Access
    public func stringValue(data: NSData?) -> [String:String]? {
        if let data = data {
            return self.profile.stringValue(data)
        } else {
            return nil
        }
    }
    
    public func dataFromStringValue(stringValue: [String: String]) -> NSData? {
        return self.profile.dataFromStringValue(stringValue)
    }
    
    public func propertyEnabled(property:CBCharacteristicProperties) -> Bool {
        return (self.properties.rawValue & property.rawValue) > 0
    }

    public func value<T: Deserializable>() -> T? {
        if let data = self.dataValue {
            return T.deserialize(data)
        } else {
            return nil
        }
    }

    public func value<T: RawDeserializable where T.RawType: Deserializable>() -> T? {
        if let data = self.dataValue {
            return SerDe.deserialize(data)
        } else {
            return nil
        }
    }

    public func value<T: RawArrayDeserializable where T.RawType: Deserializable>() -> T? {
        if let data = self.dataValue {
            return SerDe.deserialize(data)
        } else {
            return nil
        }
    }

    public func value<T: RawPairDeserializable where T.RawType1: Deserializable, T.RawType2: Deserializable>() -> T? {
        if let data = self.dataValue {
            return SerDe.deserialize(data)
        } else {
            return nil
        }
    }

    public func value<T: RawArrayPairDeserializable where T.RawType1: Deserializable, T.RawType2: Deserializable>() -> T? {
        if let data = self.dataValue {
            return SerDe.deserialize(data)
        } else {
            return nil
        }
    }

    // MARK: Notifications
    public func startNotifying() -> Future<Characteristic> {
        let promise = Promise<Characteristic>()
        if self.canNotify {
            self.notificationStateChangedPromise = promise
            self.setNotifyValue(true)
        } else {
            promise.failure(BCError.characteristicNotifyNotSupported)
        }
        return promise.future
    }

    public func stopNotifying() -> Future<Characteristic> {
        let promise = Promise<Characteristic>()
        if self.canNotify {
            self.notificationStateChangedPromise = promise
            self.setNotifyValue(false)
        } else {
            promise.failure(BCError.characteristicNotifyNotSupported)
        }
        return promise.future
    }

    public func receiveNotificationUpdates(capacity: Int? = nil) -> FutureStream<(characteristic: Characteristic, data: NSData?)> {
        let promise = StreamPromise<(characteristic: Characteristic, data: NSData?)>(capacity:capacity)
        if self.canNotify {
            self.notificationUpdatePromise = promise
        } else {
            promise.failure(BCError.characteristicNotifyNotSupported)
        }
        return promise.future
    }
    
    public func stopNotificationUpdates() {
        self.notificationUpdatePromise = nil
    }

    // MARK: Read Data
    public func read(timeout: NSTimeInterval = 10.0) -> Future<Characteristic> {
        let promise = Promise<Characteristic>()
        if self.canRead {
            self.readPromises.append(promise)
            self.readParameters.append(ReadParameters(timeout:timeout))
            self.readNext()
        } else {
            promise.failure(BCError.characteristicReadNotSupported)
        }
        return promise.future
    }

    // MARK: Write Data
    public func writeData(value: NSData, timeout: NSTimeInterval = 10.0, type: CBCharacteristicWriteType = .WithResponse) -> Future<Characteristic> {
        let promise = Promise<Characteristic>()
        if self.canWrite {
            if type == .WithResponse {
                self.writePromises.append(promise)
                self.writeParameters.append(WriteParameters(value: value, timeout: timeout, type: type))
                self.writeNext()
            } else {
                self.writeValue(value, type: type)
                promise.success(self)
            }
        } else {
            promise.failure(BCError.characteristicWriteNotSupported)
        }
        return promise.future
    }

    public func writeString(stringValue: [String: String], timeout: NSTimeInterval = 10.0, type: CBCharacteristicWriteType = .WithResponse) -> Future<Characteristic> {
        if let value = self.dataFromStringValue(stringValue) {
            return self.writeData(value, timeout: timeout, type: type)
        } else {
            let promise = Promise<Characteristic>()
            promise.failure(BCError.characteristicNotSerilaizable)
            return promise.future
        }
    }

    public func write<T: Deserializable>(value:T, timeout: NSTimeInterval = 10.0, type: CBCharacteristicWriteType = .WithResponse) -> Future<Characteristic> {
        return self.writeData(SerDe.serialize(value), timeout: timeout, type: type)
    }
    
    public func write<T: RawDeserializable>(value:T, timeout: NSTimeInterval = 10.0, type: CBCharacteristicWriteType = .WithResponse) -> Future<Characteristic> {
        return self.writeData(SerDe.serialize(value), timeout: timeout, type: type)
    }

    public func write<T: RawArrayDeserializable>(value: T, timeout: NSTimeInterval = 10.0, type: CBCharacteristicWriteType = .WithResponse) -> Future<Characteristic> {
        return self.writeData(SerDe.serialize(value), timeout: timeout, type: type)
    }

    public func write<T: RawPairDeserializable>(value: T, timeout: NSTimeInterval = 10.0, type: CBCharacteristicWriteType = .WithResponse) -> Future<Characteristic> {
        return self.writeData(SerDe.serialize(value), timeout: timeout, type: type)
    }
    
    public func write<T: RawArrayPairDeserializable>(value: T, timeout: NSTimeInterval = 10.0, type: CBCharacteristicWriteType = .WithResponse) -> Future<Characteristic> {
        return self.writeData(SerDe.serialize(value), timeout: timeout, type: type)
    }

    // MARK: CBPeripheralDelegate Shim
    internal func didUpdateNotificationState(error: NSError?) {
        if let error = error {
            Logger.debug("failed uuid=\(self.UUID.UUIDString), name=\(self.name)")
            self.notificationStateChangedPromise?.failure(error)
        } else {
            Logger.debug("success:  uuid=\(self.UUID.UUIDString), name=\(self.name)")
            self.willChangeValueForKey("isNotifying")
            self.isNotifying = self.cbCharacteristic.isNotifying
            self.didChangeValueForKey("isNotifying")
            self.notificationStateChangedPromise?.success(self)
        }
    }
    
    internal func didUpdate(error: NSError?) {
        if self.isNotifying {
            self.didNotify(error)
        } else {
            self.didRead(error)
        }
    }
    
    internal func didWrite(error: NSError?) {
        guard let promise = self.shiftPromise(&self.writePromises) where !promise.completed else {
            return
        }
        if let error = error {
            Logger.debug("failed:  uuid=\(self.UUID.UUIDString), name=\(self.name)")
            promise.failure(error)
        } else {
            Logger.debug("success:  uuid=\(self.UUID.UUIDString), name=\(self.name)")
            promise.success(self)
        }
        self.writing = false
        self.writeNext()
    }

    private func didRead(error: NSError?) {
        guard let promise = self.shiftPromise(&self.readPromises) where !promise.completed else {
            return
        }
        if let error = error {
            promise.failure(error)
        } else {
            promise.success(self)
        }
        self.reading = false
        self.readNext()
    }


    private func didNotify(error: NSError?) {
        if let error = error {
            self.notificationUpdatePromise?.failure(error)
        } else {
            self.notificationUpdatePromise?.success((self, self.dataValue.flatmap{ $0.copy() as? NSData}))
        }
    }

    // MARK: IO Timeout
    private func timeoutRead(sequence: Int, timeout: NSTimeInterval) {
        Logger.debug("sequence \(sequence), timeout:\(timeout))")
        Characteristic.timeoutQueue.delay(timeout) {
            if sequence == self.readSequence && self.reading {
                Logger.debug("timing out sequence=\(sequence), current readSequence=\(self.readSequence)")
                self.didUpdate(BCError.characteristicReadTimeout)
            } else {
                Logger.debug("timeout expired")
            }
        }
    }
    
    private func timeoutWrite(sequence: Int, timeout: NSTimeInterval) {
        Logger.debug("sequence \(sequence), timeout:\(timeout)")
        Characteristic.timeoutQueue.delay(timeout) {
            if sequence == self.writeSequence && self.writing {
                Logger.debug("timing out sequence=\(sequence), current writeSequence=\(self.writeSequence)")
                self.didWrite(BCError.characteristicWriteTimeout)
            } else {
                Logger.debug("timeout expired")
            }
        }
    }

    // MARK: Peripheral Delegation
    private func setNotifyValue(state: Bool) {
        self.service?.peripheral?.setNotifyValue(state, forCharacteristic: self)
    }
    
    private func readValueForCharacteristic() {
        self.service?.peripheral?.readValueForCharacteristic(self)
    }
    
    private func writeValue(value: NSData, type: CBCharacteristicWriteType = .WithResponse) {
        self.service?.peripheral?.writeValue(value, forCharacteristic: self, type: type)
    }

    // MARK: Utilities
    private func writeNext() {
        guard let parameters = self.writeParameters.first where !self.writing else {
            return
        }
        Logger.debug("write characteristic value=\(parameters.value.hexStringValue()), uuid=\(self.UUID.UUIDString)")
        self.writeParameters.removeAtIndex(0)
        self.writing = true
        self.writeValue(parameters.value, type: parameters.type)
        self.writeSequence += 1
        self.timeoutWrite(self.writeSequence, timeout: parameters.timeout)
    }
    
    private func readNext() {
        guard let parameters = self.readParameters.first where !self.reading else {
            return
        }
        Logger.debug("read characteristic \(self.UUID.UUIDString)")
        self.readParameters.removeAtIndex(0)
        self.readValueForCharacteristic()
        self.reading = true
        self.readSequence += 1
        self.timeoutRead(self.readSequence, timeout: parameters.timeout)
    }
    
    private func shiftPromise(inout promises: SerialIOArray<Promise<Characteristic>>) -> Promise<Characteristic>? {
        if let item = promises.first {
            promises.removeAtIndex(0)
            return item
        } else {
            return nil
        }
    }
}
