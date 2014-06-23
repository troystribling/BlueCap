//
//  Service.swift
//  BlueCap
//
//  Created by Troy Stribling on 6/11/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation
import CoreBluetooth

class Service : NSObject {
    
    let cbService   : CBService!
    let perpheral   : Peripheral!
    let profile     : ServiceProfile?
    
    var discoveredCharacteristics   = Dictionary<CBUUID, Characteristic>()
    var characteristicsDiscovered   : (() -> ())?

    var name : String {
        if let profile = self.profile {
            return profile.name
        } else {
            return "Unknown"
        }
    }
    
    var uuid : CBUUID {
        return self.cbService.UUID
    }
    
    var characteristics : Characteristic[] {
        return Array(self.discoveredCharacteristics.values)
    }
    
    // APPLICATION INTERFACE
    init(cbService:CBService, peripheral:Peripheral) {
        self.cbService = cbService
        self.perpheral = peripheral
        self.profile = ProfileManager.sharedInstance().serviceProfiles[cbService.UUID]
    }
    
    func discoverAllCharacteristics(characteristicsDiscovered:() -> ()) {
        Logger.debug("Service#discoverAllCharacteristics")
        self.characteristicsDiscovered = characteristicsDiscovered
        self.perpheral.cbPeripheral.discoverCharacteristics(nil, forService:self.cbService)
    }
    
    func discoverCharacteristics(characteristics:CBUUID[], characteristicsDiscovered:() -> ()) {
        Logger.debug("Service#discoverCharacteristics")
        self.characteristicsDiscovered = characteristicsDiscovered
        self.perpheral.cbPeripheral.discoverCharacteristics(characteristics, forService:self.cbService)
    }
    
    // INTERNAL INTERFACE
    func didDiscoverCharacteristics() {
        self.discoveredCharacteristics.removeAll()
        for cbCharacteristic : AnyObject in self.cbService.characteristics {
            let bcCharacteristic = Characteristic(cbCharacteristic:cbCharacteristic as CBCharacteristic, service:self)
            self.discoveredCharacteristics[bcCharacteristic.uuid] = bcCharacteristic
            bcCharacteristic.didDiscover()
            Logger.debug("Service#didDiscoverCharacteristics: uuid=\(bcCharacteristic.uuid.UUIDString), name=\(bcCharacteristic.name)")
        }
        if let characteristicsDiscovered = self.characteristicsDiscovered {
            CentralManager.asyncCallback(characteristicsDiscovered)
        }
    }
}