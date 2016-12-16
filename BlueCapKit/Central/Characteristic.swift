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
    let timeout: TimeInterval
    let type: CBCharacteristicWriteType
}

struct ReadParameters {
    let timeout: TimeInterval
}

// MARK: - Characteristic -
public class Characteristic : NSObject {

    // MARK: Properties
    fileprivate var notificationStateChangedPromise: Promise<Characteristic>?
    fileprivate var notificationUpdatePromise: StreamPromise<(characteristic: Characteristic, data: Data?)>?

    fileprivate var readParameters  = [ReadParameters]()
    fileprivate var writeParameters = [WriteParameters]()

    fileprivate weak var _service: Service?
    
    fileprivate let profile: CharacteristicProfile

    fileprivate var reading = false
    fileprivate var writing = false
    fileprivate var readSequence = 0
    fileprivate var writeSequence = 0

    var readPromises = [Promise<Characteristic>]()
    var writePromises = [Promise<Characteristic>]()

    let cbCharacteristic: CBCharacteristicInjectable
    let centralQueue: Queue

    public var pendingReadCount: Int {
        return centralQueue.sync { self.readPromises.count }
    }

    public var pendingWriteCount: Int {
        return centralQueue.sync { self.writePromises.count }
    }

    public var uuid: CBUUID {
        return cbCharacteristic.uuid
    }
    
    public var name: String {
        return profile.name
    }
    
