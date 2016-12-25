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

    weak var characteristic: Characteristic?
    weak var peripheral: Peripheral?
    weak var connectionFuture: FutureStream<Peripheral>?

    let cancelToken = CancelToken()
    let progressView = ProgressView()

    var valueName: String?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = valueName
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(PeripheralServiceCharacteristicEditValueViewController.didEnterBackground), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        guard  let connectionFuture = connectionFuture, let peripheral = peripheral, characteristic != nil else {
            _ = navigationController?.popViewController(animated: true)
            return
        }
        readCharacteristic()
        if peripheral.state == .connected {
            connectionFuture.onSuccess(cancelToken: cancelToken)  { _ in
            }
            connectionFuture.onFailure { [weak self] error in
                self?.presentAlertIngoringForcedDisconnect(title: "Connection Error", error: error)
            }
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self)
        _ = connectionFuture?.cancel(cancelToken)
    }

    func didEnterBackground() {
        peripheral?.disconnect()
        _ = navigationController?.popToRootViewController(animated: false)
    }

    func writeCharacteristic() {
        guard let characteristic = characteristic, let newValue = valueTextField.text else {
            present(UIAlertController.alert(message: "Connection error") { _ in
                _ = self.navigationController?.popToRootViewController(animated: false)
            }, animated: true, completion: nil)
            return
        }
        progressView.show()
        let writeFuture: Future<Characteristic>
        if let valueName = valueName {
            if var values = characteristic.stringValue {
                values[valueName] = newValue
                writeFuture = characteristic.write(string: values, timeout: Double(ConfigStore.getCharacteristicReadWriteTimeout()))
            } else {
                writeFuture = characteristic.write(data: newValue.dataFromHexString(), timeout: Double(ConfigStore.getCharacteristicReadWriteTimeout()))
            }
        } else {
            writeFuture = characteristic.write(data: newValue.dataFromHexString(), timeout:Double(ConfigStore.getCharacteristicReadWriteTimeout()))
        }
        writeFuture.onSuccess { [weak self] _ in
            self?.progressView.remove().onSuccess {
                _ = self?.navigationController?.popViewController(animated: true)
            }
        }
        writeFuture.onFailure { [weak self] error in
            self?.progressView.remove().onSuccess {
                self?.present(UIAlertController.alert(title: "Charcteristic write error", error: error) { _ in
                    _ = self?.navigationController?.popViewController(animated: true)
                    return
                }, animated:true, completion:nil)
            }
        }
    }

    func readCharacteristic() {
        guard let characteristic = characteristic else {
            present(UIAlertController.alert(message: "Connection error") { _ in
                _ = self.navigationController?.popToRootViewController(animated: false)
            }, animated: true, completion: nil)
            return
        }
        guard characteristic.propertyEnabled(.read) else {
            return
        }
        progressView.show()
        let readFuture = characteristic.read(timeout: Double(ConfigStore.getCharacteristicReadWriteTimeout()))
        readFuture.onSuccess { [weak self] characteristic in
            _ = self?.progressView.remove()
            if let valueName = self?.valueName {
                self?.valueTextField.text = characteristic.stringValue?[valueName]
            }
        }
        readFuture.onFailure { [weak self] error in
            self?.progressView.remove().onSuccess {
                self?.present(UIAlertController.alert(title: "Charcteristic read error", error: error) { _ in
                    _ = self?.navigationController?.popViewController(animated: true)
                    return
                }, animated:true, completion:nil)
            }
        }
    }

    // UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        writeCharacteristic()
        return true
    }

}
