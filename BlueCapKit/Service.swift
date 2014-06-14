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
    
    let cbService           : CBService!
    var discoveredServices  : Dictionary<String, Characteristic> = [:]
    
    var characteristicsDiscovered   : ((characteristics:Characteristic[]!) -> ())?

    init(cbService:CBService) {
        self.cbService = cbService
    }
    
}