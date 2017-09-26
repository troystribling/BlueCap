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

    fileprivate var characteristicDiscoverySequence = 0
    fileprivate var characteristicsDiscoveredPromise: Promise<Void>?

    // MARK: Properties

    public let uuid: CBUUID

    public var name: String {
        return profile?.name ?? "Unknown"
    }

    var discoveredCharacteristics = [CBUUID : [Characteristic]]()
    
    public var characteristics: [Characteristic] {
        return centralQueue.sync { Array(self.discoveredCharacteristics.values).flatMap { $0 } }
    }
    
    fileprivate(set) weak var profile: ServiceProfile?
    fileprivate(set) weak var cbService: CBServiceInjectable?
    public fileprivate(set) weak var peripheral: Peripheral?

    var centralQueue: Queue {
        return peripheral!.centralQueue
    }

    // MARK: Initializer

    internal init(cbService: CBServiceInjectable, peripheral: Peripheral, profile: ServiceProfile? = nil) {
        self.cbService = cbService
        self.peripheral = peripheral
        self.profile = profile
        uuid = CBUUID(data: cbService.uuid.data)
    }

    // MARK: Discover Characteristics

    public func discoverAllCharacteristics(timeout: TimeInterval = TimeInterval.infinity) -> Future<Void> {
        Logger.debug("uuid=\(uuid.uuidString), name=\(self.name)")
        return self.discoverIfConnected(nil, timeout: timeout)
    }
    
    public func discoverCharacteristics(_ characteristics: [CBUUID], timeout: TimeInterval = TimeInterval.infinity) -> Future<Void> {
        Logger.debug("uuid=\(uuid.uuidString), name=\(self.name)")
        return self.discoverIfConnected(characteristics, timeout: timeout)
    }
    
    public func characteristics(withUUID uuid: CBUUID) -> [Characteristic]? {
        return centralQueue.sync { self.discoveredCharacteristics[uuid] }
    }

    // MARK: CBPeripheralDelegate Shim

    internal func didDiscoverCharacteristics(_ characteristics: [CBCharacteristicInjectable], error: Swift.Error?) {
        guard peripheral != nil else {
            return
        }
        discoveredCharacteristics.removeAll()
        if let error = error {
            Logger.debug("Error discovering \(error), service name \(name), service uuid \(uuid), characteristic count \(discoveredCharacteristics.count)")
            if let characteristicsDiscoveredPromise = self.characteristicsDiscoveredPromise, !characteristicsDiscoveredPromise.completed {
                self.characteristicsDiscoveredPromise?.failure(error)
            }
        } else {
            characteristics.forEach { cbCharacteristic in
                let bcCharacteristic = Characteristic(cbCharacteristic: cbCharacteristic, service: self)
                Logger.debug("Discovered characterisc uuid=\(cbCharacteristic.uuid.uuidString), characteristic name=\(bcCharacteristic.name), service name \(name), service uuid \(uuid)")
                if let bcCharacteristics = discoveredCharacteristics[cbCharacteristic.uuid] {
                    discoveredCharacteristics[cbCharacteristic.uuid] = bcCharacteristics + [bcCharacteristic]
                } else {
                    discoveredCharacteristics[cbCharacteristic.uuid] = [bcCharacteristic]
                }
            }
            Logger.debug("discovery success service name \(name), service uuid \(uuid)")
            if let characteristicsDiscoveredPromise = characteristicsDiscoveredPromise, !characteristicsDiscoveredPromise.completed {
                characteristicsDiscoveredPromise.success(())
            }
        }
    }

    internal func didDisconnectPeripheral(_ error: Swift.Error?) {
        if let characteristicsDiscoveredPromise = self.characteristicsDiscoveredPromise, !characteristicsDiscoveredPromise.completed {
            characteristicsDiscoveredPromise.failure(PeripheralError.disconnected)
        }
    }

    // MARK: Utils

    fileprivate func discoverIfConnected(_ characteristics: [CBUUID]?, timeout: TimeInterval) -> Future<Void> {
        if let characteristicsDiscoveredPromise = self.characteristicsDiscoveredPromise, !characteristicsDiscoveredPromise.completed {
            return characteristicsDiscoveredPromise.future
        }
        guard let peripheral = peripheral, let cbService = cbService else {
            return Future<Void>(error: ServiceError.unconfigured)
        }
        if peripheral.state == .connected {
            characteristicsDiscoveredPromise = Promise<Void>()
            characteristicDiscoverySequence += 1
            timeoutCharacteristicDiscovery(self.characteristicDiscoverySequence, timeout: timeout)
            peripheral.discoverCharacteristics(characteristics, forService: cbService)
            return self.characteristicsDiscoveredPromise!.future
        } else {
            return Future<Void>(error: PeripheralError.disconnected)
        }
    }

    fileprivate func timeoutCharacteristicDiscovery(_ sequence: Int, timeout: TimeInterval) {
        guard let peripheral = peripheral, timeout < TimeInterval.infinity, cbService != nil else {
            return
        }
        Logger.debug("name = \(self.name), uuid = \(peripheral.identifier.uuidString), sequence = \(sequence), timeout = \(timeout)")
        centralQueue.delay(timeout) { [weak self, weak peripheral] in
            self.forEach { strongSelf in
                if let characteristicsDiscoveredPromise = strongSelf.characteristicsDiscoveredPromise, sequence == strongSelf.characteristicDiscoverySequence && !characteristicsDiscoveredPromise.completed {
                    Logger.debug("characteristic scan timing out name = \(strongSelf.name), peripheral uuid = \(String(describing: peripheral?.identifier.uuidString)), sequence=\(sequence), current sequence = \(strongSelf.characteristicDiscoverySequence)")
                    characteristicsDiscoveredPromise.failure(ServiceError.characteristicDiscoveryTimeout)
                } else {
                    Logger.debug("characteristic scan timeout expired name = \(strongSelf.name), peripheral UUID = \(String(describing: peripheral?.identifier.uuidString)), sequence = \(sequence), current sequence = \(strongSelf.characteristicDiscoverySequence)")
                }
            }
        }
    }

}
