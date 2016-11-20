//
//  PeripheralServiceCharacteristicEditDiscreteValuesViewController.swift
//  BlueCap
//
//  Created by Troy Stribling on 7/20/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import UIKit
import BlueCapKit
import CoreBluetooth

class PeripheralServiceCharacteristicEditDiscreteValuesViewController : UITableViewController {

    var characteristicName = "Unknown"
    var characteristicUUID: CBUUID?
    var serviceUUID: CBUUID?
    var peripheralIdentifier: UUID?

    var characteristicConnector: CharacteristicConnector?
    var characteristic: Characteristic?

    var progressView = ProgressView()
    
    struct MainStoryboard {
        static let peripheralServiceCharacteristicDiscreteValueCell = "PeripheraServiceCharacteristicEditDiscreteValueCell"
    }

    required init?(coder aDecoder:NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = characteristicName
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard let peripheralIdentifier = peripheralIdentifier, let characteristicUUID = characteristicUUID, let serviceUUID = serviceUUID else {
            _ = self.navigationController?.popViewController(animated: true)
            return
        }
        characteristicConnector = CharacteristicConnector(characteristicUUID: characteristicUUID, serviceUUID: serviceUUID, peripheralIdentifier: peripheralIdentifier)
        NotificationCenter.default.addObserver(self, selector: #selector(PeripheralServiceCharacteristicEditDiscreteValuesViewController.didEnterBackground), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        readCharacteristic()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }

    func didEnterBackground() {
        characteristicConnector?.disconnect().onSuccess { [weak self] in
            _ = self?.navigationController?.popToRootViewController(animated: false)
        }
    }

    func writeCharacteristic(_ stringValue: [String : String]) {
        guard let characteristicConnector = characteristicConnector else {
            present(UIAlertController.alert(message: "Connection error") { _ in
                _ = self.navigationController?.popToRootViewController(animated: false)
            }, animated: true, completion: nil)
            return
        }
        progressView.show()
        let connectionFuture = characteristicConnector.connect()
        let writeFuture = connectionFuture.flatMap { (_, characteristic) -> Future<Characteristic> in
            characteristic.write(string: stringValue, timeout: (Double(ConfigStore.getCharacteristicReadWriteTimeout())))
        }.flatMap { [weak self] (characteristic) -> Future<Void> in
            guard let strongSelf = self, let characteristicConnector = strongSelf.characteristicConnector else {
                return Future<Void>(value: ())
            }
            return characteristicConnector.disconnect()
        }
        writeFuture.onSuccess { [weak self] _ in
            self?.progressView.remove()
            _ = self?.navigationController?.popViewController(animated: true)
        }
        writeFuture.onFailure { [weak self] error in
            self?.progressView.remove()
            self?.present(UIAlertController.alert(title: "Charcteristic write error", error: error) { _ in
                _ = self?.navigationController?.popViewController(animated: true)
                return
            }, animated:true, completion:nil)
        }
    }

    func readCharacteristic() {
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
        }.flatMap { [weak self] (characteristic) -> Future<Void> in
            guard let strongSelf = self, let characteristicConnector = strongSelf.characteristicConnector else {
                return Future<Void>(value: ())
            }
            return characteristicConnector.disconnect()
        }
        readFuture.onSuccess { [weak self] _ in
            self?.updateWhenActive()
            self?.progressView.remove()
        }
        readFuture.onFailure { [weak self] error in
            self?.progressView.remove()
            self?.present(UIAlertController.alert(title: "Charcteristic read error", error: error) { _ in
                _ = self?.navigationController?.popViewController(animated: true)
                return
            }, animated:true, completion:nil)
        }
    }

    // UITableViewDataSource
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let characteristic = characteristic else {
            return 0
        }
        return characteristic.stringValues.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: MainStoryboard.peripheralServiceCharacteristicDiscreteValueCell, for: indexPath) as UITableViewCell
        guard let characteristic = characteristic else {
            cell.textLabel?.text = "Unknown"
            return cell
        }

        let stringValue = characteristic.stringValues[indexPath.row]
        cell.textLabel?.text = stringValue

        if let value = characteristic.stringValue?.values.first {
            if value == stringValue {
                cell.accessoryType = UITableViewCellAccessoryType.checkmark
            } else {
                cell.accessoryType = UITableViewCellAccessoryType.none
            }
        }

        return cell
    }
    
    // UITableViewDelegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let characteristic = characteristic, let valueName = characteristic.stringValue?.keys.first else {
            return
        }
        writeCharacteristic([valueName : characteristic.stringValues[indexPath.row]])
    }
    
}
