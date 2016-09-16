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

    fileprivate static var BCPeripheralStateKVOContext = UInt8()

    struct MainStoryboard {
        static let peripheralServiceCharacteristicValueSegue = "PeripheralServiceCharacteristicValues"
        static let peripheralServiceCharacteristicEditWriteOnlyDiscreteValuesSegue = "PeripheralServiceCharacteristicEditWriteOnlyDiscreteValues"
        static let peripheralServiceCharacteristicEditWriteOnlyValueSeque = "PeripheralServiceCharacteristicEditWriteOnlyValue"
    }
    
    weak var characteristic: Characteristic!
    weak var connectionFuture: FutureStream<(peripheral: Peripheral, connectionEvent: ConnectionEvent)>!

    var peripheralViewController: PeripheralViewController!
    
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
        self.navigationItem.title = self.characteristic.name

        self.setUI()
        
        self.uuidLabel.text = self.characteristic.UUID.UUIDString
        self.notifyingLabel.text = self.booleanStringValue(self.characteristic.isNotifying)
        
        self.propertyBroadcastLabel.text = self.booleanStringValue(self.characteristic.propertyEnabled(.Broadcast))
        self.propertyReadLabel.text = self.booleanStringValue(self.characteristic.propertyEnabled(.Read))
        self.propertyWriteWithoutResponseLabel.text = self.booleanStringValue(self.characteristic.propertyEnabled(.WriteWithoutResponse))
        self.propertyWriteLabel.text = self.booleanStringValue(self.characteristic.propertyEnabled(.Write))
        self.propertyNotifyLabel.text = self.booleanStringValue(self.characteristic.propertyEnabled(.Notify))
        self.propertyIndicateLabel.text = self.booleanStringValue(self.characteristic.propertyEnabled(.Indicate))
        self.propertyAuthenticatedSignedWritesLabel.text = self.booleanStringValue(self.characteristic.propertyEnabled(.AuthenticatedSignedWrites))
        self.propertyExtendedPropertiesLabel.text = self.booleanStringValue(self.characteristic.propertyEnabled(.ExtendedProperties))
        self.propertyNotifyEncryptionRequiredLabel.text = self.booleanStringValue(self.characteristic.propertyEnabled(.NotifyEncryptionRequired))
        self.propertyIndicateEncryptionRequiredLabel.text = self.booleanStringValue(self.characteristic.propertyEnabled(.IndicateEncryptionRequired))
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.plain, target:nil, action:nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.setUI()
        let options = NSKeyValueObservingOptions([.new])
        // TODO: Use Future Callback
        self.characteristic?.service?.peripheral?.addObserver(self, forKeyPath: "state", options: options, context: &PeripheralServiceCharacteristicViewController.BCPeripheralStateKVOContext)
        NotificationCenter.default.addObserver(self, selector: #selector(PeripheralServiceCharacteristicViewController.didEnterBackground), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.characteristic?.service?.peripheral?.removeObserver(self, forKeyPath: "state", context: &PeripheralServiceCharacteristicViewController.BCPeripheralStateKVOContext)
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
        if let _ = identifier {
            return (self.characteristic.propertyEnabled(.Read) || self.characteristic.isNotifying || self.characteristic.propertyEnabled(.Write)) && self.peripheralViewController.peripheralConnected
        } else {
            return false
        }
    }
    
    @IBAction func toggleNotificatons() {
        if self.characteristic.isNotifying {
            let future = self.characteristic.stopNotifying()
            future.onSuccess {_ in
                self.setUI()
                self.characteristic.stopNotificationUpdates()
            }
            future.onFailure {(error) in
                self.notifySwitch.on = false
                self.setUI()
                self.presentViewController(UIAlertController.alertOnError("Stop Notifications Error", error: error), animated: true, completion: nil)
            }
        } else {
            let future = self.characteristic.startNotifying()
            future.onSuccess {_ in
                self.setUI()
            }
            future.onFailure {(error) in
                self.notifySwitch.on = false
                self.setUI()
                self.presentViewController(UIAlertController.alertOnError("Start Notifications Error", error: error), animated: true, completion: nil)
            }
        }
    }
    
    func setUI() {
        if (!self.characteristic.propertyEnabled(.Read) && !self.characteristic.propertyEnabled(.Write) && !self.characteristic.isNotifying) || !self.peripheralViewController.peripheralConnected {
            self.valuesLabel.textColor = UIColor.lightGray
        } else {
            self.valuesLabel.textColor = UIColor.black
        }
        if self.peripheralViewController.peripheralConnected &&
            (characteristic.propertyEnabled(.Notify)                     ||
             characteristic.propertyEnabled(.Indicate)                   ||
             characteristic.propertyEnabled(.NotifyEncryptionRequired)   ||
             characteristic.propertyEnabled(.IndicateEncryptionRequired)) {
            self.notifyLabel.textColor = UIColor.black
            self.notifySwitch.isEnabled = true
            self.notifySwitch.on = self.characteristic.isNotifying
        } else {
            self.notifyLabel.textColor = UIColor.lightGray
            self.notifySwitch.isEnabled = false
            self.notifySwitch.isOn = false
        }
        self.notifyingLabel.text = self.booleanStringValue(self.characteristic.isNotifying)
    }
    
    func booleanStringValue(_ value: Bool) -> String {
        return value ? "YES" : "NO"
    }
    
    func peripheralDisconnected() {
        Logger.debug()
        if self.peripheralViewController.peripheralConnected {
            self.present(UIAlertController.alertWithMessage("Peripheral disconnected") {(action) in
                    self.peripheralViewController.peripheralConnected = false
                    self.setUI()
                }, animated: true, completion: nil)
        }
    }

    func didEnterBackground() {
        self.navigationController?.popToRootViewController(animated: false)
        Logger.debug()
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        guard keyPath != nil else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }
        switch (keyPath!, context) {
        case("state", PeripheralServiceCharacteristicViewController.BCPeripheralStateKVOContext):
            if let change = change, let newValue = change[NSKeyValueChangeKey.newKey], let newRawState = newValue as? Int, let newState = CBPeripheralState(rawValue: newRawState) {
                if newState == .disconnected {
                    DispatchQueue.main.async { self.peripheralDisconnected() }
                }
            }
        default:
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (indexPath as NSIndexPath).row == 0 {
            if self.characteristic.propertyEnabled(.Read) || self.characteristic.isNotifying  {
                self.performSegue(withIdentifier: MainStoryboard.peripheralServiceCharacteristicValueSegue, sender: indexPath)
            } else if (self.characteristic.propertyEnabled(.Write) || self.characteristic.propertyEnabled(.WriteWithoutResponse)) && !self.characteristic.propertyEnabled(.Read) {
                if self.characteristic.stringValues.isEmpty {
                    self.performSegue(withIdentifier: MainStoryboard.peripheralServiceCharacteristicEditWriteOnlyValueSeque, sender: indexPath)
                } else {
                    self.performSegue(withIdentifier: MainStoryboard.peripheralServiceCharacteristicEditWriteOnlyDiscreteValuesSegue, sender: indexPath)
                }
            }
        }
    }

}
