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

    // MARK: Properties
    private let profile : BCServiceProfile?

    internal var discoveredCharacteristics          = [CBUUID:BCCharacteristic]()
    private var _characteristicsDiscoveredPromise   = Promise<BCService>()

    private weak var _peripheral: BCPeripheral?
    
    public let cbService: CBService

    public var characteristicsDiscoveredPromise: Promise<BCService> {
        return self._characteristicsDiscoveredPromise
    }
    
    public var name: String {
        if let profile = self.profile {
            return profile.name
        } else {
            return "Unknown"
        }
    }
    
    public var uuid: CBUUID {
        return self.cbService.UUID
    }
    
    public var characteristics: [BCCharacteristic] {
        return Array(self.discoveredCharacteristics.values)
    }
    
    public var peripheral: BCPeripheral? {
        return self._peripheral
    }

    // MARK: Initializer
    public init(cbService: CBService, peripheral: BCPeripheral) {
        self.cbService = cbService
        self._peripheral = peripheral
        self.profile = ProfileManager.sharedInstance.serviceProfiles[cbService.UUID]
    }

    // MARK: Discover Characteristics
    public func discoverAllCharacteristics() -> Future<BCService> {
        BCLogger.debug("uuid=\(self.uuid.UUIDString), name=\(self.name)")
        return self.discoverIfConnected(nil)
    }
    
    public func discoverCharacteristics(characteristics: [CBUUID]) -> Future<BCService> {
        BCLogger.debug("uuid=\(self.uuid.UUIDString), name=\(self.name)")
        return self.discoverIfConnected(characteristics)
    }
    
    public func characteristic(uuid: CBUUID) -> BCCharacteristic? {
        return self.discoveredCharacteristics[uuid]
    }

    // MARK: CBPeripheralDelegate
    public func didDiscoverCharacteristics(discoveredCharacteristics: [CBCharacteristic], error: NSError?) {
        if let error = error {
            BCLogger.debug("discover failed")
            self.characteristicsDiscoveredPromise.failure(error)
        } else {
            self.discoveredCharacteristics.removeAll()
            for cbCharacteristic in discoveredCharacteristics {
                let bcCharacteristic = BCCharacteristic(cbCharacteristic: cbCharacteristic, service: self)
                self.discoveredCharacteristics[bcCharacteristic.uuid] = bcCharacteristic
                BCLogger.debug("uuid=\(self.uuid.UUIDString), name=\(self.name)")
                bcCharacteristic.afterDiscoveredPromise?.success(bcCharacteristic)
                BCLogger.debug("uuid=\(bcCharacteristic.uuid.UUIDString), name=\(bcCharacteristic.name)")
            }
            BCLogger.debug("discover success")
            self.characteristicsDiscoveredPromise.success(self)
        }
    }
    
    private func discoverIfConnected(characteristics: [CBUUID]?) -> Future<BCService> {
        self._characteristicsDiscoveredPromise = Promise<BCService>()
        if self.peripheral?.state == .Connected {
            self.peripheral?.discoverCharacteristics(characteristics, forService:self)
        } else {
            self.characteristicsDiscoveredPromise.failure(BCError.peripheralDisconnected)
        }
        return self.characteristicsDiscoveredPromise.future
    }
}