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
    
    var isNotifying = false
    var characteristic: Characteristic?
    var peripheral: Peripheral?

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
        guard peripheral != nil, characteristic != nil else {
            _ = navigationController?.popToRootViewController(animated: false)
            return
        }
        navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.plain, target:nil, action:nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(PeripheralServiceCharacteristicViewController.didEnterBackground), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        guard peripheral != nil else {
            _ = navigationController?.popToRootViewController(animated: false)
            return
        }
        setUI()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }

    override func prepare(for segue:UIStoryboardSegue, sender:Any!) {
        if segue.identifier == MainStoryboard.peripheralServiceCharacteristicValueSegue {
            let viewController = segue.destination as! PeripheralServiceCharacteristicValuesViewController
            viewController.characteristicUUID = characteristic?.uuid
            viewController.peripheralIdentifier = peripheral?.identifier
            viewController.serviceUUID = characteristic?.service?.uuid
            viewController.isNotifying = isNotifying
        } else if segue.identifier == MainStoryboard.peripheralServiceCharacteristicEditWriteOnlyDiscreteValuesSegue {
            let viewController = segue.destination as! PeripheralServiceCharacteristicEditDiscreteValuesViewController
            viewController.characteristicUUID = characteristic?.uuid
            viewController.peripheralIdentifier = peripheral?.identifier
            viewController.serviceUUID = characteristic?.service?.uuid
        } else if segue.identifier == MainStoryboard.peripheralServiceCharacteristicEditWriteOnlyValueSeque {
            let viewController = segue.destination as! PeripheralServiceCharacteristicEditValueViewController
            viewController.characteristicUUID = characteristic?.uuid
            viewController.peripheralIdentifier = peripheral?.identifier
            viewController.serviceUUID = characteristic?.service?.uuid
            if let stringValues = self.characteristic?.stringValue {
                let selectedIndex = sender as! IndexPath
                let names = Array(stringValues.keys)
                viewController.valueName = names[selectedIndex.row]
            }
        }
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String?, sender: Any?) -> Bool {
        guard let characteristic = characteristic, identifier != nil  else {
            return false
        }
        return characteristic.propertyEnabled(.read)    ||
               characteristic.isNotifying               ||
               characteristic.propertyEnabled(.write)
    }
    
    @IBAction func toggleNotificatons() {
        isNotifying = notifySwitch.isOn
        updateUI()
    }

    func setUI() {
        guard let characteristic = characteristic else {
            return
        }
        uuidLabel.text = characteristic.uuid.uuidString
        notifyingLabel.text = booleanStringValue(isNotifying)
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
        updateUI()
    }

    func updateUI() {
        guard let characteristic = characteristic else {
            return
        }
        if (characteristic.propertyEnabled(.read) || characteristic.propertyEnabled(.write) || characteristic.isNotifying) {
            valuesLabel.textColor = UIColor.black
        } else {
            valuesLabel.textColor = UIColor.lightGray
        }
        if (characteristic.propertyEnabled(.notify)                     ||
             characteristic.propertyEnabled(.indicate)                   ||
             characteristic.propertyEnabled(.notifyEncryptionRequired)   ||
             characteristic.propertyEnabled(.indicateEncryptionRequired)) {
            notifyLabel.textColor = UIColor.black
            notifySwitch.isEnabled = true
            notifySwitch.isOn = isNotifying
        } else {
            notifyLabel.textColor = UIColor.lightGray
            notifySwitch.isEnabled = false
            notifySwitch.isOn = false
        }
        notifyingLabel.text = booleanStringValue(isNotifying)
    }
    
    func booleanStringValue(_ value: Bool) -> String {
        return value ? "YES" : "NO"
    }
    
    func didEnterBackground() {
        _ = navigationController?.popToRootViewController(animated: false)
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let characteristic = characteristic else {
            return
        }
        if indexPath.row == 0 && indexPath.section == 0 {
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
