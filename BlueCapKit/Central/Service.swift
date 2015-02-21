//
//  Service.swift
//  BlueCap
//
//  Created by Troy Stribling on 6/11/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation
import CoreBluetooth

///////////////////////////////////////////
// ServiceImpl
public struct ServiceImpl<T> {
        
}
// ServiceImpl
///////////////////////////////////////////

public class Service : NSObject {
    
    private let profile                             : ServiceProfile?
    private var characteristicsDiscoveredPromise    = Promise<[Characteristic]>()

    internal let _peripheral                        : Peripheral
    internal let cbService                          : CBService
    
    internal var discoveredCharacteristics  = [CBUUID:Characteristic]()
    
    public var name : String {
        if let profile = self.profile {
            return profile.name
        } else {
            return "Unknown"
        }
    }
    
    public var uuid : CBUUID! {
        return self.cbService.UUID
    }
    
    public var characteristics : [Characteristic] {
        return self.discoveredCharacteristics.values.array
    }
    
    public var peripheral : Peripheral {
        return self._peripheral
    }
    
    public func discoverAllCharacteristics() -> Future<[Characteristic]> {
        Logger.debug("Service#discoverAllCharacteristics")
        return self.discoverIfConnected(nil)
    }

    public func discoverCharacteristics(characteristics:[CBUUID]) -> Future<[Characteristic]> {
        Logger.debug("Service#discoverCharacteristics")
        return self.discoverIfConnected(characteristics)
    }

    private func discoverIfConnected(services:[CBUUID]!) -> Future<[Characteristic]> {
        self.characteristicsDiscoveredPromise = Promise<[Characteristic]>()
        if self.peripheral.state == .Connected {
            self.peripheral.cbPeripheral.discoverCharacteristics(nil, forService:self.cbService)
        } else {
            self.characteristicsDiscoveredPromise.failure(BCError.peripheralDisconnected)
        }
        return self.characteristicsDiscoveredPromise.future
    }

    internal init(cbService:CBService, peripheral:Peripheral) {
        self.cbService = cbService
        self._peripheral = peripheral
        self.profile = ProfileManager.sharedInstance.serviceProfiles[cbService.UUID]
    }
    
    internal func didDiscoverCharacteristics(error:NSError!) {
        if let error = error {
            self.characteristicsDiscoveredPromise.failure(error)
        } else {
            self.discoveredCharacteristics.removeAll()
            for characteristic in self.cbService.characteristics {
                let cbCharacteristic = characteristic as! CBCharacteristic
                let bcCharacteristic = Characteristic(cbCharacteristic:cbCharacteristic, service:self)
                self.discoveredCharacteristics[bcCharacteristic.uuid] = bcCharacteristic
                bcCharacteristic.didDiscover()
                Logger.debug("Service#didDiscoverCharacteristics: uuid=\(bcCharacteristic.uuid.UUIDString), name=\(bcCharacteristic.name)")
            }
            self.characteristicsDiscoveredPromise.success(self.characteristics)
        }
    }
}