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

    var characteristicConnector: CharacteristicConnector?
    var characteristic: Characteristic?

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
        guard let peripheralIdentifier = peripheralIdentifier, let characteristicUUID = characteristicUUID, let serviceUUID = serviceUUID else {
            _ = self.navigationController?.popViewController(animated: true)
            return
        }
        characteristicConnector = CharacteristicConnector(characteristicUUID: characteristicUUID, serviceUUID: serviceUUID, peripheralIdentifier: peripheralIdentifier)
        updateValues()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        guard let characteristicConnector = characteristicConnector else {
            return
        }
        _ = characteristicConnector.disconnect()
        NotificationCenter.default.removeObserver(self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any!) {
        if segue.identifier == MainStoryboard.peripheralServiceCharacteristicEditDiscreteValuesSegue {
            let viewController = segue.destination as! PeripheralServiceCharacteristicEditDiscreteValuesViewController
            viewController.characteristicUUID = characteristicUUID
            viewController.peripheralIdentifier = peripheralIdentifier
            viewController.serviceUUID = serviceUUID
        } else if segue.identifier == MainStoryboard.peripheralServiceCharacteristicEditValueSeque {
            let viewController = segue.destination as! PeripheralServiceCharacteristicEditValueViewController
            viewController.characteristicUUID = characteristic?.uuid
            viewController.peripheralIdentifier = peripheralIdentifier
            viewController.serviceUUID = characteristic?.service?.uuid
            if let stringValues = self.characteristic?.stringValue {
                let selectedIndex = sender as! IndexPath
                let names = Array(stringValues.keys)
                viewController.valueName = names[selectedIndex.row]
            }
        }
    }
    
    @IBAction func updateValues() {
        guard let characteristicConnector = characteristicConnector else {
            present(UIAlertController.alert(message: "Connection error") { _ in
                _ = self.navigationController?.popToRootViewController(animated: false)
            }, animated: true, completion: nil)
            return
        }
        progressView.show()
        let connectionFuture = characteristicConnector.connect()
        let readFuture = connectionFuture.flatMap { [weak self] (_, characteristic) -> Future<Characteristic> in
            self?.characteristic = characteristic
            return characteristic.read(timeout: Double(ConfigStore.getCharacteristicReadWriteTimeout()))
        }
        readFuture.onSuccess { [weak self] _ in
            self?.updateWhenActive()
            self?.progressView.remove()
        }
        readFuture.onFailure { [weak self] error in
            self?.progressView.remove()
            self?.present(UIAlertController.alert(title: "Charcteristic read error", error: error) { [weak self] _ in
                _ = self?.navigationController?.popViewController(animated: true)
                return
            }, animated:true, completion:nil)
        }
        if isNotifying {
            let updateFuture = readFuture.flatMap { (characteristic) -> Future<Characteristic> in
                characteristic.startNotifying()
            }.flatMap { [weak self] (characteristic) -> FutureStream<(characteristic: Characteristic, data: Data?)> in
                self?.progressView.remove()
                return characteristic.receiveNotificationUpdates(capacity: 10)
            }
            updateFuture.onSuccess { [weak self] _ in
                self?.updateWhenActive()
            }
            updateFuture.onFailure{ [weak self] error in
                self?.present(UIAlertController.alert(title: "Characteristic notification error", error: error), animated: true, completion: nil)
            }
        } else {
            readFuture.onSuccess { [weak self] _ in
                _ = self?.characteristicConnector?.disconnect()
            }
        }
    }

    func didEnterBackground() {
        characteristicConnector?.disconnect().onComplete { [weak self] _ in
            _ = self?.navigationController?.popToRootViewController(animated: false)
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
