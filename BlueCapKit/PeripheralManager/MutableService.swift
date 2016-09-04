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

    static let ioQueue = Queue("us.gnos.blueCap.mutable-service")

    fileprivate var _characteristics = SerialIOArray<MutableCharacteristic>(MutableService.ioQueue)

    internal let profile: ServiceProfile

    internal weak var peripheralManager: PeripheralManager?

    internal let cbMutableService: CBMutableServiceInjectable

    public var UUID: CBUUID {
        return self.profile.UUID
    }
    
    public var name: String {
        return self.profile.name
    }
    
    public var characteristics: [MutableCharacteristic] {
        get {
            return self._characteristics.data
        }
        set {
            self._characteristics.data = newValue
            let cbCharacteristics = self._characteristics.map { characteristic -> CBCharacteristicInjectable in
                characteristic._service = self
                return characteristic.cbMutableChracteristic
            }
            self.cbMutableService.setCharacteristics(cbCharacteristics)
        }
    }
    
    public convenience init(profile: ServiceProfile) {
        self.init(cbMutableService: CBMutableService(type: profile.UUID, primary: true), profile: profile)
    }

    public convenience init(UUID: String) {
        self.init(profile: ServiceProfile(UUID: UUID))
    }

    internal init(cbMutableService: CBMutableServiceInjectable, profile: ServiceProfile? = nil) {
        self.cbMutableService = cbMutableService
        self.profile = profile ?? ServiceProfile(UUID: cbMutableService.UUID.uuidString)
        super.init()
    }

    public func characteristicsFromProfiles() {
        self.characteristics = self.profile.characteristics.map { MutableCharacteristic(profile: $0) }
    }
    
}
