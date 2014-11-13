//
//  Errors.swift
//  BlueCap
//
//  Created by Troy Stribling on 7/5/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation

struct BCError {
    static let domain = "BlueCap"
    struct CharacteristicReadTimeout {
        static let code = 1
        static let description = "Characteristic read timeout"
    }
    struct CharacteristicWriteTimeout {
        static let code = 2
        static let description = "Characteristic write timeout"
    }
    struct PeripheralDisconnected {
        static let code = 3
        static let description = "Peripheral Disconnected"
    }
    struct ServiceDiscoveryTimeout {
        static let code = 4
        static let description = "Service Discovery Timeout"
    }
    struct LocationUpdateFailed {
        static let code = 5
        static let description = "Location update failed"
    }
}

