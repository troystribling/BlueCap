//
//  Service.swift
//  BlueCap
//
//  Created by Troy Stribling on 6/11/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import Foundation
import CoreBluetooth

// MARK: - Service -
public class Service {

    // MARK: Serialize Property IO
    static let ioQueue = Queue("us.gnos.blueCap.service.io")
    static let timeoutQueue = Queue("us.gnos.blueCap.service.timeout")

    fileprivate var _characteristicDiscoverySequence = 0
    fileprivate var _characteristicDiscoveryInProgress = false
    fileprivate var _characteristicsDiscoveredPromise: Promise<Service>?

    fileprivate var characteristicDiscoverySequence: Int {
        get {
            return Service.ioQueue.sync { return self._characteristicDiscoverySequence }
        }
        set {
            Service.ioQueue.sync { self._characteristicDiscoverySequence = newValue }
        }
    }

    fileprivate var characteristicDiscoveryInProgress: Bool {
        get {
            return Service.ioQueue.sync { return self._characteristicDiscoveryInProgress }
        }
        set {
            Service.ioQueue.sync { self._characteristicDiscoveryInProgress = newValue }
        }
    }

     internal var characteristicsDiscoveredPromise: Promise<Service>? {
        get {
            return Service.ioQueue.sync { return self._characteristicsDiscoveredPromise }
        }
        set {
            Service.ioQueue.sync { self._characteristicsDiscoveredPromise = newValue }
        }
    }

    // MARK: Properties
    internal let profile: ServiceProfile?

    internal var discoveredCharacteristics = [CBUUID : Characteristic]()

    internal let cbService: CBServiceInjectable

    public var name: String {
        if let profile = self.profile {
            return profile.name
        } else {
            return "Unknown"
        }
    }
    
    public var UUID: CBUUID {
        return self.cbService.UUID
    }
    
    public var characteristics: [Characteristic] {
        return Array(self.discoveredCharacteristics.values)
    }
    
    public fileprivate(set) weak var peripheral: Peripheral?

    // MARK: Initializer
    internal init(cbService: CBServiceInjectable, peripheral: Peripheral, profile: ServiceProfile? = nil) {
        self.cbService = cbService
        self.peripheral = peripheral
        self.profile = profile
    }

    // MARK: Discover Characteristics
    public func discoverAllCharacteristics(_ timeout: Double? = nil) -> Future<Service> {
        Logger.debug("uuid=\(self.UUID.uuidString), name=\(self.name)")
        return self.discoverIfConnected(nil, timeout: timeout)
    }
    
    public func discoverCharacteristics(_ characteristics: [CBUUID], timeout: Double? = nil) -> Future<Service> {
        Logger.debug("uuid=\(self.UUID.uuidString), name=\(self.name)")
        return self.discoverIfConnected(characteristics, timeout: timeout)
    }
    
    public func characteristic(_ uuid: CBUUID) -> Characteristic? {
        return self.discoveredCharacteristics[uuid]
    }

    // MARK: CBPeripheralDelegate Shim
    internal func didDiscoverCharacteristics(_ discoveredCharacteristics: [CBCharacteristicInjectable], error: Swift.Error?) {
        self.characteristicDiscoveryInProgress = false
        self.discoveredCharacteristics.removeAll()
        if let error = error {
            Logger.debug("discover failed")
            self.characteristicsDiscoveredPromise?.failure(error)
            for cbCharacteristic in discoveredCharacteristics {
                let bcCharacteristic = Characteristic(cbCharacteristic: cbCharacteristic, service: self)
                bcCharacteristic.afterDiscoveredPromise.failure(error)
                Logger.debug("Error discovering uuid=\(bcCharacteristic.UUID.uuidString), name=\(bcCharacteristic.name)")
            }
        } else {
            for cbCharacteristic in discoveredCharacteristics {
                let bcCharacteristic = Characteristic(cbCharacteristic: cbCharacteristic, service: self)
                self.discoveredCharacteristics[bcCharacteristic.UUID] = bcCharacteristic
                bcCharacteristic.afterDiscoveredPromise.success(bcCharacteristic)
                Logger.debug("uuid=\(bcCharacteristic.UUID.uuidString), name=\(bcCharacteristic.name)")
            }
            Logger.debug("discover success")
            self.characteristicsDiscoveredPromise?.success(self)
        }
    }

    internal func didDisconnectPeripheral(_ error: Swift.Error?) {
        self.characteristicDiscoveryInProgress = false
    }

    // MARK: Utils
    fileprivate func discoverIfConnected(_ characteristics: [CBUUID]?, timeout: Double?) -> Future<Service> {
        if !self.characteristicDiscoveryInProgress {
            self.characteristicsDiscoveredPromise = Promise<Service>()
            if self.peripheral?.state == .connected {
                self.characteristicDiscoveryInProgress = true
                self.characteristicDiscoverySequence += 1
                self.timeoutCharacteristicDiscovery(self.characteristicDiscoverySequence, timeout: timeout)
                self.peripheral?.discoverCharacteristics(characteristics, forService:self)
            } else {
                self.characteristicsDiscoveredPromise?.failure(PeripheralError.disconnected)
            }
            return self.characteristicsDiscoveredPromise!.future
        } else {
            let promise = Promise<Service>()
            promise.failure(ServiceError.characteristicDiscoveryInProgress)
            return promise.future
        }
    }

    fileprivate func timeoutCharacteristicDiscovery(_ sequence: Int, timeout: Double?) {
        guard let peripheral = peripheral, let centralManager = peripheral.centralManager, let timeout = timeout else {
            return
        }
        Logger.debug("name = \(self.name), uuid = \(peripheral.identifier.uuidString), sequence = \(sequence), timeout = \(timeout)")
        Peripheral.pollQueue.delay(timeout) {
            if sequence == self.characteristicDiscoverySequence && self.characteristicDiscoveryInProgress {
                Logger.debug("characteristic scan timing out name = \(self.name), UUID = \(self.UUID.uuidString), peripheral UUID = \(peripheral.identifier.uuidString), sequence=\(sequence), current sequence = \(self.characteristicDiscoverySequence)")
                centralManager.cancelPeripheralConnection(peripheral)
                self.characteristicDiscoveryInProgress = false
                self.characteristicsDiscoveredPromise?.failure(ServiceError.characteristicDiscoveryTimeout)
            } else {
                Logger.debug("characteristic scan timeout expired name = \(self.name), UUID = \(self.UUID.uuidString), peripheral UUID = \(peripheral.identifier.uuidString), sequence = \(sequence), current connectionSequence=\(self.characteristicDiscoverySequence)")
            }
        }
    }

}
