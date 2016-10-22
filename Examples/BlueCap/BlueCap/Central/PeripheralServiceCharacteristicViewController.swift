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
    
    weak var characteristic: Characteristic?
    weak var peripheral: Peripheral?
    
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
        guard peripheral != nil, let characteristic = characteristic else {
            _ = self.navigationController?.popToRootViewController(animated: false)
            return
        }
        navigationItem.title = characteristic.name
        updateUI()
        uuidLabel.text = characteristic.UUID.uuidString
        notifyingLabel.text = self.booleanStringValue(characteristic.isNotifying)
        propertyBroadcastLabel.text = booleanStringValue(characteristic.propertyEnabled(.broadcast))
        propertyReadLabel.text = booleanStringValue(characteristic.propertyEnabled(.read))
        propertyWriteWithoutResponseLabel.text = booleanStringValue(characteristic.propertyEnabled(.writeWithoutResponse))
        propertyWriteLabel.text = booleanStringValue(characteristic.propertyEnabled(.write))
        propertyNotifyLabel.text = booleanStringValue(characteristic.propertyEnabled(.notify))
        propertyIndicateLabel.text = booleanStringValue(characteristic.propertyEnabled(.indicate))
        propertyAuthenticatedSignedWritesLabel.text = booleanStringValue(characteristic.propertyEnabled(.authenticatedSignedWrites))
        propertyExtendedPropertiesLabel.text = booleanStringValue(characteristic.propertyEnabled(.extendedProperties))
        propertyNotifyEncryptionRequiredLabel.text = booleanStringValue(characteristic.propertyEnabled(.notifyEncryptionRequired))
        propertyIndicateEncryptionRequiredLabel.text = booleanStringValue(characteristic.propertyEnabled(.indicateEncryptionRequired))
        navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.plain, target:nil, action:nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(PeripheralServiceCharacteristicViewController.didEnterBackground), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        guard peripheral != nil, characteristic != nil else {
            _ = self.navigationController?.popToRootViewController(animated: false)
            return
        }
        updateUI()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }

    override func prepare(for segue:UIStoryboardSegue, sender:Any!) {
        if segue.identifier == MainStoryboard.peripheralServiceCharacteristicValueSegue {
            let viewController = segue.destination as! PeripheralServiceCharacteristicValuesViewController
            viewController.characteristic = self.characteristic
        } else if segue.identifier == MainStoryboard.peripheralServiceCharacteristicEditWriteOnlyDiscreteValuesSegue {
            let viewController = segue.destination as! PeripheralServiceCharacteristicEditDiscreteValuesViewController
            viewController.characteristic = self.characteristic
        } else if segue.identifier == MainStoryboard.peripheralServiceCharacteristicEditWriteOnlyValueSeque {
            let viewController = segue.destination as! PeripheralServiceCharacteristicEditValueViewController
            viewController.characteristic = self.characteristic
            viewController.valueName = nil
        }
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String?, sender: Any?) -> Bool {
        guard let characteristic = characteristic, identifier != nil  else {
            return false
        }
        return (characteristic.propertyEnabled(.read) ||
                   characteristic.isNotifying || characteristic.propertyEnabled(.write))
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
            self.valuesLabel.textColor = UIColor.black
        } else {
            self.valuesLabel.textColor = UIColor.lightGray
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
            self.notifyLabel.textColor = UIColor.lightGray
            self.notifySwitch.isEnabled = false
            self.notifySwitch.isOn = false
        }
        notifyingLabel.text = self.booleanStringValue(characteristic.isNotifying)
    }
    
    func booleanStringValue(_ value: Bool) -> String {
        return value ? "YES" : "NO"
    }
    
    func didEnterBackground() {
        peripheral?.stopPollingRSSI()
        peripheral?.disconnect()
        _ = self.navigationController?.popToRootViewController(animated: false)
    }

    func connect() {
        guard let peripheral = peripheral else {
            return
        }
        Logger.debug("Connect peripheral: '\(peripheral.name)'', \(peripheral.identifier.uuidString)")
        let maxTimeouts = ConfigStore.getPeripheralMaximumTimeoutsEnabled() ? ConfigStore.getPeripheralMaximumTimeouts() : UInt.max
        let maxDisconnections = ConfigStore.getPeripheralMaximumDisconnectionsEnabled() ? ConfigStore.getPeripheralMaximumDisconnections() : UInt.max
        let connectionTimeout = ConfigStore.getPeripheralConnectionTimeoutEnabled() ? Double(ConfigStore.getPeripheralConnectionTimeout()) : Double.infinity
        let connectionFuture = peripheral.connect(timeoutRetries: maxTimeouts, disconnectRetries: maxDisconnections, connectionTimeout: connectionTimeout, capacity: 10)

        connectionFuture.onSuccess { [weak self] (peripheral, connectionEvent) in
            self.forEach { strongSelf in
                switch connectionEvent {
                case .connect:
                    break
                case .timeout:
                    peripheral.reconnect()
                case .disconnect:
                    peripheral.reconnect()
                case .forceDisconnect:
                    break;
                case .giveUp:
                    strongSelf.present(UIAlertController.alertWithMessage("Connection to `\(peripheral.name)` failed"), animated:true, completion:nil)
                }
            }
        }

        connectionFuture.onFailure { [weak self] error in
            self?.present(UIAlertController.alertOnError("Error connecting", error: error), animated: true, completion: nil)
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let characteristic = characteristic, let peripheral = peripheral, peripheral.state == .connected else {
            return
        }
        if (indexPath as NSIndexPath).row == 0 {
            if characteristic.propertyEnabled(.read) || characteristic.isNotifying  {
                self.performSegue(withIdentifier: MainStoryboard.peripheralServiceCharacteristicValueSegue, sender: indexPath)
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
