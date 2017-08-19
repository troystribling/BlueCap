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
    var peripheralDiscoveryFuture: FutureStream<[Void]>?


    let cancelToken = CancelToken()
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
        guard let characteristic = characteristic,
              peripheral != nil
        else {
            _ = navigationController?.popToRootViewController(animated: false)
            return
        }
        navigationItem.title = characteristic.name
        navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.plain, target:nil, action:nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard let peripheral = peripheral,
              let peripheralDiscoveryFuture = peripheralDiscoveryFuture,
              peripheral.state == .connected,
              characteristic != nil
        else {
            _ = navigationController?.popToRootViewController(animated: false)
            return
        }
        NotificationCenter.default.addObserver(self, selector: #selector(PeripheralServiceCharacteristicViewController.didEnterBackground), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        setUI()
        peripheralDiscoveryFuture.onSuccess(cancelToken: cancelToken)  { [weak self] _ in
            self?.updateUI()
        }
        peripheralDiscoveryFuture.onFailure { [weak self] error -> Void in
            guard let strongSelf = self else {
                return
            }
            strongSelf.progressView.remove().onSuccess { _ in
                strongSelf.presentAlertIngoringForcedDisconnect(title: "Connection Error", error: error)
                strongSelf.updateWhenActive()
            }
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self)
        _ = peripheralDiscoveryFuture?.cancel(cancelToken)
    }

    override func prepare(for segue:UIStoryboardSegue, sender:Any!) {
        if segue.identifier == MainStoryboard.peripheralServiceCharacteristicValueSegue {
            let viewController = segue.destination as! PeripheralServiceCharacteristicValuesViewController
            viewController.characteristic = characteristic
            viewController.peripheral = peripheral
            viewController.peripheralDiscoveryFuture = peripheralDiscoveryFuture
        } else if segue.identifier == MainStoryboard.peripheralServiceCharacteristicEditWriteOnlyDiscreteValuesSegue {
            let viewController = segue.destination as! PeripheralServiceCharacteristicEditDiscreteValuesViewController
            viewController.characteristic = characteristic
            viewController.peripheral = peripheral
            viewController.peripheralDiscoveryFuture = peripheralDiscoveryFuture
        } else if segue.identifier == MainStoryboard.peripheralServiceCharacteristicEditWriteOnlyValueSeque {
            let viewController = segue.destination as! PeripheralServiceCharacteristicEditValueViewController
            viewController.characteristic = characteristic
            viewController.peripheral = peripheral
            viewController.peripheralDiscoveryFuture = peripheralDiscoveryFuture
            if let characteristic = characteristic,
               let stringValues = characteristic.stringValue
            {
                let selectedIndex = sender as! IndexPath
                let names = Array(stringValues.keys)
                viewController.valueName = names[selectedIndex.row]
            }
        }
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String?, sender: Any?) -> Bool {
        guard let characteristic = characteristic,
              identifier != nil
        else {
            return false
        }
        return characteristic.propertyEnabled(.read)    ||
               characteristic.isNotifying               ||
               characteristic.propertyEnabled(.write)
    }
    
    @IBAction func toggleNotificatons() {
        progressView.show()
        
        guard let peripheralDiscoveryFuture = peripheralDiscoveryFuture else {
            return
        }

        let updateFuture = peripheralDiscoveryFuture.flatMap { [weak self] _ -> Future<Void> in
            guard let strongSelf = self, let characteristic = strongSelf.characteristic else {
                throw AppError.unlikelyFailure
            }
            return strongSelf.notifySwitch.isOn ? characteristic.startNotifying() : characteristic.stopNotifying()
        }

        updateFuture.onSuccess { [weak self] _ in
            _ = self?.progressView.remove()
            self?.updateUI()
            self?.updateWhenActive()
        }
        updateFuture.onFailure{ [weak self] error -> Void in
            self?.progressView.remove().onSuccess { _ in
                self?.present(UIAlertController.alert(title: "Characteristic notification error", error: error), animated: true, completion: nil)
            }
            self?.updateUI()
        }
    }

    func setUI() {
        guard let characteristic = characteristic else {
            return
        }
        uuidLabel.text = characteristic.uuid.uuidString
        notifyingLabel.text = booleanStringValue(characteristic.isNotifying)
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
        if (characteristic.propertyEnabled(.notify)                      ||
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
    
    @objc func didEnterBackground() {
        peripheral?.disconnect()
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
