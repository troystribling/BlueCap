//
//  MutableService.swift
//  BlueCap
//
//  Created by Troy Stribling on 8/9/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import Foundation
import CoreBluetooth

public class MutableService : NSObject {

    // MutableServiceWrappable
    public var uuid : CBUUID {
        return self.profile.uuid
    }
    
    public var name : String {
        return self.profile.name
    }

    private var _characteristics : [MutableCharacteristic] = []
    private let profile : ServiceProfile

    internal let cbMutableService : CBMutableService
    internal weak var peripheralManager : PeripheralManager?

    public var characteristics : [MutableCharacteristic] {
        get {
            return self._characteristics
        }
        set {
            self._characteristics = newValue
            let cbCharacteristics = self._characteristics.reduce([CBMutableCharacteristic]()) {(cbCharacteristics, characteristic) in
                characteristic.service = self
                return cbCharacteristics + [characteristic.cbMutableChracteristic]
            }
            self.cbMutableService.characteristics = cbCharacteristics
        }
    }
    
    public init(profile:ServiceProfile, peripheralManager:PeripheralManager) {
        self.profile = profile
        self.peripheralManager = peripheralManager
        self.cbMutableService = CBMutableService(type:self.profile.uuid, primary:true)
        super.init()
    }
    
    public convenience init(uuid:String, peripheralManager:PeripheralManager) {
        self.init(profile:ServiceProfile(uuid:uuid), peripheralManager:peripheralManager)
    }

    public func characteristicsFromProfiles(profiles:[CharacteristicProfile]) {
        self.characteristics = profiles.map{MutableCharacteristic(profile:$0)}
    }
    
}