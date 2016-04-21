//
//  BCMutableService.swift
//  BlueCap
//
//  Created by Troy Stribling on 8/9/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import Foundation
import CoreBluetooth

// MARK: - BCMutableService -
public class BCMutableService : NSObject {

    static let ioQueue = Queue("us.gnos.blueCap.mutable-service")

    private var _characteristics = BCSerialIOArray<BCMutableCharacteristic>(BCMutableService.ioQueue)

    internal let profile: BCServiceProfile

    internal weak var peripheralManager: BCPeripheralManager?

    internal let cbMutableService: CBMutableServiceInjectable

    public var UUID: CBUUID {
        return self.profile.UUID
    }
    
    public var name: String {
        return self.profile.name
    }
    
    public var characteristics: [BCMutableCharacteristic] {
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
    
    public convenience init(profile: BCServiceProfile) {
        self.init(cbMutableService: CBMutableService(type: profile.UUID, primary: true), profile: profile)
    }

    public convenience init(UUID: String) {
        self.init(profile: BCServiceProfile(UUID: UUID))
    }

    internal init(cbMutableService: CBMutableServiceInjectable, profile: BCServiceProfile) {
        self.cbMutableService = cbMutableService
        self.profile = profile
        super.init()
    }

    internal init(cbMutableService: CBMutableServiceInjectable) {
        self.cbMutableService = cbMutableService
        let uuid = cbMutableService.UUID
        if let profile = BCProfileManager.sharedInstance.services[uuid] {
            self.profile = profile
        } else {
            self.profile = BCServiceProfile(UUID: uuid.UUIDString)
        }
        super.init()
    }


    public func characteristicsFromProfiles() {
        self.characteristics = self.profile.characteristics.map { BCMutableCharacteristic(profile: $0) }
    }
    
}