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
    var peripheralDiscoveryFuture: FutureStream<[Void]>?

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
        guard  let peripheralDiscoveryFuture = peripheralDiscoveryFuture,
               let peripheral = peripheral,
               let characteristic = characteristic,
               peripheral.state == .connected
        else {
            _ = navigationController?.popViewController(animated: true)
            return
        }

        peripheralDiscoveryFuture.onFailure(cancelToken: cancelToken) { [weak self] (error) -> Void in
            guard let strongSelf = self else {
                return
            }
            strongSelf.progressView.remove().onSuccess { _ in
                strongSelf.presentAlertIngoringForcedDisconnect(title: "Connection Error", error: error)
            }
        }
        
        guard characteristic.canRead else {
            return
        }
        
        progressView.show()
        let readFuture = characteristic.read(timeout: Double(ConfigStore.getCharacteristicReadWriteTimeout()))
        readFuture.onSuccess { [weak self] _ in
            _ = self?.progressView.remove()
            guard let valueName = self?.valueName else {
                return
            }
            self?.valueTextField.text = characteristic.stringValue?[valueName]
        }
        readFuture.onFailure { [weak self] error in
            self?.progressView.remove().onSuccess { _ in
                self?.present(UIAlertController.alert(title: "Charcteristic read error", error: error) { _ in
                    _ = self?.navigationController?.popViewController(animated: true)
                    return
                }, animated:true, completion:nil)
            }
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self)
        _ = peripheralDiscoveryFuture?.cancel(cancelToken)
    }

    @objc func didEnterBackground() {
        peripheral?.disconnect()
        _ = navigationController?.popToRootViewController(animated: false)
    }

    func writeCharacteristic() {
        guard  let characteristic = characteristic,
            let peripheral = peripheral,
            let newValue = valueTextField.text,
            peripheralDiscoveryFuture != nil,
            peripheral.state == .connected else {
                _ = self.navigationController?.popViewController(animated: true)
                return
        }
        progressView.show()

        let writeFuture: Future<Void>
        if let valueName = self.valueName {
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
            self?.progressView.remove().onSuccess { _ in
                _ = self?.navigationController?.popViewController(animated: true)
            }
        }
        writeFuture.onFailure { [weak self] (error) -> Void in
            self?.progressView.remove().onSuccess { _ in
                self?.present(UIAlertController.alert(title: "Charcteristic write error", error: error) { _ in
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
