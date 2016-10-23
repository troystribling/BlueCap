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


    var valueName: String?
    
    var progressView = ProgressView()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        guard peripheral != nil, let characteristic = characteristic else {
            _ = self.navigationController?.popToRootViewController(animated: false)
            return
        }
        if let valueName = self.valueName {
            self.navigationItem.title = valueName
            if let value = characteristic.stringValue?[valueName] {
                valueTextField.text = value
            }
        }
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(PeripheralServiceCharacteristicEditValueViewController.didEnterBackground), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }

    func didEnterBackground() {
        peripheral?.stopPollingRSSI()
        peripheral?.disconnect()
        _ = self.navigationController?.popToRootViewController(animated: false)
    }

    // UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard let characteristic = characteristic else {
            return true
        }
        if let newValue = self.valueTextField.text {
            func afterWriteSuceses(characteristic: Characteristic) -> Void {
                self.progressView.remove()
                _ = self.navigationController?.popViewController(animated: true)
                return
            }
            func afterWriteFailed(error: Swift.Error) -> Void {
                self.progressView.remove()
                self.present(UIAlertController.alertOnError("Characteristic Write Error", error:error) {(action) in
                    _ = self.navigationController?.popViewController(animated: true)
                        return
                    } , animated:true, completion:nil)
            }
            self.progressView.show()
            if let valueName = valueName {
                if var values = characteristic.stringValue {
                    values[valueName] = newValue
                    let write = characteristic.write(string: values, timeout: Double(ConfigStore.getCharacteristicReadWriteTimeout()))
                    write.onSuccess(completion: afterWriteSuceses)
                    write.onFailure(completion: afterWriteFailed)
                } else {
                    let write = characteristic.write(data: newValue.dataFromHexString(), timeout: Double(ConfigStore.getCharacteristicReadWriteTimeout()))
                    write.onSuccess(completion: afterWriteSuceses)
                    write.onFailure(completion: afterWriteFailed)
                }
            } else {
                Logger.debug("VALUE: \(newValue.dataFromHexString())")
                let write = characteristic.write(data: newValue.dataFromHexString(), timeout:Double(ConfigStore.getCharacteristicReadWriteTimeout()))
                write.onSuccess(completion: afterWriteSuceses)
                write.onFailure(completion: afterWriteFailed)
            }
        }
        return true
    }

}
