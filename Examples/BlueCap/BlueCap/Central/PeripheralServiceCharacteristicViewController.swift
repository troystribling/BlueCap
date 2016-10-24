//
//  PeripheralServiceCharacteristicViewController.swift
//  BlueCap
//
//  Created by Troy Stribling on 6/23/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import UIKit
import BlueCapKit
import CoreBluetooth

class PeripheralServiceCharacteristicViewController : UITableViewController {

    struct MainStoryboard {
        static let peripheralServiceCharacteristicValueSegue = "PeripheralServiceCharacteristicValues"
        static let peripheralServiceCharacteristicEditWriteOnlyDiscreteValuesSegue = "PeripheralServiceCharacteristicEditWriteOnlyDiscreteValues"
        static let peripheralServiceCharacteristicEditWriteOnlyValueSeque = "PeripheralServiceCharacteristicEditWriteOnlyValue"
    }
    
    weak var discoveredCharacteristic: Characteristic?
    weak var peripheral: Peripheral?

    var characteristic: Characteristic?
    var discoveredPeripheral: Peripheral?

    var connectionFuture: FutureStream<(peripheral: Peripheral, connectionEvent: ConnectionEvent)>?
    let progressView = ProgressView()
    
    @IBOutlet var valuesLabel: UILabel!

    @IBOutlet var notifySwitch: UISwitch!
    @IBOutlet var notifyLabel: UILabel!
    
    @IBOutlet var uuidLabel: UILabel!
    @IBOutlet var broadcastingLabel: UILabel!
    @IBOutlet var notifyingLabel: UILabel!
    
    @IBOutlet var propertyBroadcastLabel: UILabel!
    @IBOutlet var propertyReadLabel: UILabel!
    @IBOutlet var propertyWriteWithoutResponseLabel: UILabel!
    @IBOutlet var propertyWriteLabel: UILabel!
    @IBOutlet var propertyNotifyLabel: UILabel!
    @IBOutlet var propertyIndicateLabel: UILabel!
    @IBOutlet var propertyAuthenticatedSignedWritesLabel: UILabel!
    @IBOutlet var propertyExtendedPropertiesLabel: UILabel!
    @IBOutlet var propertyNotifyEncryptionRequiredLabel: UILabel!
    @IBOutlet var propertyIndicateEncryptionRequiredLabel: UILabel!
    
    required init?(coder aDecoder:NSCoder) {
        super.init(coder:aDecoder)
    }
    
    override func viewDidLoad()  {
        guard let discoveredPeripheral = discoveredPeripheral, let discoveredCharacteristic = discoveredCharacteristic else {
            _ = navigationController?.popToRootViewController(animated: false)
            return
        }
        peripheral = Singletons.communicationManager.retrievePeripherals(withIdentifiers: [discoveredPeripheral.identifier]).first
        navigationItem.title = discoveredCharacteristic.name
        updateUI()
        uuidLabel.text = discoveredCharacteristic.UUID.uuidString
        notifyingLabel.text = "NO"
        propertyBroadcastLabel.text = booleanStringValue(discoveredCharacteristic.propertyEnabled(.broadcast))
        propertyReadLabel.text = booleanStringValue(discoveredCharacteristic.propertyEnabled(.read))
        propertyWriteWithoutResponseLabel.text = booleanStringValue(discoveredCharacteristic.propertyEnabled(.writeWithoutResponse))
        propertyWriteLabel.text = booleanStringValue(discoveredCharacteristic.propertyEnabled(.write))
        propertyNotifyLabel.text = booleanStringValue(discoveredCharacteristic.propertyEnabled(.notify))
        propertyIndicateLabel.text = booleanStringValue(discoveredCharacteristic.propertyEnabled(.indicate))
        propertyAuthenticatedSignedWritesLabel.text = booleanStringValue(discoveredCharacteristic.propertyEnabled(.authenticatedSignedWrites))
        propertyExtendedPropertiesLabel.text = booleanStringValue(discoveredCharacteristic.propertyEnabled(.extendedProperties))
        propertyNotifyEncryptionRequiredLabel.text = booleanStringValue(discoveredCharacteristic.propertyEnabled(.notifyEncryptionRequired))
        propertyIndicateEncryptionRequiredLabel.text = booleanStringValue(discoveredCharacteristic.propertyEnabled(.indicateEncryptionRequired))
        navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.plain, target:nil, action:nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(PeripheralServiceCharacteristicViewController.didEnterBackground), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        guard discoveredPeripheral != nil, discoveredCharacteristic != nil else {
            _ = navigationController?.popToRootViewController(animated: false)
            return
        }
        connect()
        updateUI()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }

