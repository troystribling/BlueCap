//
//  Errors.swift
//  BlueCap
//
//  Created by Troy Stribling on 7/5/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import Foundation

// MARK: - Errors -
public enum CharacteristicError : Swift.Error {
    case readTimeout
    case writeTimeout
    case notSerializable
    case readNotSupported
    case writeNotSupported
    case notifyNotSupported
}

public enum PeripheralError : Swift.Error {
    case disconnected
    case serviceDiscoveryTimeout
}

public enum PeripheralManagerError : Swift.Error {
    case isAdvertising
    case restoreFailed
    case notSerializable
}

public enum MutableCharacteristicError : Swift.Error {
    case unconfigured
    case notSerializable
    case notifyNotSupported
}

public enum CentralManagerError : Swift.Error {
    case isScanning
    case isPoweredOff
    case restoreFailed
    case peripheralScanTimeout
}

public enum ServiceError : Swift.Error {
    case characteristicDiscoveryTimeout
}

