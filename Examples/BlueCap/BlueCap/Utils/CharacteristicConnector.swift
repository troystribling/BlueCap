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

    var characteristic: Characteristic?
    var peripheral: Peripheral?

    var characteristicUUID: CBUUID
    var serviceUUID: CBUUID
    var viewController: UIViewController

    let progressView = ProgressView()

    var connectionPromise = StreamPromise<(Peripheral, Characteristic)>()

    init(characteristicUUID: CBUUID, serviceUUID: CBUUID, peripheralIdentifier: UUID, viewController: UIViewController) {
        peripheral = Singletons.communicationManager.retrievePeripherals(withIdentifiers: [peripheralIdentifier]).first
        self.characteristicUUID = characteristicUUID
        self.serviceUUID = serviceUUID
        self.viewController = viewController
    }

    func connect() {
        guard let peripheral = peripheral else {
            return
        }
        Logger.debug("Connect peripheral: '\(peripheral.name)'', \(peripheral.identifier.uuidString)")
        progressView.show()
        let maxTimeouts = ConfigStore.getPeripheralMaximumTimeoutsEnabled() ? ConfigStore.getPeripheralMaximumTimeouts() : UInt.max
        let maxDisconnections = ConfigStore.getPeripheralMaximumDisconnectionsEnabled() ? ConfigStore.getPeripheralMaximumDisconnections() : UInt.max
        let connectionTimeout = ConfigStore.getPeripheralConnectionTimeoutEnabled() ? Double(ConfigStore.getPeripheralConnectionTimeout()) : Double.infinity
        let connectionFuture = peripheral.connect(timeoutRetries: maxTimeouts, disconnectRetries: maxDisconnections, connectionTimeout: connectionTimeout, capacity: 10)

        connectionFuture.onSuccess { [weak self] (peripheral, connectionEvent) in
            self.forEach { strongSelf in
                switch connectionEvent {
                case .connect:
                    strongSelf.discoverPeripheralService()
                case .timeout:
                    strongSelf.reconnect()
                case .disconnect:
                    strongSelf.reconnect()
                case .forceDisconnect:
                    fallthrough
                case .giveUp:
                    strongSelf.progressView.remove()
                    strongSelf.viewController.present(UIAlertController.alertWithMessage("Connection to `\(peripheral.name)` failed"), animated:true, completion:nil)
                }
            }
        }

        connectionFuture.onFailure { [weak self] error in
            self.forEach { strongSelf in
                strongSelf.connect()
                strongSelf.viewController.present(UIAlertController.alertOnError("Connection", error: error) { _ in
                    strongSelf.progressView.remove()
                }, animated: true, completion: nil)
            }
        }
    }

    func reconnect() {
        guard let peripheral = peripheral else {
            return
        }
        peripheral.reconnect()
    }

    func discoverPeripheralService() {
        guard let peripheral = peripheral, peripheral.state == .connected else {
                progressView.remove()
                return
        }
        let serviceDiscoveryFuture = peripheral.discoverServices([serviceUUID]).flatMap { peripheral in
            peripheral.services.map { $0.discoverAllCharacteristics() }.sequence()
        }
        serviceDiscoveryFuture.onSuccess { [weak self] peripherals in
            self.forEach { strongSelf in
                strongSelf.characteristic = peripheral.service(strongSelf.serviceUUID)?.characteristic(strongSelf.characteristicUUID)
                strongSelf.progressView.remove()
                if let characteristic = strongSelf.characteristic {
                    Logger.debug("Discovered charcateristic \(characteristic.name), \(characteristic.UUID)")
                } else {
                    Logger.debug("Characteristic discovery failed")
                }
            }
        }
        serviceDiscoveryFuture.onFailure { [weak self] (error) in
            self.forEach { strongSelf in
                strongSelf.viewController.present(UIAlertController.alertOnError("Peripheral discovery error", error: error) { _ in
                    strongSelf.progressView.remove()
                }, animated: true, completion: nil)
                Logger.debug("Service discovery failed")
            }
        }
    }
}
