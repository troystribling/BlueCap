//
//  Errors.swift
//  BlueCap
//
//  Created by Troy Stribling on 7/5/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation

public enum CharacteristicError : Int {
    case ReadTimeout        = 1
    case WriteTimeout       = 2
    case NotSerializable    = 3
    case ReadNotSupported   = 4
    case WriteNotSupported  = 5
}

public enum ConnectoratorError : Int {
    case Timeout            = 10
    case Disconnect         = 11
    case ForceDisconnect    = 12
    case Failed             = 13
    case GiveUp             = 14
}

public enum PeripheralError : Int {
    case DiscoveryTimeout   = 20
    case Disconnected       = 21
}

public enum PeripheralManagerError : Int {
    case IsAdvertising      = 40
    case AddServiceFailed   = 41
}

public enum CentralError : Int {
    case IsScannong         = 50
}

public struct BCError {
    public static let domain = "BlueCap"
    
    public static let characteristicReadTimeout = NSError(domain:domain, code:CharacteristicError.ReadTimeout.rawValue, userInfo:[NSLocalizedDescriptionKey:"Characteristic read timeout"])
    public static let characteristicWriteTimeout = NSError(domain:domain, code:CharacteristicError.WriteTimeout.rawValue, userInfo:[NSLocalizedDescriptionKey:"Characteristic write timeout"])
    public static let characteristicNotSerilaizable = NSError(domain:domain, code:CharacteristicError.NotSerializable.rawValue, userInfo:[NSLocalizedDescriptionKey:"Characteristic not serializable"])
    public static let characteristicReadNotSupported = NSError(domain:domain, code:CharacteristicError.ReadNotSupported.rawValue, userInfo:[NSLocalizedDescriptionKey:"Characteristic read not supported"])
    public static let characteristicWriteNotSupported = NSError(domain:domain, code:CharacteristicError.WriteNotSupported.rawValue, userInfo:[NSLocalizedDescriptionKey:"Characteristic write not supported"])

    public static let connectoratorTimeout = NSError(domain:domain, code:ConnectoratorError.Timeout.rawValue, userInfo:[NSLocalizedDescriptionKey:"Connectorator timeout"])
    public static let connectoratorDisconnect = NSError(domain:domain, code:ConnectoratorError.Disconnect.rawValue, userInfo:[NSLocalizedDescriptionKey:"Connectorator disconnect"])
    public static let connectoratorForcedDisconnect = NSError(domain:domain, code:ConnectoratorError.ForceDisconnect.rawValue, userInfo:[NSLocalizedDescriptionKey:"Connectorator forced disconnected"])
    public static let connectoratorFailed = NSError(domain:domain, code:ConnectoratorError.Failed.rawValue, userInfo:[NSLocalizedDescriptionKey:"Connectorator connection failed"])
    public static let connectoratorGiveUp = NSError(domain:domain, code:ConnectoratorError.GiveUp.rawValue, userInfo:[NSLocalizedDescriptionKey:"Connectorator giving up"])

    public static let peripheralDisconnected = NSError(domain:domain, code:PeripheralError.Disconnected.rawValue, userInfo:[NSLocalizedDescriptionKey:"Peripheral disconnected timeout"])
    public static let peripheralDiscoveryTimeout = NSError(domain:domain, code:PeripheralError.DiscoveryTimeout.rawValue, userInfo:[NSLocalizedDescriptionKey:"Peripheral discovery Timeout"])
        
    public static let peripheralManagerIsAdvertising = NSError(domain:domain, code:PeripheralManagerError.IsAdvertising.rawValue, userInfo:[NSLocalizedDescriptionKey:"Peripheral Manager is Advertising"])
    public static let peripheralManagerAddServiceFailed = NSError(domain:domain, code:PeripheralManagerError.AddServiceFailed.rawValue, userInfo:[NSLocalizedDescriptionKey:"Add service failed because service peripheral is advertising"])
    
    public static let centralIsScanning = NSError(domain:domain, code:CentralError.IsScannong.rawValue, userInfo:[NSLocalizedDescriptionKey:"Central is scanning"])

}

