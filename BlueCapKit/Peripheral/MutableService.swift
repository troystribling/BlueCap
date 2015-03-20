//
//  MutableService.swift
//  BlueCap
//
//  Created by Troy Stribling on 8/9/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation
import CoreBluetooth

///////////////////////////////////////////
// MutableServiceImpl
public protocol MutableServiceWrappable {
    var uuid            : CBUUID            {get}
    var name            : String            {get}
}
// MutableServiceImpl
///////////////////////////////////////////

public class MutableService : NSObject, MutableServiceWrappable {

    // MutableServiceWrappable
    public var uuid : CBUUID {
        return self.profile.uuid
    }
    
    public var name : String {
        return self.profile.name
    }
    // MutableServiceWrappable

    private let profile             : ServiceProfile
    private var _characteristics    : [MutableCharacteristic] = []

    internal let cbMutableService   : CBMutableService

    public var characteristics : [MutableCharacteristic] {
        get {
            return self._characteristics
        }
        set {
            self._characteristics = newValue
            let cbCharacteristics = self._characteristics.reduce([CBMutableCharacteristic]()) {(cbCharacteristics, characteristic) in
                PeripheralManager.sharedInstance.configuredCharcteristics[characteristic.cbMutableChracteristic] = characteristic
                return cbCharacteristics + [characteristic.cbMutableChracteristic]
            }
            self.cbMutableService.characteristics = cbCharacteristics
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