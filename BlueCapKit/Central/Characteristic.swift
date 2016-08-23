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
    let value: Data
    let timeout: Double
    let type: CBCharacteristicWriteType
}

struct ReadParameters {
    let timeout: Double
}

// MARK: - Characteristic -
public class Characteristic : NSObject {

    // MARK: Properties
    static let ioQueue      = Queue("us.gnos.blueCap.characteristic.io")
    static let timeoutQueue = Queue("us.gnos.blueCap.characteristic.timeout")

    fileprivate var _notificationStateChangedPromise: Promise<Characteristic>?
    fileprivate var _notificationUpdatePromise: StreamPromise<(characteristic: Characteristic, data: Data?)>?

    internal var readPromises    = SerialIOArray<Promise<Characteristic>>(Characteristic.ioQueue)
    internal var writePromises   = SerialIOArray<Promise<Characteristic>>(Characteristic.ioQueue)
    fileprivate var readParameters  = SerialIOArray<ReadParameters>(Characteristic.ioQueue)
    fileprivate var writeParameters = SerialIOArray<WriteParameters>(Characteristic.ioQueue)
    
    fileprivate weak var _service: Service?
    
    fileprivate let profile: CharacteristicProfile

    fileprivate var _reading = false
    fileprivate var _writing = false
    fileprivate var _readSequence = 0
    fileprivate var _writeSequence = 0
    fileprivate var _isNotifying = false
    fileprivate let defaultTimeout  = 10.0

    internal let cbCharacteristic: CBCharacteristicInjectable

    fileprivate var notificationStateChangedPromise: Promise<Characteristic>? {
        get {
            return Characteristic.ioQueue.sync { return self._notificationStateChangedPromise }
        }
        set {
            Characteristic.ioQueue.sync { self._notificationStateChangedPromise = newValue }
        }
    }

    fileprivate var notificationUpdatePromise: StreamPromise<(characteristic: Characteristic, data: Data?)>? {
        get {
            return Characteristic.ioQueue.sync { return self._notificationUpdatePromise }
        }
        set {
            Characteristic.ioQueue.sync { self._notificationUpdatePromise = newValue }
        }
    }

    fileprivate var reading: Bool {
        get {
            return Characteristic.ioQueue.sync { return self._reading }
        }
        set {
            Characteristic.ioQueue.sync{self._reading = newValue}
        }
    }

    fileprivate var writing: Bool {
        get {
            return Characteristic.ioQueue.sync { return self._writing }
        }
        set {
            Characteristic.ioQueue.sync{ self._writing = newValue }
        }
    }

    fileprivate var readSequence: Int {
        get {
            return Characteristic.ioQueue.sync { return self._readSequence }
        }
        set {
            Characteristic.ioQueue.sync{ self._readSequence = newValue }
        }
    }

    fileprivate var writeSequence: Int {
        get {
            return Characteristic.ioQueue.sync { return self._writeSequence }
        }
        set {
            Characteristic.ioQueue.sync{ self._writeSequence = newValue }
        }
    }
    
    public var UUID: CBUUID {
        return cbCharacteristic.UUID
    }
    
    public var name: String {
        return profile.name
    }
    
    public var isNotifying: Bool {
        get {
            return cbCharacteristic.isNotifying
        }
    }
    
    public var afterDiscoveredPromise: StreamPromise<Characteristic>? {
        return profile.afterDiscoveredPromise
    }
    
    public var canNotify: Bool {
        return propertyEnabled(.notify) || propertyEnabled(.indicate) || propertyEnabled(.notifyEncryptionRequired) || propertyEnabled(.indicateEncryptionRequired)
    }
    
    public var canRead: Bool {
        return propertyEnabled(.read)
    }
    
    public var canWrite: Bool {
        return propertyEnabled(.write) || self.propertyEnabled(.writeWithoutResponse)
    }
    
    public var service: Service? {
        return self._service
    }
    
    public var dataValue: Data? {
        return cbCharacteristic.value
    }
    
    public var stringValues: [String] {
        return profile.stringValues
    }

