//
//  CharacteristicConnector.swift
//  BlueCap
//
//  Created by Troy Stribling on 10/26/16.
//  Copyright © 2016 Troy Stribling. All rights reserved.
//

import Foundation
import CoreBluetooth
import BlueCapKit

class CharacteristicConnector {

    enum CharacteristicConnectorError: Swift.Error {
        case disconnected
        case peripheralNotFound
        case characteristicNotFound
        case connectionFailed
    }

    var characteristicUUID: CBUUID
    var serviceUUID: CBUUID
    var peripheralIdentifier: UUID

    var connectionPromise = StreamPromise<(Peripheral, Characteristic)>()

    init(characteristicUUID: CBUUID, serviceUUID: CBUUID, peripheralIdentifier: UUID) {
        self.characteristicUUID = characteristicUUID
        self.serviceUUID = serviceUUID
        self.peripheralIdentifier = peripheralIdentifier
    }

    func connect() -> FutureStream<(Peripheral, Characteristic)> {
        guard let peripheral = Singletons.communicationManager.retrievePeripherals(withIdentifiers: [peripheralIdentifier]).first else {
           return FutureStream<(Peripheral, Characteristic)>(error: CharacteristicConnectorError.peripheralNotFound)
        }
        connect(peripheral: peripheral)
        return connectionPromise.stream
    }

    private func connect(peripheral: Peripheral) {
        Logger.debug("Connect peripheral: '\(peripheral.name)'', \(peripheral.identifier.uuidString)")
        let maxTimeouts = ConfigStore.getPeripheralMaximumTimeoutsEnabled() ? ConfigStore.getPeripheralMaximumTimeouts() : UInt.max
        let maxDisconnections = ConfigStore.getPeripheralMaximumDisconnectionsEnabled() ? ConfigStore.getPeripheralMaximumDisconnections() : UInt.max
        let connectionTimeout = ConfigStore.getPeripheralConnectionTimeoutEnabled() ? Double(ConfigStore.getPeripheralConnectionTimeout()) : Double.infinity
        let connectionFuture = peripheral.connect(timeoutRetries: maxTimeouts,
                                                  disconnectRetries: maxDisconnections,
                                                  connectionTimeout: connectionTimeout,
                                                  capacity: 10)
            .flatMap { [weak self] (peripheral, connectionEvent) -> Future<[Service]> in
                guard let strongSelf = self else {
                    throw CharacteristicConnectorError.connectionFailed
                }
                switch connectionEvent {
                case .connect:
                    return peripheral.discoverServices([strongSelf.serviceUUID]).flatMap { peripheral in
                        peripheral.services.map { $0.discoverAllCharacteristics() }.sequence()
                    }
                case .timeout:
                    throw CharacteristicConnectorError.disconnected
                case .disconnect:
                    throw CharacteristicConnectorError.disconnected
                case .forceDisconnect:
                    throw CharacteristicConnectorError.connectionFailed
                case .giveUp:
                    throw CharacteristicConnectorError.connectionFailed
                }
        }

        connectionFuture.onSuccess { [weak self] _ in
            self.forEach { strongSelf in
                if let characteristic = peripheral.service(strongSelf.serviceUUID)?.characteristic(strongSelf.characteristicUUID) {
                    Logger.debug("Discovered charcateristic \(characteristic.name), \(characteristic.UUID)")
                } else {
                    Logger.debug("Characteristic discovery failed")
                }
            }
        }

        connectionFuture.onFailure { [weak self] error in
            switch error {
            case CharacteristicConnectorError.disconnected:
                peripheral.reconnect()
            default:
                self?.connectionPromise.failure(error)
            }
        }
    }
}
