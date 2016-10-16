//
//  DiscoveredPeripheralStore.swift
//  BlueCap
//
//  Created by Troy Stribling on 10/5/16.
//  Copyright © 2016 Troy Stribling. All rights reserved.
//

import Foundation

class DiscoveredPeripheralStore {

    class func getPeripheralIdentifiers() -> [UUID] {
        guard let peripherals = UserDefaults.standard.array(forKey: "discoveredPeripherals") else {
            return []
        }
        return peripherals.reduce([UUID]()) { (uuids, id) in
            guard let id = id as? String, let uuid = UUID(uuidString: id) else {
                return uuids
            }
            return uuids + [uuid]
        }
    }

    class func setPeripheralIdentifiers(_ peripheralIdentifier: [UUID]) {
        UserDefaults.standard.set(peripheralIdentifier.map { $0.uuidString }, forKey: "discoveredPeripherals")
    }

    class func addPeripheralIdentifier(_ peripheralIdentifier: UUID) {
        let peripherals = getPeripheralIdentifiers()
        if !peripherals.contains(peripheralIdentifier) {
            setPeripheralIdentifiers(peripherals + [peripheralIdentifier])
        }
    }
}
