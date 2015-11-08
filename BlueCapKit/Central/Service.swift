//
//  Service.swift
//  BlueCap
//
//  Created by Troy Stribling on 6/11/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import Foundation
import CoreBluetooth

public protocol CBServiceWrappable {
    var UUID : CBUUID                           {get}
    var characteristics : [CBCharacteristic]?   {get}
}

extension CBService : CBServiceWrappable {}

public final class Service {

    private let profile : ServiceProfile?
    private var characteristicsDiscoveredPromise    = Promise<Service>()

    internal var discoveredCharacteristics          = [CBUUID:Characteristic]()

    internal let cbService : CBServiceWrappable
    private weak var _peripheral : Peripheral?
    
    
    public var name : String {
        if let profile = self.profile {
            return profile.name
        } else {
            return "Unknown"
        }
    }
    
    public var uuid : CBUUID {
        return self.cbService.UUID
    }
    
    public var characteristics : [Characteristic] {
        return Array(self.discoveredCharacteristics.values)
    }
    
    public var peripheral : Peripheral? {
        return self._peripheral
    }
    
    public func discoverAllCharacteristics() -> Future<Service> {
        Logger.debug("uuid=\(self.uuid.UUIDString), name=\(self.name)")
        return self.discoverIfConnected(nil)
    }
    
    public func discoverCharacteristics(characteristics:[CBUUID]) -> Future<Service> {
        Logger.debug("uuid=\(self.uuid.UUIDString), name=\(self.name)")
        return self.discoverIfConnected(characteristics)
    }
    
    public func characteristic(uuid:CBUUID) -> Characteristic? {
        return self.discoveredCharacteristics[uuid]
    }

    public func didDiscoverCharacteristics(discoveredCharacteristics:[CBCharacteristicWrappable], error:NSError?) {
        if let error = error {
            Logger.debug("discover failed")
            self.characteristicsDiscoveredPromise.failure(error)
        } else {
            self.discoveredCharacteristics.removeAll()
            for cbCharacteristic in discoveredCharacteristics {
                let bcCharacteristic = Characteristic(cbCharacteristic:cbCharacteristic, service:self)
                self.discoveredCharacteristics[bcCharacteristic.uuid] = bcCharacteristic
                Logger.debug("uuid=\(self.uuid.UUIDString), name=\(self.name)")
                bcCharacteristic.afterDiscoveredPromise?.success(bcCharacteristic)
                Logger.debug("uuid=\(bcCharacteristic.uuid.UUIDString), name=\(bcCharacteristic.name)")
            }
            Logger.debug("discover success")
            self.characteristicsDiscoveredPromise.success(self)
        }
    }
    
    internal init(cbService:CBServiceWrappable, peripheral:Peripheral) {
        self.cbService = cbService
        self._peripheral = peripheral
        self.profile = ProfileManager.sharedInstance.serviceProfiles[cbService.UUID]
    }

    private func createCharacteristics() {
        
    }

    private func discoverIfConnected(characteristics:[CBUUID]?) -> Future<Service> {
        self.characteristicsDiscoveredPromise = Promise<Service>()
        if self.peripheral?.state == .Connected {
            self.peripheral?.discoverCharacteristics(characteristics, forService:self)
        } else {
            self.characteristicsDiscoveredPromise.failure(BCError.peripheralDisconnected)
        }
        return self.characteristicsDiscoveredPromise.future
    }
}