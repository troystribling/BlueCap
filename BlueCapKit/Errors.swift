//
//  Errors.swift
//  BlueCap
//
//  Created by Troy Stribling on 7/5/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import Foundation

// MARK: - Errors -

public enum CharacteristicError : Swift.Error, LocalizedError {
    case readTimeout
    case writeTimeout
    case notSerializable
    case readNotSupported
    case writeNotSupported
    case notifyNotSupported
    case unconfigured

    public var errorDescription: String? {
        switch self {
        case .readTimeout:
            return NSLocalizedString("Characteristic read timeout.", comment: "CharacteristicError.readTimeout")
        case .writeTimeout:
            return NSLocalizedString("Characteristic write timeout.", comment: "CharacteristicError.writeTimeout")
        case .notSerializable:
            return NSLocalizedString("Characteristic string value is not serailizable.", comment: "CharacteristicError.notSerializable")
        case .readNotSupported:
            return NSLocalizedString("Characteristic read property not enabled.", comment: "CharacteristicError.readNotSupported")
        case .writeNotSupported:
            return NSLocalizedString("Characteristic write property not enabled.", comment: "CharacteristicError.writeNotSupported")
        case .notifyNotSupported:
            return NSLocalizedString("Characteristic notify property not enabled.", comment: "CharacteristicError.notifyNotSupported")
        case .unconfigured:
            return NSLocalizedString("Characteristic needs to be added to a PeripheralManager.", comment: "CharacteristicError.unconfigured")
        }
    }

}

public enum ServiceError : Swift.Error, LocalizedError {
    case characteristicDiscoveryTimeout
    case unconfigured

    public var errorDescription: String? {
        switch self {
        case .characteristicDiscoveryTimeout:
            return NSLocalizedString("Characteristic discovery timeout.", comment: "ServiceError.characteristicDiscoveryTimeout")
        case .unconfigured:
            return NSLocalizedString("Service has no associated Peripheral.", comment: "ServiceError.unconfigured")
        }
    }
}

public enum PeripheralError : Swift.Error, LocalizedError {
    case disconnected
    case forcedDisconnect
    case connectionTimeout
    case serviceDiscoveryTimeout

    public var errorDescription: String? {
        switch self {
        case .disconnected:
            return NSLocalizedString("Peripheral disconnected.", comment: "PeripheralError.disconnected")
        case .forcedDisconnect:
            return NSLocalizedString("Peripheral disconnect called.", comment: "PeripheralError.forcedDisconnect")
        case .connectionTimeout:
            return NSLocalizedString("Peripheral connection timeout.", comment: "PeripheralError.connectionTimeout")
        case .serviceDiscoveryTimeout:
            return NSLocalizedString("Service discovery timeout.", comment: "PeripheralError.serviceDiscoveryTimeout")
        }
    }
}

public enum PeripheralManagerError : Swift.Error, LocalizedError {
    case isAdvertising
    case restoreFailed
    case stopAdvertisingTimeout

    public var errorDescription: String? {
        switch self {
        case .isAdvertising:
            return NSLocalizedString("PeripheralManager is advertising.", comment: "PeripheralManagerError.isAdvertising")
        case .restoreFailed:
            return NSLocalizedString("PeripheralManager state restoration failed.", comment: "PeripheralManagerError.restoreFailed")
        case .stopAdvertisingTimeout:
            return NSLocalizedString("PeripheralManager stopAdvertising timeout.", comment: "PeripheralManagerError.stopAdvertisingTimout")
        }

    }
}

public enum MutableServiceError : Swift.Error, LocalizedError {
    case unconfigured

    public var errorDescription: String? {
        switch self {
        case .unconfigured:
            return NSLocalizedString("MutableService has no CBMutableService.", comment: "MutableServiceError.unconfigured")
        }
    }
}

public enum MutableCharacteristicError : Swift.Error, LocalizedError {
    case unconfigured
    case notSerializable
    case notifyNotSupported

    public var errorDescription: String? {
        switch self {
        case .unconfigured:
            return NSLocalizedString("Characteristic needs to be added to a PeripheralManager.", comment: "MutableCharacteristicError.unconfigured")
        case .notSerializable:
            return NSLocalizedString("Characteristic string value is not serializable.", comment: "MutableCharacteristicError.notSerializable")
        case .notifyNotSupported:
            return NSLocalizedString("Characteristic notify property not enabled.", comment: "MutableCharacteristicError.notifyNotSupported")
        }
    }
}

public enum CentralManagerError : Swift.Error, LocalizedError {
    case isScanning
    case isPoweredOff
    case restoreFailed
    case serviceScanTimeout
    case invalidPeripheral

    public var errorDescription: String? {
        switch self {
        case .isScanning:
            return NSLocalizedString("CentralManager is scanning.", comment: "CentralManagerError.isScanning")
        case .isPoweredOff:
            return NSLocalizedString("CentralManager is powered off.", comment: "CentralManagerError.isPoweredOff")
        case .restoreFailed:
            return NSLocalizedString("CentralManager state resoration failed.", comment: "CentralManagerError.restoreFailed")
        case .serviceScanTimeout:
            return NSLocalizedString("Service scan timeout.", comment: "CentralManagerError.peripheralScanTimeout")
        case .invalidPeripheral:
            return NSLocalizedString("A CBPeripheral was discovered with conflictig UUID.", comment: "CentralManagerError.invalidPeripheral")
        }
    }
}

