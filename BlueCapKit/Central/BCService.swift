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
    private var _characteristicDiscoveryComplete = true
    private var _characteristicsDiscoveredPromise: Promise<BCService>?

    private var characteristicDiscoverySequence: Int {
        get {
            return BCService.ioQueue.sync { return self._characteristicDiscoverySequence }
        }
        set {
            BCService.ioQueue.sync { self._characteristicDiscoverySequence = newValue }
        }
    }

    private var characteristicDiscoveryComplete: Bool {
        get {
            return BCService.ioQueue.sync { return self._characteristicDiscoveryComplete }
        }
        set {
            BCService.ioQueue.sync { self._characteristicDiscoveryComplete = newValue }
        }
    }

     private var characteristicsDiscoveredPromise: Promise<BCService>? {
        get {
            return BCService.ioQueue.sync { return self._characteristicsDiscoveredPromise }
        }
        set {
            BCService.ioQueue.sync { self._characteristicsDiscoveredPromise = newValue }
        }
    }


    // MARK: Properties
    private let profile: BCServiceProfile?

    internal var discoveredCharacteristics = [CBUUID:BCCharacteristic]()

    public let cbService: CBService

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
    internal init(cbService: CBService, peripheral: BCPeripheral) {
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
        if self.characteristicDiscoveryComplete {
            return self.discoverIfConnected(characteristics, timeout: timeout)
        } else {
            let promise = Promise<BCService>()
            promise.failure(BCError.serviceCharacteristicDiscoveryInProgress)
            return promise.future
        }
    }
    
    public func characteristic(uuid: CBUUID) -> BCCharacteristic? {
        return self.discoveredCharacteristics[uuid]
    }

    // MARK: CBPeripheralDelegate Shim
    internal func didDiscoverCharacteristics(discoveredCharacteristics: [CBCharacteristic], error: NSError?) {
        self.characteristicDiscoveryComplete = true
        if let error = error {
            BCLogger.debug("discover failed")
            self.characteristicsDiscoveredPromise?.failure(error)
        } else {
            self.discoveredCharacteristics.removeAll()
            for cbCharacteristic in discoveredCharacteristics {
                let bcCharacteristic = BCCharacteristic(cbCharacteristic: cbCharacteristic, service: self)
                self.discoveredCharacteristics[bcCharacteristic.UUID] = bcCharacteristic
                BCLogger.debug("uuid=\(self.UUID.UUIDString), name=\(self.name)")
                bcCharacteristic.afterDiscoveredPromise?.success(bcCharacteristic)
                BCLogger.debug("uuid=\(bcCharacteristic.UUID.UUIDString), name=\(bcCharacteristic.name)")
            }
            BCLogger.debug("discover success")
            self.characteristicsDiscoveredPromise?.success(self)
        }
    }

    // MARK: Utils
    private func discoverIfConnected(characteristics: [CBUUID]?, timeout: NSTimeInterval?) -> Future<BCService> {
        self.characteristicsDiscoveredPromise = Promise<BCService>()
        if self.peripheral?.state == .Connected {
            self.characteristicDiscoveryComplete = false
            self.characteristicDiscoverySequence += 1
            self.timeoutCharacteristicDiscovery(self.characteristicDiscoverySequence, timeout: timeout)
            self.peripheral?.discoverCharacteristics(characteristics, forService:self)
        } else {
            self.characteristicsDiscoveredPromise?.failure(BCError.peripheralDisconnected)
        }
        return self.characteristicsDiscoveredPromise!.future
    }

    private func timeoutCharacteristicDiscovery(sequence: Int, timeout: NSTimeInterval?) {
        guard let peripheral = peripheral, centralManager = peripheral.centralManager, timeout = timeout else {
            return
        }
        BCLogger.debug("name = \(self.name), uuid = \(peripheral.identifier.UUIDString), sequence = \(sequence), timeout = \(timeout)")
        BCPeripheral.timeoutQueue.delay(timeout) {
            if sequence == self.characteristicDiscoverySequence && !self.characteristicDiscoveryComplete {
                BCLogger.debug("characteristic scan timing out name = \(self.name), UUID = \(self.UUID.UUIDString), peripheral UUID = \(peripheral.identifier.UUIDString), sequence=\(sequence), current sequence = \(self.characteristicDiscoverySequence)")
                centralManager.cancelPeripheralConnection(peripheral)
                self.characteristicsDiscoveredPromise?.failure(BCError.serviceCharacteristicDiscoveryTimeout)
            } else {
                BCLogger.debug("characteristic scan timeout expired name = \(self.name), UUID = \(self.UUID.UUIDString), peripheral UUID = \(peripheral.identifier.UUIDString), sequence = \(sequence), current connectionSequence=\(self.characteristicDiscoverySequence)")
            }
        }
    }

}