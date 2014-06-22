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
    
    var discoveredCharacteristics   = Dictionary<String, Characteristic>()
    var characteristicsDiscovered   : ((characteristics:Characteristic[]!) -> ())?

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
    
    init(cbService:CBService, peripheral:Peripheral) {
        self.cbService = cbService
        self.perpheral = peripheral
        self.profile = ProfileManager.sharedInstance().serviceProfiles[cbService.UUID]
    }
    
}