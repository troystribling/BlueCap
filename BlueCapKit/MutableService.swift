//
//  MutableService.swift
//  BlueCap
//
//  Created by Troy Stribling on 8/9/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation
import CoreBluetooth

public class MutableService : NSObject {
    
    // PRIVATE
    private let cbMutableService    : CBMutableService!
    private let profile             : ServiceProfile!
    private var _characteristics    : [MutableCharacteristic] = []
    
    // PUBLIC
    var uuid : CBUUID {
        return self.profile.uuid
    }
    
    var name : String {
        return self.profile.name
    }
    
    var characteristics : [MutableCharacteristic] {
        get {
            return self._characteristics
        }
        set {
            self._characteristics = newValue
            self.cbMutableService.characteristics = self._characteristics.reduce(Array<CBMutableCharacteristic>())
                                                        {(cbCharacteristics, characteristic) in
                                                            PeripheralManager.sharedInstance().configuredCharcteristics[characteristic.cbMutableChracteristic] = characteristic
                                                            return cbCharacteristics + [characteristic.cbMutableChracteristic]
                                                        }
        }
    }
    
    init(profile:ServiceProfile) {
        super.init()
        self.profile = profile
        self.cbMutableService = CBMutableService(type:self.profile.uuid, primary:true)
    }
    
}