    override func prepare(for segue:UIStoryboardSegue, sender:Any!) {
        if segue.identifier == MainStoryboard.peripheralServiceCharacteristicValueSegue {
            let viewController = segue.destination as! PeripheralServiceCharacteristicValuesViewController
            viewController.characteristic = characteristic
            viewController.peripheral = peripheral
            viewController.connectionFuture = connectionFuture
        } else if segue.identifier == MainStoryboard.peripheralServiceCharacteristicEditWriteOnlyDiscreteValuesSegue {
            let viewController = segue.destination as! PeripheralServiceCharacteristicEditDiscreteValuesViewController
            viewController.characteristic = characteristic
            viewController.peripheral = peripheral
        } else if segue.identifier == MainStoryboard.peripheralServiceCharacteristicEditWriteOnlyValueSeque {
            let viewController = segue.destination as! PeripheralServiceCharacteristicEditValueViewController
            viewController.characteristic = characteristic
            viewController.peripheral = peripheral
        }
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String?, sender: Any?) -> Bool {
        guard let peripheral = peripheral, let characteristic = characteristic, identifier != nil  else {
            return false
        }
        return characteristic.propertyEnabled(.read)    ||
               characteristic.isNotifying               ||
               characteristic.propertyEnabled(.write)   &&
               peripheral.state == .connected
    }
    
    @IBAction func toggleNotificatons() {
        guard let characteristic = characteristic else {
            return
        }
        if characteristic.isNotifying {
            let future = characteristic.stopNotifying()
            future.onSuccess { [weak self] _ in
                self?.updateUI()
                characteristic.stopNotificationUpdates()
            }
            future.onFailure { [weak self] (error) in
                self.forEach { strongSelf in
                    strongSelf.notifySwitch.isOn = false
                    strongSelf.updateUI()
                    strongSelf.present(UIAlertController.alertOnError("Error stopping notifications", error: error), animated: true, completion: nil)
                }
            }
        } else {
            let future = characteristic.startNotifying()
            future.onSuccess { [weak self] _ in
                self?.updateUI()
            }
            future.onFailure { [weak self] (error) in
                self.forEach { strongSelf in
                    strongSelf.notifySwitch.isOn = false
                    strongSelf.updateUI()
                    strongSelf.present(UIAlertController.alertOnError("Error stopping notification", error: error), animated: true, completion: nil)
                }
            }
        }
    }
    
    func updateUI() {
        guard let characteristic = characteristic, let peripheral = peripheral else {
            return
        }
        if (characteristic.propertyEnabled(.read) || characteristic.propertyEnabled(.write) || characteristic.isNotifying) && peripheral.state == .connected {
            valuesLabel.textColor = UIColor.black
        } else {
            valuesLabel.textColor = UIColor.lightGray
        }
        if peripheral.state == .connected &&
            (characteristic.propertyEnabled(.notify)                     ||
             characteristic.propertyEnabled(.indicate)                   ||
             characteristic.propertyEnabled(.notifyEncryptionRequired)   ||
             characteristic.propertyEnabled(.indicateEncryptionRequired)) {
            notifyLabel.textColor = UIColor.black
            notifySwitch.isEnabled = true
            notifySwitch.isOn = characteristic.isNotifying
        } else {
            notifyLabel.textColor = UIColor.lightGray
            notifySwitch.isEnabled = false
            notifySwitch.isOn = false
        }
        notifyingLabel.text = booleanStringValue(characteristic.isNotifying)
    }
    
