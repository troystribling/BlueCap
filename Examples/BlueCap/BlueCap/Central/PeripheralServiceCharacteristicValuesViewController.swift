//
//  PeripheralServiceCharacteristicValuesViewController.swift
//  BlueCap
//
//  Created by Troy Stribling on 7/5/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import UIKit
import BlueCapKit
import CoreBluetooth

class PeripheralServiceCharacteristicValuesViewController : UITableViewController {

    var characteristicName = "Unknown"
    var characteristicUUID: CBUUID?
    var serviceUUID: CBUUID?
    var peripheralIdentifier: UUID?
    var isNotifying = false

    var characteristic: Characteristic?
    var peripheral: Peripheral?

    let progressView = ProgressView()

    @IBOutlet var refreshButton:UIButton!
    
    struct MainStoryboard {
        static let peripheralServiceCharactertisticValueCell = "PeripheralServiceCharacteristicValueCell"
        static let peripheralServiceCharacteristicEditDiscreteValuesSegue = "PeripheralServiceCharacteristicEditDiscreteValues"
        static let peripheralServiceCharacteristicEditValueSeque = "PeripheralServiceCharacteristicEditValue"
    }
    
    required init?(coder aDecoder:NSCoder) {
        super.init(coder:aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let peripheralIdentifier = peripheralIdentifier, characteristicUUID != nil, serviceUUID != nil else {
            _ = self.navigationController?.popViewController(animated: true)
            return
        }
        self.navigationItem.title = characteristicName
        if isNotifying {
            refreshButton.isEnabled = false
        } else {
            refreshButton.isEnabled = true
        }
        navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.plain, target:nil, action:nil)
    }
    
    override func viewDidAppear(_ animated:Bool)  {
        NotificationCenter.default.addObserver(self, selector: #selector(PeripheralServiceCharacteristicValuesViewController.didEnterBackground), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        guard peripheralIdentifier != nil, characteristicUUID != nil else {
            _ = self.navigationController?.popViewController(animated: true)
            return
        }
        updateValues()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        guard let characteristic = characteristic else {
            return
        }
        if characteristic.isNotifying {
            characteristic.stopNotificationUpdates()
        }
        NotificationCenter.default.removeObserver(self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any!) {
        if segue.identifier == MainStoryboard.peripheralServiceCharacteristicEditDiscreteValuesSegue {
            let viewController = segue.destination as! PeripheralServiceCharacteristicEditDiscreteValuesViewController
            viewController.characteristic = self.characteristic
            viewController.peripheral = peripheral
        } else if segue.identifier == MainStoryboard.peripheralServiceCharacteristicEditValueSeque {
            let viewController = segue.destination as! PeripheralServiceCharacteristicEditValueViewController
            viewController.characteristic = self.characteristic
            viewController.peripheral = peripheral
            if let stringValues = self.characteristic?.stringValue {
                let selectedIndex = sender as! IndexPath
                let names = Array(stringValues.keys)
                viewController.valueName = names[selectedIndex.row]
            }
        }
    }
    
    @IBAction func updateValues() {
        guard let characteristic = characteristic else {
            progressView.remove()
            _ = self.navigationController?.popToRootViewController(animated: false)
            return
        }
        if characteristic.isNotifying {
            let future = characteristic.receiveNotificationUpdates(capacity: 10)
            future.onSuccess { [weak self] _ in
                self?.updateWhenActive()
            }
            future.onFailure{ [weak self] error in
                self?.present(UIAlertController.alertOnError("Characteristic notification error", error: error), animated: true, completion: nil)
            }
        } else if characteristic.propertyEnabled(.read) {
            self.progressView.show()
            let future = characteristic.read(timeout: Double(ConfigStore.getCharacteristicReadWriteTimeout()))
            future.onSuccess { _ in
                self.updateWhenActive()
                self.progressView.remove()
            }
            future.onFailure { error in
                self.progressView.remove()
                self.present(UIAlertController.alertOnError("Charcteristic read error", error: error) { [weak self] _ in
                    _ = self?.navigationController?.popViewController(animated: true)
                    return
                }, animated:true, completion:nil)
            }
        } else {
            progressView.remove()
        }
    }

    func didEnterBackground() {
        _ = self.navigationController?.popToRootViewController(animated: false)
        peripheral?.disconnect()
        Logger.debug()
    }

    func toggleNotificatons() {
        guard let characteristic = characteristic else {
            return
        }
        if characteristic.isNotifying {
            let future = characteristic.stopNotifying()
            future.onSuccess { [weak self] _ in
                characteristic.stopNotificationUpdates()
            }
            future.onFailure { [weak self] (error) in
                self.forEach { strongSelf in
                    strongSelf.present(UIAlertController.alertOnError("Error stopping notifications", error: error), animated: true, completion: nil)
                }
            }
        } else {
            let future = characteristic.startNotifying()
            future.onSuccess { [weak self] _ in
            }
            future.onFailure { [weak self] (error) in
                self.forEach { strongSelf in
                    strongSelf.present(UIAlertController.alertOnError("Error stopping notification", error: error), animated: true, completion: nil)
                }
            }
        }
    }

    // UITableViewDataSource
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_: UITableView, numberOfRowsInSection section :Int) -> Int {
        if let values = self.characteristic?.stringValue {
            return values.count
        } else {
            return 0;
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: MainStoryboard.peripheralServiceCharactertisticValueCell, for: indexPath) as! CharacteristicValueCell
        if let characteristic = self.characteristic {
            if let stringValues = characteristic.stringValue {
                let names = Array(stringValues.keys)
                let values = Array(stringValues.values)
                cell.valueNameLabel.text = names[indexPath.row]
                cell.valueLable.text = values[indexPath.row]
            }
            if characteristic.propertyEnabled(.write) || characteristic.propertyEnabled(.writeWithoutResponse) {
                cell.accessoryType = UITableViewCellAccessoryType.disclosureIndicator
            } else {
                cell.accessoryType = UITableViewCellAccessoryType.none
            }
        }
        return cell
    }

    // UITableViewDelegate
    override func tableView(_ tableView:UITableView, didSelectRowAt indexPath: IndexPath) {
        if let characteristic = self.characteristic {
            if characteristic.propertyEnabled(.write) || characteristic.propertyEnabled(.writeWithoutResponse) {
                if characteristic.stringValues.isEmpty {
                    self.performSegue(withIdentifier: MainStoryboard.peripheralServiceCharacteristicEditValueSeque, sender: indexPath)
                } else {
                    self.performSegue(withIdentifier: MainStoryboard.peripheralServiceCharacteristicEditDiscreteValuesSegue, sender: indexPath)
                }
            }
        }
    }
}