    public var isNotifying: Bool {
        return cbCharacteristic.isNotifying
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

    public var stringValue: [String : String]? {
        return stringValue(self.dataValue)
    }
    
    public var properties: CBCharacteristicProperties {
        return self.cbCharacteristic.properties
    }

    // MARK: Initializers
    init(cbCharacteristic: CBCharacteristicInjectable, service: Service) {
        self.cbCharacteristic = cbCharacteristic
        self._service = service
        self.centralQueue = service.centralQueue
        self.profile = service.profile?.characteristicProfile(withUUID: cbCharacteristic.uuid) ??  CharacteristicProfile(uuid: cbCharacteristic.uuid.uuidString)
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
        return centralQueue.sync {
            if let notificationStateChangedPromise = self.notificationStateChangedPromise, !notificationStateChangedPromise.completed {
                return notificationStateChangedPromise.future
            }
            if self.canNotify {
                self.notificationStateChangedPromise = Promise<Characteristic>()
                self.setNotifyValue(true)
                return self.notificationStateChangedPromise!.future
            } else {
                return Future(error: CharacteristicError.notifyNotSupported)
            }
        }
    }

    public func stopNotifying() -> Future<Characteristic> {
        return centralQueue.sync {
            if let notificationStateChangedPromise = self.notificationStateChangedPromise, !notificationStateChangedPromise.completed {
                return notificationStateChangedPromise.future
            }
            if self.canNotify {
                self.notificationStateChangedPromise = Promise<Characteristic>()
                self.setNotifyValue(false)
                return self.notificationStateChangedPromise!.future
            } else {
                return Future(error: CharacteristicError.notifyNotSupported)
            }
        }
    }

    public func receiveNotificationUpdates(capacity: Int = Int.max) -> FutureStream<(characteristic: Characteristic, data: Data?)> {
        return centralQueue.sync {
            if let notificationUpdatePromise = self.notificationUpdatePromise {
                return notificationUpdatePromise.stream
            }
            if self.canNotify {
                self.notificationUpdatePromise = StreamPromise<(characteristic: Characteristic, data: Data?)>(capacity: capacity)
                return self.notificationUpdatePromise!.stream
            } else {
                return FutureStream(error: CharacteristicError.notifyNotSupported)
            }
        }
    }
    
    public func stopNotificationUpdates() {
        self.notificationUpdatePromise = nil
    }

    // MARK: Read Data
    public func read(timeout: TimeInterval = TimeInterval.infinity) -> Future<Characteristic> {
        return centralQueue.sync {
            if self.canRead {
                let promise = Promise<Characteristic>()
                self.readPromises.append(promise)
                self.readParameters.append(ReadParameters(timeout:timeout))
                self.readNext()
                return promise.future
            } else {
                return Future(error: CharacteristicError.readNotSupported)
            }
        }
    }

    // MARK: Write Data
    public func write(data value: Data, timeout: TimeInterval = TimeInterval.infinity, type: CBCharacteristicWriteType = .withResponse) -> Future<Characteristic> {
        return centralQueue.sync {
            if self.canWrite {
                if type == .withResponse {
                    let promise = Promise<Characteristic>()
                    self.writePromises.append(promise)
                    self.writeParameters.append(WriteParameters(value: value, timeout: timeout, type: type))
                    self.writeNext()
                    return promise.future
                } else {
                    self.writeValue(value, type: type)
                    return Future(value: self)
                }
            } else {
                return Future(error: CharacteristicError.writeNotSupported)
            }
        }
    }

    public func write(string stringValue: [String: String], timeout: TimeInterval = TimeInterval.infinity, type: CBCharacteristicWriteType = .withResponse) -> Future<Characteristic> {
        if let value = data(fromString: stringValue) {
            return write(data: value, timeout: timeout, type: type)
        } else {
            return Future(error: CharacteristicError.notSerializable)
        }
    }

    public func write<T: Deserializable>(_ value: T, timeout: TimeInterval = TimeInterval.infinity, type: CBCharacteristicWriteType = .withResponse) -> Future<Characteristic> {
        return write(data: SerDe.serialize(value), timeout: timeout, type: type)
    }
    
    public func write<T: RawDeserializable>(_ value: T, timeout: TimeInterval = TimeInterval.infinity, type: CBCharacteristicWriteType = .withResponse) -> Future<Characteristic> {
        return write(data: SerDe.serialize(value), timeout: timeout, type: type)
    }

    public func write<T: RawArrayDeserializable>(_ value: T, timeout: TimeInterval = TimeInterval.infinity, type: CBCharacteristicWriteType = .withResponse) -> Future<Characteristic> {
        return write(data: SerDe.serialize(value), timeout: timeout, type: type)
    }

    public func write<T: RawPairDeserializable>(_ value: T, timeout: TimeInterval = TimeInterval.infinity, type: CBCharacteristicWriteType = .withResponse) -> Future<Characteristic> {
        return write(data: SerDe.serialize(value), timeout: timeout, type: type)
    }
    
    public func write<T: RawArrayPairDeserializable>(_ value: T, timeout: TimeInterval = TimeInterval.infinity, type: CBCharacteristicWriteType = .withResponse) -> Future<Characteristic> {
        return write(data: SerDe.serialize(value), timeout: timeout, type: type)
    }

    // MARK: CBPeripheralDelegate Shim
    internal func didUpdateNotificationState(_ error: Swift.Error?) {
        if let error = error {
            Logger.debug("failed uuid=\(uuid.uuidString), name=\(self.name)")
            notificationStateChangedPromise?.failure(error)
        } else {
            Logger.debug("success:  uuid=\(uuid.uuidString), name=\(self.name)")
            notificationStateChangedPromise?.success(self)
        }
    }
    
    internal func didUpdate(_ error: Swift.Error?) {
        didNotify(error)
        didRead(error)
    }
    
    internal func didWrite(_ error: Swift.Error?) {
        guard let promise = self.shiftPromise(&self.writePromises) , !promise.completed else {
            return
        }
        if let error = error {
            Logger.debug("failed:  uuid=\(uuid.uuidString), name=\(self.name)")
            promise.failure(error)
        } else {
            Logger.debug("success:  uuid=\(uuid.uuidString), name=\(self.name)")
            promise.success(self)
        }
        writing = false
        writeNext()
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
        reading = false
        readNext()
    }

    fileprivate func didNotify(_ error: Swift.Error?) {
        guard isNotifying else {
            return
        }
        if let error = error {
            notificationUpdatePromise?.failure(error)
        } else {
            notificationUpdatePromise?.success((self, self.dataValue))
        }
    }

    // MARK: IO Timeout
    fileprivate func timeoutRead(_ sequence: Int, timeout: TimeInterval) {
        guard timeout < TimeInterval.infinity else {
            return
        }
        Logger.debug("sequence \(sequence), timeout:\(timeout))")
        centralQueue.delay(timeout) { [weak self] in
            self.forEach { strongSelf in
                if sequence == strongSelf.readSequence && strongSelf.reading {
                    Logger.debug("timing out sequence=\(sequence), current readSequence=\(strongSelf.readSequence)")
                    strongSelf.didUpdate(CharacteristicError.readTimeout)
                } else {
                    Logger.debug("timeout expired")
                }
            }
        }
    }
    
    fileprivate func timeoutWrite(_ sequence: Int, timeout: TimeInterval) {
        guard timeout < TimeInterval.infinity else {
            return
        }
        Logger.debug("sequence \(sequence), timeout:\(timeout)")
        centralQueue.delay(timeout) { [weak self] in
            self.forEach { strongSelf in
                if sequence == strongSelf.writeSequence && strongSelf.writing {
                    Logger.debug("timing out sequence=\(sequence), current writeSequence=\(strongSelf.writeSequence)")
                    strongSelf.didWrite(CharacteristicError.writeTimeout)
                } else {
                    Logger.debug("timeout expired")
                }
            }
        }
    }

    // MARK: Peripheral Delegation
    fileprivate func setNotifyValue(_ state: Bool) {
        service?.peripheral?.setNotifyValue(state, forCharacteristic: self)
    }
    
    fileprivate func readValueForCharacteristic() {
        service?.peripheral?.readValueForCharacteristic(self)
    }
    
    fileprivate func writeValue(_ value: Data, type: CBCharacteristicWriteType = .withResponse) {
        service?.peripheral?.writeValue(value, forCharacteristic: self, type: type)
    }

    // MARK: Utilities
    fileprivate func writeNext() {
        guard let parameters = writeParameters.first , !writing else {
            return
        }
        Logger.debug("write characteristic value=\(parameters.value.hexStringValue()), uuid=\(uuid.uuidString)")
        writeParameters.remove(at :0)
        writing = true
        writeValue(parameters.value, type: parameters.type)
        writeSequence += 1
        timeoutWrite(self.writeSequence, timeout: parameters.timeout)
    }
    
    fileprivate func readNext() {
        guard let parameters = readParameters.first , !reading else {
            return
        }
        Logger.debug("read characteristic \(uuid.uuidString)")
        readParameters.remove(at :0)
        readValueForCharacteristic()
        reading = true
        readSequence += 1
        timeoutRead(self.readSequence, timeout: parameters.timeout)
    }
    
    fileprivate func shiftPromise(_ promises: inout [Promise<Characteristic>]) -> Promise<Characteristic>? {
        if let _ = promises.first {
            return promises.remove(at :0)
        } else {
            return nil
        }
    }

}
