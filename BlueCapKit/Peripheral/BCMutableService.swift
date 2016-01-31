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

    private let profile: ServiceProfile

    internal weak var peripheralManager: BCPeripheralManager?

    public let cbMutableService: CBMutableService

    public var uuid: CBUUID {
        return self.profile.uuid
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
    
    public init(profile: ServiceProfile, peripheralManager: BCPeripheralManager) {
        self.profile = profile
        self.peripheralManager = peripheralManager
        self.cbMutableService = CBMutableService(type: self.profile.uuid, primary: true)
        super.init()
    }
    
    public convenience init(uuid: String, peripheralManager: BCPeripheralManager) {
        self.init(profile:ServiceProfile(uuid: uuid), peripheralManager:peripheralManager)
    }

    public func characteristicsFromProfiles() {
        self.characteristics = self.profile.characteristics.map{ BCMutableCharacteristic(profile: $0) }
    }
    
}