//
//  Service.swift
//  BlueCap
//
//  Created by Troy Stribling on 6/11/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation
import CoreBluetooth

public class Service : NSObject {
    
    // PRIVATE
    private let profile                             : ServiceProfile?
    private var characteristicsDiscoveredSuccess    : (() -> ())?
    private var characteristicDiscoveryFailed       : ((error:NSError) -> ())?

    // INTERNAL
    internal let _peripheral                        : Peripheral
    internal let cbService                          : CBService
    
    internal var discoveredCharacteristics      = Dictionary<CBUUID, Characteristic>()
    
    // PUBLIC
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
    
    // PUBLIC
    public func discoverAllCharacteristics(characteristicsDiscoveredSuccess:() -> (), characteristicDiscoveryFailed:((error:NSError) -> ())? = nil) {
        Logger.debug("Service#discoverAllCharacteristics")
        self.characteristicsDiscoveredSuccess = characteristicsDiscoveredSuccess
        self.characteristicDiscoveryFailed = characteristicDiscoveryFailed
        self.discoverIfConnected(nil)
    }

    public func discoverCharacteristics(characteristics:[CBUUID], characteristicsDiscoveredSuccess:() -> (), characteristicDiscoveryFailed:((error:NSError) -> ())? = nil) {
        Logger.debug("Service#discoverCharacteristics")
        self.characteristicsDiscoveredSuccess = characteristicsDiscoveredSuccess
        self.characteristicDiscoveryFailed = characteristicDiscoveryFailed
        self.discoverIfConnected(characteristics)
    }

    // PRIVATE
    private func discoverIfConnected(services:[CBUUID]!) {
        if self.peripheral.state == .Connected {
            self.peripheral.cbPeripheral.discoverCharacteristics(nil, forService:self.cbService)
        } else {
            if let characteristicDiscoveryFailed = self.characteristicDiscoveryFailed {
                CentralManager.asyncCallback {characteristicDiscoveryFailed(error:BCError.peripheralDisconnected)}
            }
        }
    }

    // INTERNAL
    internal init(cbService:CBService, peripheral:Peripheral) {
        self.cbService = cbService
        self._peripheral = peripheral
        self.profile = ProfileManager.sharedInstance.serviceProfiles[cbService.UUID]
    }
    
    internal func didDiscoverCharacteristics() {
        self.discoveredCharacteristics.removeAll()
        if let cbCharacteristics = self.cbService.characteristics {
            for cbCharacteristic : AnyObject in cbCharacteristics {
                let bcCharacteristic = Characteristic(cbCharacteristic:cbCharacteristic as CBCharacteristic, service:self)
                self.discoveredCharacteristics[bcCharacteristic.uuid] = bcCharacteristic
                bcCharacteristic.didDiscover()
                Logger.debug("Service#didDiscoverCharacteristics: uuid=\(bcCharacteristic.uuid.UUIDString), name=\(bcCharacteristic.name)")
            }
            if let characteristicsDiscoveredSuccess = self.characteristicsDiscoveredSuccess {
                CentralManager.asyncCallback(characteristicsDiscoveredSuccess)
            }
        }
    }
}