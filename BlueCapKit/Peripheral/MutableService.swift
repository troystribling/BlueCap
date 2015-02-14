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
    
    private let profile             : ServiceProfile
    private var _characteristics    : [MutableCharacteristic] = []

    internal let cbMutableService   : CBMutableService

    public var uuid : CBUUID {
        return self.profile.uuid
    }
    
    public var name : String {
        return self.profile.name
    }
    
    public var characteristics : [MutableCharacteristic] {
        get {
            return self._characteristics
        }
        set {
            self._characteristics = newValue
            self.cbMutableService.characteristics = self._characteristics.reduce([CBMutableCharacteristic]()) {(cbCharacteristics, characteristic) in
                                                            PeripheralManager.sharedInstance.configuredCharcteristics[characteristic.cbMutableChracteristic] = characteristic
                                                            return cbCharacteristics + [characteristic.cbMutableChracteristic]
                                                        }
        }
    }
    
    public init(profile:ServiceProfile) {
        self.profile = profile
        self.cbMutableService = CBMutableService(type:self.profile.uuid, primary:true)
        super.init()
    }
    
    public func characteristicsFromProfiles(profiles:[CharacteristicProfile]) {
        self.characteristics = profiles.map{MutableCharacteristic(profile:$0)}
    }
    
}