    public var stringValue: [String:String]? {
        return stringValue(self.dataValue)
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
                Logger.debug("charcteristic profile found creating characteristic: \(characteristicProfile.name):\(characteristicProfile.UUID.uuidString)")
                self.profile = characteristicProfile
            } else {
                Logger.debug("no characteristic profile found. Creating characteristic with UUID: \(service.UUID.uuidString)")
                self.profile = CharacteristicProfile(UUID: service.UUID.uuidString)
            }
        } else {
            Logger.debug("no service profile found. Creating characteristic with UUID: \(service.UUID.uuidString)")
            self.profile = CharacteristicProfile(UUID: service.UUID.uuidString)
        }
        super.init()
    }

    // MARK: Data Access
    public func stringValue(_ data: Data?) -> [String : String]? {
        if let data = data {
            return profile.stringValue(data)
        } else {
            return nil
        }
    }
    
    public func data(fromString stringValue: [String : String]) -> Data? {
        return profile.data(fromString: stringValue)
    }
    
    public func propertyEnabled(_ property: CBCharacteristicProperties) -> Bool {
        return (self.properties.rawValue & property.rawValue) > 0
    }

    public func value<T: Deserializable>() -> T? {
        if let data = self.dataValue {
            return T.deserialize(data)
        } else {
            return nil
        }
    }

    public func value<T: RawDeserializable>() -> T?  where T.RawType: Deserializable {
        if let data = self.dataValue {
            return SerDe.deserialize(data)
        } else {
            return nil
        }
    }

    public func value<T: RawArrayDeserializable>() -> T? where T.RawType: Deserializable {
        if let data = self.dataValue {
            return SerDe.deserialize(data)
        } else {
            return nil
        }
    }

    public func value<T: RawPairDeserializable>() -> T? where T.RawType1: Deserializable, T.RawType2: Deserializable {
        if let data = self.dataValue {
            return SerDe.deserialize(data)
        } else {
            return nil
        }
    }

    public func value<T: RawArrayPairDeserializable>() -> T? where T.RawType1: Deserializable, T.RawType2: Deserializable {
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
            promise.failure(CharacteristicError.notifyNotSupported)
        }
        return promise.future
    }

    public func stopNotifying() -> Future<Characteristic> {
        let promise = Promise<Characteristic>()
        if self.canNotify {
            self.notificationStateChangedPromise = promise
            self.setNotifyValue(false)
        } else {
            promise.failure(CharacteristicError.notifyNotSupported)
        }
        return promise.future
    }

    public func receiveNotificationUpdates(capacity: Int = Int.max) -> FutureStream<(characteristic: Characteristic, data: Data?)> {
        let promise = StreamPromise<(characteristic: Characteristic, data: Data?)>(capacity: capacity)
        if self.canNotify {
            self.notificationUpdatePromise = promise
        } else {
            promise.failure(CharacteristicError.notifyNotSupported)
        }
        return promise.stream
    }
    
    public func stopNotificationUpdates() {
        self.notificationUpdatePromise = nil
    }

    // MARK: Read Data
    public func read(timeout: Double = Double.infinity) -> Future<Characteristic> {
        let promise = Promise<Characteristic>()
        if self.canRead {
            self.readPromises.append(promise)
            self.readParameters.append(ReadParameters(timeout:timeout))
            self.readNext()
        } else {
            promise.failure(CharacteristicError.readNotSupported)
        }
        return promise.future
    }

    // MARK: Write Data
    public func write(data value: Data, timeout: Double = Double.infinity, type: CBCharacteristicWriteType = .withResponse) -> Future<Characteristic> {
        let promise = Promise<Characteristic>()
        if self.canWrite {
            if type == .withResponse {
                self.writePromises.append(promise)
                self.writeParameters.append(WriteParameters(value: value, timeout: timeout, type: type))
                self.writeNext()
            } else {
                self.writeValue(value, type: type)
                promise.success(self)
            }
        } else {
            promise.failure(CharacteristicError.writeNotSupported)
        }
        return promise.future
    }

    public func write(string stringValue: [String: String], timeout: Double = Double.infinity, type: CBCharacteristicWriteType = .withResponse) -> Future<Characteristic> {
        if let value = self.data(fromString: stringValue) {
            return self.write(data: value, timeout: timeout, type: type)
        } else {
            return Future(error: CharacteristicError.notSerializable)
        }
    }

    public func write<T: Deserializable>(_ value: T, timeout: Double = Double.infinity, type: CBCharacteristicWriteType = .withResponse) -> Future<Characteristic> {
        return self.write(data: SerDe.serialize(value), timeout: timeout, type: type)
    }
    
    public func write<T: RawDeserializable>(_ value: T, timeout: Double = Double.infinity, type: CBCharacteristicWriteType = .withResponse) -> Future<Characteristic> {
        return self.write(data: SerDe.serialize(value), timeout: timeout, type: type)
    }

    public func write<T: RawArrayDeserializable>(_ value: T, timeout: Double = Double.infinity, type: CBCharacteristicWriteType = .withResponse) -> Future<Characteristic> {
        return self.write(data: SerDe.serialize(value), timeout: timeout, type: type)
    }

    public func write<T: RawPairDeserializable>(_ value: T, timeout: Double = Double.infinity, type: CBCharacteristicWriteType = .withResponse) -> Future<Characteristic> {
        return self.write(data: SerDe.serialize(value), timeout: timeout, type: type)
    }
    
    public func write<T: RawArrayPairDeserializable>(_ value: T, timeout: Double = Double.infinity, type: CBCharacteristicWriteType = .withResponse) -> Future<Characteristic> {
        return self.write(data: SerDe.serialize(value), timeout: timeout, type: type)
    }

    // MARK: CBPeripheralDelegate Shim
    internal func didUpdateNotificationState(_ error: Swift.Error?) {
        if let error = error {
            Logger.debug("failed uuid=\(self.UUID.uuidString), name=\(self.name)")
            self.notificationStateChangedPromise?.failure(error)
        } else {
            Logger.debug("success:  uuid=\(self.UUID.uuidString), name=\(self.name)")
            self.notificationStateChangedPromise?.success(self)
        }
    }
    
    internal func didUpdate(_ error: Swift.Error?) {
        if self.isNotifying {
            self.didNotify(error)
        } else {
            self.didRead(error)
        }
    }
    
    internal func didWrite(_ error: Swift.Error?) {
        guard let promise = self.shiftPromise(&self.writePromises) , !promise.completed else {
            return
        }
        if let error = error {
            Logger.debug("failed:  uuid=\(self.UUID.uuidString), name=\(self.name)")
            promise.failure(error)
        } else {
            Logger.debug("success:  uuid=\(self.UUID.uuidString), name=\(self.name)")
            promise.success(self)
        }
        self.writing = false
        self.writeNext()
    }

    fileprivate func didRead(_ error: Swift.Error?) {
        guard let promise = self.shiftPromise(&self.readPromises) , !promise.completed else {
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


    fileprivate func didNotify(_ error: Swift.Error?) {
        if let error = error {
            self.notificationUpdatePromise?.failure(error)
        } else {
            self.notificationUpdatePromise?.success((self, self.dataValue))
        }
    }

    // MARK: IO Timeout
    fileprivate func timeoutRead(_ sequence: Int, timeout: Double) {
        guard timeout < Double.infinity else {
            return
        }
        Logger.debug("sequence \(sequence), timeout:\(timeout))")
        Characteristic.timeoutQueue.delay(timeout) {
            if sequence == self.readSequence && self.reading {
                Logger.debug("timing out sequence=\(sequence), current readSequence=\(self.readSequence)")
                self.didUpdate(CharacteristicError.readTimeout)
            } else {
                Logger.debug("timeout expired")
            }
        }
    }
    
    fileprivate func timeoutWrite(_ sequence: Int, timeout: Double) {
        guard timeout < Double.infinity else {
            return
        }
        Logger.debug("sequence \(sequence), timeout:\(timeout)")
        Characteristic.timeoutQueue.delay(timeout) {
            if sequence == self.writeSequence && self.writing {
                Logger.debug("timing out sequence=\(sequence), current writeSequence=\(self.writeSequence)")
                self.didWrite(CharacteristicError.writeTimeout)
            } else {
                Logger.debug("timeout expired")
            }
        }
    }

    // MARK: Peripheral Delegation
    fileprivate func setNotifyValue(_ state: Bool) {
        self.service?.peripheral?.setNotifyValue(state, forCharacteristic: self)
    }
    
    fileprivate func readValueForCharacteristic() {
        self.service?.peripheral?.readValueForCharacteristic(self)
    }
    
    fileprivate func writeValue(_ value: Data, type: CBCharacteristicWriteType = .withResponse) {
        self.service?.peripheral?.writeValue(value, forCharacteristic: self, type: type)
    }

    // MARK: Utilities
    fileprivate func writeNext() {
        guard let parameters = self.writeParameters.first , !self.writing else {
            return
        }
        Logger.debug("write characteristic value=\(parameters.value.hexStringValue()), uuid=\(self.UUID.uuidString)")
        self.writeParameters.removeAtIndex(0)
        self.writing = true
        self.writeValue(parameters.value, type: parameters.type)
        self.writeSequence += 1
        self.timeoutWrite(self.writeSequence, timeout: parameters.timeout)
    }
    
    fileprivate func readNext() {
        guard let parameters = self.readParameters.first , !self.reading else {
            return
        }
        Logger.debug("read characteristic \(self.UUID.uuidString)")
        self.readParameters.removeAtIndex(0)
        self.readValueForCharacteristic()
        self.reading = true
        self.readSequence += 1
        self.timeoutRead(self.readSequence, timeout: parameters.timeout)
    }
    
    fileprivate func shiftPromise(_ promises: inout SerialIOArray<Promise<Characteristic>>) -> Promise<Characteristic>? {
        if let item = promises.first {
            promises.removeAtIndex(0)
            return item
        } else {
            return nil
        }
    }
}
