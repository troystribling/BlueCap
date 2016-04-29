//
//  BCService.swift
//  BlueCap
//
//  Created by Troy Stribling on 6/11/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import Foundation
import CoreBluetooth

// MARK: - BCService -
public class BCService {

    // MARK: Serialize Property IO
    static let ioQueue = Queue("us.gnos.blueCap.service.io")
    static let timeoutQueue = Queue("us.gnos.blueCap.service.timeout")

    private var _characteristicDiscoverySequence = 0
    private var _characteristicDiscoveryInProgress = false
    private var _characteristicsDiscoveredPromise: Promise<BCService>?

    private var characteristicDiscoverySequence: Int {
        get {
            return BCService.ioQueue.sync { return self._characteristicDiscoverySequence }
        }
        set {
            BCService.ioQueue.sync { self._characteristicDiscoverySequence = newValue }
        }
    }

    private var characteristicDiscoveryInProgress: Bool {
        get {
            return BCService.ioQueue.sync { return self._characteristicDiscoveryInProgress }
        }
        set {
            BCService.ioQueue.sync { self._characteristicDiscoveryInProgress = newValue }
        }
    }

     internal var characteristicsDiscoveredPromise: Promise<BCService>? {
        get {
            return BCService.ioQueue.sync { return self._characteristicsDiscoveredPromise }
        }
        set {
            BCService.ioQueue.sync { self._characteristicsDiscoveredPromise = newValue }
        }
    }

    // MARK: Properties
    private let profile: BCServiceProfile?

    internal var discoveredCharacteristics = [CBUUID : BCCharacteristic]()

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
    
    public var characteristics: [BCCharacteristic] {
        return Array(self.discoveredCharacteristics.values)
    }
    
    public private(set) weak var peripheral: BCPeripheral?

    // MARK: Initializer
    internal init(cbService: CBServiceInjectable, peripheral: BCPeripheral) {
        self.cbService = cbService
        self.peripheral = peripheral
        self.profile = BCProfileManager.sharedInstance.services[cbService.UUID]
    }

    // MARK: Discover Characteristics
    public func discoverAllCharacteristics(timeout: NSTimeInterval? = nil) -> Future<BCService> {
        BCLogger.debug("uuid=\(self.UUID.UUIDString), name=\(self.name)")
        return self.discoverIfConnected(nil, timeout: timeout)
    }
    
    public func discoverCharacteristics(characteristics: [CBUUID], timeout: NSTimeInterval? = nil) -> Future<BCService> {
        BCLogger.debug("uuid=\(self.UUID.UUIDString), name=\(self.name)")
        return self.discoverIfConnected(characteristics, timeout: timeout)
    }
    
    public func characteristic(uuid: CBUUID) -> BCCharacteristic? {
        return self.discoveredCharacteristics[uuid]
    }

    // MARK: CBPeripheralDelegate Shim
    internal func didDiscoverCharacteristics(discoveredCharacteristics: [CBCharacteristicInjectable], error: NSError?) {
        self.characteristicDiscoveryInProgress = false
        self.discoveredCharacteristics.removeAll()
        if let error = error {
            BCLogger.debug("discover failed")
            self.characteristicsDiscoveredPromise?.failure(error)
            for cbCharacteristic in discoveredCharacteristics {
                let bcCharacteristic = BCCharacteristic(cbCharacteristic: cbCharacteristic, service: self)
                bcCharacteristic.afterDiscoveredPromise?.failure(error)
                BCLogger.debug("Error discovering uuid=\(bcCharacteristic.UUID.UUIDString), name=\(bcCharacteristic.name)")
            }
        } else {
            for cbCharacteristic in discoveredCharacteristics {
                let bcCharacteristic = BCCharacteristic(cbCharacteristic: cbCharacteristic, service: self)
                self.discoveredCharacteristics[bcCharacteristic.UUID] = bcCharacteristic
                bcCharacteristic.afterDiscoveredPromise?.success(bcCharacteristic)
                BCLogger.debug("uuid=\(bcCharacteristic.UUID.UUIDString), name=\(bcCharacteristic.name)")
            }
            BCLogger.debug("discover success")
            self.characteristicsDiscoveredPromise?.success(self)
        }
    }

    internal func didDisconnectPeripheral(error: NSError?) {
        self.characteristicDiscoveryInProgress = false
    }

    // MARK: Utils
    private func discoverIfConnected(characteristics: [CBUUID]?, timeout: NSTimeInterval?) -> Future<BCService> {
        if !self.characteristicDiscoveryInProgress {
            self.characteristicsDiscoveredPromise = Promise<BCService>()
            if self.peripheral?.state == .Connected {
                self.characteristicDiscoveryInProgress = true
                self.characteristicDiscoverySequence += 1
                self.timeoutCharacteristicDiscovery(self.characteristicDiscoverySequence, timeout: timeout)
                self.peripheral?.discoverCharacteristics(characteristics, forService:self)
            } else {
                self.characteristicsDiscoveredPromise?.failure(BCError.peripheralDisconnected)
            }
            return self.characteristicsDiscoveredPromise!.future
        } else {
            let promise = Promise<BCService>()
            promise.failure(BCError.serviceCharacteristicDiscoveryInProgress)
            return promise.future
        }
    }

    private func timeoutCharacteristicDiscovery(sequence: Int, timeout: NSTimeInterval?) {
        guard let peripheral = peripheral, centralManager = peripheral.centralManager, timeout = timeout else {
            return
        }
        BCLogger.debug("name = \(self.name), uuid = \(peripheral.identifier.UUIDString), sequence = \(sequence), timeout = \(timeout)")
        BCPeripheral.pollQueue.delay(timeout) {
            if sequence == self.characteristicDiscoverySequence && self.characteristicDiscoveryInProgress {
                BCLogger.debug("characteristic scan timing out name = \(self.name), UUID = \(self.UUID.UUIDString), peripheral UUID = \(peripheral.identifier.UUIDString), sequence=\(sequence), current sequence = \(self.characteristicDiscoverySequence)")
                centralManager.cancelPeripheralConnection(peripheral)
                self.characteristicDiscoveryInProgress = false
                self.characteristicsDiscoveredPromise?.failure(BCError.serviceCharacteristicDiscoveryTimeout)
            } else {
                BCLogger.debug("characteristic scan timeout expired name = \(self.name), UUID = \(self.UUID.UUIDString), peripheral UUID = \(peripheral.identifier.UUIDString), sequence = \(sequence), current connectionSequence=\(self.characteristicDiscoverySequence)")
            }
        }
    }

}