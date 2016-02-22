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

    private let profile: BCServiceProfile

    internal weak var peripheralManager: BCPeripheralManager?

    public let cbMutableService: CBMutableService

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
            let cbCharacteristics = self._characteristics.map {characteristic -> CBMutableCharacteristic in
                characteristic._service = self
                return characteristic.cbMutableChracteristic
            }
            self.cbMutableService.characteristics = cbCharacteristics
        }
    }
    
    public init(profile: BCServiceProfile) {
        self.profile = profile
        self.cbMutableService = CBMutableService(type: self.profile.UUID, primary: true)
        super.init()
    }

    public convenience init(UUID: String) {
        self.init(profile: BCServiceProfile(UUID: UUID))
    }

    internal init(cbMutableService: CBMutableService) {
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
        self.characteristics = self.profile.characteristics.map{ BCMutableCharacteristic(profile: $0) }
    }
    
}