//
//  MutableService.swift
//  BlueCap
//
//  Created by Troy Stribling on 8/9/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import Foundation
import CoreBluetooth

// MARK: - MutableService -

public class MutableService : NSObject {

    let profile: ServiceProfile

    weak var peripheralManager: PeripheralManager?
    let cbMutableService: CBMutableServiceInjectable

    public var uuid: CBUUID {
        return self.profile.uuid
    }
    
    public var name: String {
        return self.profile.name
    }
    
    public var characteristics = [MutableCharacteristic]() {
        didSet {
            let cbCharacteristics = characteristics.map { characteristic -> CBCharacteristicInjectable in
                characteristic.service = self
                return characteristic.cbMutableChracteristic
            }
            self.cbMutableService.setCharacteristics(cbCharacteristics)
        }
    }
    
    public convenience init(profile: ServiceProfile) {
        self.init(cbMutableService: CBMutableService(type: profile.uuid, primary: true), profile: profile)
    }

    public convenience init(uuid: String) {
        self.init(profile: ServiceProfile(uuid: uuid))
    }

    internal init(cbMutableService: CBMutableServiceInjectable, profile: ServiceProfile? = nil) {
        self.cbMutableService = cbMutableService
        self.profile = profile ?? ServiceProfile(uuid: cbMutableService.uuid.uuidString)
        super.init()
    }

    public func characteristicsFromProfiles() {
        self.characteristics = self.profile.characteristics.map { MutableCharacteristic(profile: $0) }
    }
    
}
