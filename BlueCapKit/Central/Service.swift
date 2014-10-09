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
    private let profile                                     : ServiceProfile?
    private var characteristicsDiscoveredSuccessCallback    : (() -> ())?
    private var characteristicDiscoveryFailedCallback       : ((error:NSError!) -> ())?
    private var characteristicDiscoveryTimeout              : Float?

    // INTERNAL
    internal let perpheral                      : Peripheral
    internal let cbService                      : CBService
    
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
    
    // PUBLIC
    public func discoverAllCharacteristics(characteristicsDiscoveredSuccessCallback:() -> ()) {
        Logger.debug("Service#discoverAllCharacteristics")
        self.characteristicsDiscoveredSuccessCallback = characteristicsDiscoveredSuccessCallback
        self.perpheral.cbPeripheral.discoverCharacteristics(nil, forService:self.cbService)
    }
    
    public func discoverCharacteristics(characteristics:[CBUUID], characteristicsDiscoveredSuccessCallback:() -> ()) {
        Logger.debug("Service#discoverCharacteristics")
        self.characteristicsDiscoveredSuccessCallback = characteristicsDiscoveredSuccessCallback
        self.perpheral.cbPeripheral.discoverCharacteristics(characteristics, forService:self.cbService)
    }
    
    // INTERNAL
    internal init(cbService:CBService, peripheral:Peripheral) {
        self.cbService = cbService
        self.perpheral = peripheral
        self.profile = ProfileManager.sharedInstance().serviceProfiles[cbService.UUID]
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
            if let characteristicsDiscoveredSuccessCallback = self.characteristicsDiscoveredSuccessCallback {
                CentralManager.asyncCallback(characteristicsDiscoveredSuccessCallback)
            }
        }
    }
}