    func booleanStringValue(_ value: Bool) -> String {
        return value ? "YES" : "NO"
    }
    
    func didEnterBackground() {
        peripheral?.disconnect()
        _ = navigationController?.popToRootViewController(animated: false)
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
        connectionFuture = peripheral.connect(timeoutRetries: maxTimeouts, disconnectRetries: maxDisconnections, connectionTimeout: connectionTimeout, capacity: 10)

        connectionFuture?.onSuccess { [weak self] (peripheral, connectionEvent) in
            self.forEach { strongSelf in
                switch connectionEvent {
                case .connect:
                    strongSelf.discoverPeripheralService()
                    strongSelf.updateUI()
                case .timeout:
                    strongSelf.reconnect()
                case .disconnect:
                    strongSelf.reconnect()
                case .forceDisconnect:
                    fallthrough
                case .giveUp:
                    strongSelf.progressView.remove()
                    strongSelf.present(UIAlertController.alertWithMessage("Connection to `\(peripheral.name)` failed"), animated:true, completion:nil)
                }
            }
        }

        connectionFuture?.onFailure { [weak self] error in
            self.forEach { strongSelf in
                strongSelf.updateUI()
                strongSelf.connect()
                strongSelf.present(UIAlertController.alertOnError("Connection", error: error) { _ in
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
        guard let peripheral = peripheral,
              let discoveredCharacteristic = discoveredCharacteristic,
              let discoveredService = discoveredCharacteristic.service, peripheral.state == .connected else {
            progressView.remove()
            return
        }
        let serviceDiscoveryFuture = peripheral.discoverServices([discoveredService.UUID]).flatMap { peripheral in
            peripheral.services.map { $0.discoverAllCharacteristics() }.sequence()
        }
        serviceDiscoveryFuture.onSuccess { [weak self] peripherals in
            self.forEach { strongSelf in
                strongSelf.characteristic = peripheral.service(discoveredService.UUID)?.characteristic(discoveredCharacteristic.UUID)
                strongSelf.progressView.remove()
                strongSelf.updateUI()
                if let characteristic = strongSelf.characteristic {
                    Logger.debug("Discovered charcateristic \(characteristic.name), \(characteristic.UUID)")
                } else {
                    Logger.debug("Characteristic discovery failed")
                }
            }
        }
        serviceDiscoveryFuture.onFailure { [weak self] (error) in
            self.forEach { strongSelf in
                strongSelf.present(UIAlertController.alertOnError("Peripheral discovery error", error: error) { _ in
                    strongSelf.progressView.remove()
                }, animated: true, completion: nil)
                Logger.debug("Service discovery failed")
            }
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let characteristic = characteristic, let peripheral = peripheral, peripheral.state == .connected else {
            return
        }
        if (indexPath as NSIndexPath).row == 0 {
            if characteristic.propertyEnabled(.read) || characteristic.isNotifying  {
                performSegue(withIdentifier: MainStoryboard.peripheralServiceCharacteristicValueSegue, sender: indexPath)
            } else if (characteristic.propertyEnabled(.write) || characteristic.propertyEnabled(.writeWithoutResponse)) && !characteristic.propertyEnabled(.read) {
                if characteristic.stringValues.isEmpty {
                    performSegue(withIdentifier: MainStoryboard.peripheralServiceCharacteristicEditWriteOnlyValueSeque, sender: indexPath)
                } else {
                    performSegue(withIdentifier: MainStoryboard.peripheralServiceCharacteristicEditWriteOnlyDiscreteValuesSegue, sender: indexPath)
                }
            }
        }
    }

}
