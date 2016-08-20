//
//  BCErrors.swift
//  BlueCap
//
//  Created by Troy Stribling on 7/5/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import Foundation

// MARK: - Error Codes -
public enum CharacteristicErrorCode: Int {
    case readTimeout = 1
    case writeTimeout = 2
    case notSerializable = 3
    case readNotSupported = 4
    case writeNotSupported = 5
    case notifyNotSupported = 6
}

public enum PeripheralErrorCode: Int {
    case serviceDiscoveryTimeout = 20
    case disconnected = 21
    case noServices = 23
    case serviceDiscoveryInProgress = 24
}

public enum PeripheralManagerErrorCode: Int {
    case isAdvertising = 40
    case isNotAdvertising = 41
    case addServiceFailed = 42
    case restoreFailed = 43
    case peripheralStateUnsupported = 54
}

public enum CentralErrorCode: Int {
    case isScanning = 50
    case isPoweredOff = 51
    case restoreFailed = 52
    case peripheralScanTimeout = 53
    case centralStateUnsupported = 54
}

public enum ServiceErrorCode: Int {
    case characteristicDiscoveryTimeout = 60
    case characteristicDiscoveryInProgress = 61
}


// MARK: - Errors -
public struct BCError {
    public static let domain = "BlueCap"

    // MARK: Characteristic
    public static let characteristicReadTimeout = NSError(domain: domain, code: CharacteristicErrorCode.readTimeout.rawValue, userInfo: [NSLocalizedDescriptionKey:"Characteristic read timeout"])
    public static let characteristicWriteTimeout = NSError(domain: domain, code: CharacteristicErrorCode.writeTimeout.rawValue, userInfo: [NSLocalizedDescriptionKey:"Characteristic write timeout"])
    public static let characteristicNotSerilaizable = NSError(domain: domain, code: CharacteristicErrorCode.notSerializable.rawValue, userInfo:[NSLocalizedDescriptionKey:"Characteristic not serializable"])
    public static let characteristicReadNotSupported = NSError(domain: domain, code: CharacteristicErrorCode.readNotSupported.rawValue, userInfo: [NSLocalizedDescriptionKey:"Characteristic read not supported"])
    public static let characteristicWriteNotSupported = NSError(domain: domain, code: CharacteristicErrorCode.writeNotSupported.rawValue, userInfo: [NSLocalizedDescriptionKey:"Characteristic write not supported"])
    public static let characteristicNotifyNotSupported = NSError(domain: domain, code: CharacteristicErrorCode.notifyNotSupported.rawValue, userInfo: [NSLocalizedDescriptionKey:"Characteristic notify not supported"])

    // MARK: Peripheral
    public static let peripheralDisconnected = NSError(domain: domain, code: PeripheralErrorCode.disconnected.rawValue, userInfo: [NSLocalizedDescriptionKey:"Peripheral disconnected"])
    public static let peripheralServiceDiscoveryTimeout = NSError(domain: domain, code: PeripheralErrorCode.serviceDiscoveryTimeout.rawValue, userInfo: [NSLocalizedDescriptionKey:"SErvice discovery timeout"])
    public static let peripheralNoServices = NSError(domain: domain, code: PeripheralErrorCode.noServices.rawValue, userInfo: [NSLocalizedDescriptionKey:"Peripheral services not found"])
    public static let peripheralServiceDiscoveryInProgress = NSError(domain: domain, code: PeripheralErrorCode.serviceDiscoveryInProgress.rawValue, userInfo: [NSLocalizedDescriptionKey:"Service discovery in progress"])

    // MARK: Peipheral Manager
    public static let peripheralManagerIsAdvertising = NSError(domain: domain, code: PeripheralManagerErrorCode.isAdvertising.rawValue, userInfo: [NSLocalizedDescriptionKey:"Peripheral Manager is Advertising"])
    public static let peripheralManagerIsNotAdvertising = NSError(domain: domain, code: PeripheralManagerErrorCode.isNotAdvertising.rawValue, userInfo: [NSLocalizedDescriptionKey:"Peripheral Manager is not Advertising"])
    public static let peripheralManagerAddServiceFailed = NSError(domain: domain, code: PeripheralManagerErrorCode.addServiceFailed.rawValue, userInfo: [NSLocalizedDescriptionKey:"Add service failed because service peripheral is advertising"])
    public static let peripheralManagerRestoreFailed = NSError(domain: domain, code: PeripheralManagerErrorCode.restoreFailed.rawValue, userInfo: [NSLocalizedDescriptionKey:"Error unpacking restored state"])
    public static let peripheralStateUnsupported = NSError(domain: domain, code: PeripheralManagerErrorCode.peripheralStateUnsupported.rawValue, userInfo: [NSLocalizedDescriptionKey:"Bluetooth not supported"])

    // MARKL=: Central
    public static let centralIsScanning = NSError(domain: domain, code: CentralErrorCode.isScanning.rawValue, userInfo: [NSLocalizedDescriptionKey:"Central is scanning"])
    public static let centralIsPoweredOff = NSError(domain: domain, code: CentralErrorCode.isPoweredOff.rawValue, userInfo: [NSLocalizedDescriptionKey:"Central is powered off"])
    public static let centralRestoreFailed = NSError(domain: domain, code: CentralErrorCode.restoreFailed.rawValue, userInfo: [NSLocalizedDescriptionKey:"Error unpacking restored state"])
    public static let centralPeripheralScanTimeout = NSError(domain: domain, code: CentralErrorCode.peripheralScanTimeout.rawValue, userInfo: [NSLocalizedDescriptionKey:"Peripheral scan timeout"])
    public static let centralStateUnsupported = NSError(domain: domain, code: CentralErrorCode.centralStateUnsupported.rawValue, userInfo: [NSLocalizedDescriptionKey:"Bleutooth not supported"])

    // MARK: Service
    public static let serviceCharacteristicDiscoveryTimeout = NSError(domain: domain, code: ServiceErrorCode.characteristicDiscoveryTimeout.rawValue, userInfo: [NSLocalizedDescriptionKey:"Characteristic discovery timeout"])
    public static let serviceCharacteristicDiscoveryInProgress = NSError(domain: domain, code: ServiceErrorCode.characteristicDiscoveryInProgress.rawValue, userInfo: [NSLocalizedDescriptionKey:"Characteristic discovery in progress"])

}

