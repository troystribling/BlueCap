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
    case ReadTimeout = 1
    case WriteTimeout = 2
    case NotSerializable = 3
    case ReadNotSupported = 4
    case WriteNotSupported = 5
    case NotifyNotSupported = 6
}

public enum PeripheralErrorCode: Int {
    case ServiceDiscoveryTimeout = 20
    case Disconnected = 21
    case NoServices = 23
    case ServiceDiscoveryInProgress = 24
}

public enum PeripheralManagerErrorCode: Int {
    case IsAdvertising = 40
    case IsNotAdvertising = 41
    case AddServiceFailed = 42
    case RestoreFailed = 43
    case PeripheralStateUnsupported = 54
}

public enum CentralErrorCode: Int {
    case IsScanning = 50
    case IsPoweredOff = 51
    case RestoreFailed = 52
    case PeripheralScanTimeout = 53
    case CentralStateUnsupported = 54
}

public enum ServiceErrorCode: Int {
    case CharacteristicDiscoveryTimeout = 60
    case CharacteristicDiscoveryInProgress = 61
}


// MARK: - Errors -
public struct BCError {
    public static let domain = "BlueCap"

    // MARK: Characteristic
    public static let characteristicReadTimeout = NSError(domain: domain, code: CharacteristicErrorCode.ReadTimeout.rawValue, userInfo: [NSLocalizedDescriptionKey:"Characteristic read timeout"])
    public static let characteristicWriteTimeout = NSError(domain: domain, code: CharacteristicErrorCode.WriteTimeout.rawValue, userInfo: [NSLocalizedDescriptionKey:"Characteristic write timeout"])
    public static let characteristicNotSerilaizable = NSError(domain: domain, code: CharacteristicErrorCode.NotSerializable.rawValue, userInfo:[NSLocalizedDescriptionKey:"Characteristic not serializable"])
    public static let characteristicReadNotSupported = NSError(domain: domain, code: CharacteristicErrorCode.ReadNotSupported.rawValue, userInfo: [NSLocalizedDescriptionKey:"Characteristic read not supported"])
    public static let characteristicWriteNotSupported = NSError(domain: domain, code: CharacteristicErrorCode.WriteNotSupported.rawValue, userInfo: [NSLocalizedDescriptionKey:"Characteristic write not supported"])
    public static let characteristicNotifyNotSupported = NSError(domain: domain, code: CharacteristicErrorCode.NotifyNotSupported.rawValue, userInfo: [NSLocalizedDescriptionKey:"Characteristic notify not supported"])

    // MARK: Peripheral
    public static let peripheralDisconnected = NSError(domain: domain, code: PeripheralErrorCode.Disconnected.rawValue, userInfo: [NSLocalizedDescriptionKey:"Peripheral disconnected"])
    public static let peripheralServiceDiscoveryTimeout = NSError(domain: domain, code: PeripheralErrorCode.ServiceDiscoveryTimeout.rawValue, userInfo: [NSLocalizedDescriptionKey:"SErvice discovery timeout"])
    public static let peripheralNoServices = NSError(domain: domain, code: PeripheralErrorCode.NoServices.rawValue, userInfo: [NSLocalizedDescriptionKey:"Peripheral services not found"])
    public static let peripheralServiceDiscoveryInProgress = NSError(domain: domain, code: PeripheralErrorCode.ServiceDiscoveryInProgress.rawValue, userInfo: [NSLocalizedDescriptionKey:"Service discovery in progress"])

    // MARK: Peipheral Manager
    public static let peripheralManagerIsAdvertising = NSError(domain: domain, code: PeripheralManagerErrorCode.IsAdvertising.rawValue, userInfo: [NSLocalizedDescriptionKey:"Peripheral Manager is Advertising"])
    public static let peripheralManagerIsNotAdvertising = NSError(domain: domain, code: PeripheralManagerErrorCode.IsNotAdvertising.rawValue, userInfo: [NSLocalizedDescriptionKey:"Peripheral Manager is not Advertising"])
    public static let peripheralManagerAddServiceFailed = NSError(domain: domain, code: PeripheralManagerErrorCode.AddServiceFailed.rawValue, userInfo: [NSLocalizedDescriptionKey:"Add service failed because service peripheral is advertising"])
    public static let peripheralManagerRestoreFailed = NSError(domain: domain, code: PeripheralManagerErrorCode.RestoreFailed.rawValue, userInfo: [NSLocalizedDescriptionKey:"Error unpacking restored state"])
    public static let peripheralStateUnsupported = NSError(domain: domain, code: PeripheralManagerErrorCode.PeripheralStateUnsupported.rawValue, userInfo: [NSLocalizedDescriptionKey:"Bluetooth not supported"])

    // MARKL=: Central
    public static let centralIsScanning = NSError(domain: domain, code: CentralErrorCode.IsScanning.rawValue, userInfo: [NSLocalizedDescriptionKey:"Central is scanning"])
    public static let centralIsPoweredOff = NSError(domain: domain, code: CentralErrorCode.IsPoweredOff.rawValue, userInfo: [NSLocalizedDescriptionKey:"Central is powered off"])
    public static let centralRestoreFailed = NSError(domain: domain, code: CentralErrorCode.RestoreFailed.rawValue, userInfo: [NSLocalizedDescriptionKey:"Error unpacking restored state"])
    public static let centralPeripheralScanTimeout = NSError(domain: domain, code: CentralErrorCode.PeripheralScanTimeout.rawValue, userInfo: [NSLocalizedDescriptionKey:"Peripheral scan timeout"])
    public static let centralStateUnsupported = NSError(domain: domain, code: CentralErrorCode.CentralStateUnsupported.rawValue, userInfo: [NSLocalizedDescriptionKey:"Bleutooth not supported"])

    // MARK: Service
    public static let serviceCharacteristicDiscoveryTimeout = NSError(domain: domain, code: ServiceErrorCode.CharacteristicDiscoveryTimeout.rawValue, userInfo: [NSLocalizedDescriptionKey:"Characteristic discovery timeout"])
    public static let serviceCharacteristicDiscoveryInProgress = NSError(domain: domain, code: ServiceErrorCode.CharacteristicDiscoveryInProgress.rawValue, userInfo: [NSLocalizedDescriptionKey:"Characteristic discovery in progress"])

}

