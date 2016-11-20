//
//  PeripheralServiceCharacteristicEditValueViewController.swift
//  BlueCap
//
//  Created by Troy Stribling on 7/20/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import UIKit
import BlueCapKit
import CoreBluetooth

class PeripheralServiceCharacteristicEditValueViewController : UIViewController, UITextFieldDelegate {

    @IBOutlet var valueTextField: UITextField!

    var characteristicUUID: CBUUID?
    var serviceUUID: CBUUID?
    var peripheralIdentifier: UUID?

    var characteristicConnector: CharacteristicConnector?
    var characteristic: Characteristic?

    var valueName: String?
    
    var progressView = ProgressView()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = valueName
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        guard let peripheralIdentifier = peripheralIdentifier, let characteristicUUID = characteristicUUID, let serviceUUID = serviceUUID else {
            _ = self.navigationController?.popViewController(animated: true)
            return
        }
        characteristicConnector = CharacteristicConnector(characteristicUUID: characteristicUUID, serviceUUID: serviceUUID, peripheralIdentifier: peripheralIdentifier)
        super.viewDidAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(PeripheralServiceCharacteristicEditValueViewController.didEnterBackground), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
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

    func writeCharacteristic() {
        guard let characteristicConnector = characteristicConnector else {
            present(UIAlertController.alert(message: "Connection error") { _ in
                _ = self.navigationController?.popToRootViewController(animated: false)
            }, animated: true, completion: nil)
            return
        }
        progressView.show()
        let connectionFuture = characteristicConnector.connect()
        let writeFuture = connectionFuture.flatMap { [weak self] (_, characteristic) -> Future<Characteristic> in
            if let newValue = self?.valueTextField.text {
                if let valueName = self?.valueName {
                    if var values = self?.characteristic?.stringValue {
                        values[valueName] = newValue
                        return characteristic.write(string: values, timeout: Double(ConfigStore.getCharacteristicReadWriteTimeout()))
                    } else {
                        return characteristic.write(data: newValue.dataFromHexString(), timeout: Double(ConfigStore.getCharacteristicReadWriteTimeout()))
                    }
                } else {
                    return characteristic.write(data: newValue.dataFromHexString(), timeout:Double(ConfigStore.getCharacteristicReadWriteTimeout()))
                }
            } else {
                throw CharacteristicConnectorError.unknown
            }
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
        let readFuture = connectionFuture.flatMap { (_, characteristic) -> Future<Characteristic> in
            return characteristic.read(timeout: Double(ConfigStore.getCharacteristicReadWriteTimeout()))
        }.flatMap { [weak self] (characteristic) -> Future<Void> in
            self?.characteristic = characteristic
            guard let strongSelf = self, let characteristicConnector = strongSelf.characteristicConnector else {
                return Future<Void>(value: ())
            }
            if let valueName = self?.valueName {
                self?.valueTextField.text = characteristic.stringValue?[valueName]
            }
            return characteristicConnector.disconnect()
        }
        readFuture.onSuccess { [weak self] _ in
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

    // UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        writeCharacteristic()
        return true
    }

}
