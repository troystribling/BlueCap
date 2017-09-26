//
//  SetUpdatePeriodViewController.swift
//  Central
//
//  Created by Troy Stribling on 5/2/15.
//  Copyright (c) 2015 Troy Stribling. The MIT License (MIT).
//

import UIKit
import BlueCapKit

class SetUpdatePeriodViewController: UITableViewController, UITextFieldDelegate {

    @IBOutlet var updatePeriodTextField : UITextField!

    var characteristic : Characteristic?
    var isRaw : Bool?
    
    required init?(coder aDecoder:NSCoder) {
        super.init(coder:aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let isRaw = isRaw, let updatePeriod : TiSensorTag.AccelerometerService.UpdatePeriod = characteristic?.value() {
            if isRaw {
                updatePeriodTextField.text = "\(updatePeriod.rawValue)"
            } else {
                updatePeriodTextField.text = "\(updatePeriod.period)"
            }
        }
        updatePeriodTextField.becomeFirstResponder()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    // UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let enteredPeriod = self.updatePeriodTextField.text, let isRaw = isRaw, let value = UInt16(enteredPeriod), !enteredPeriod.isEmpty {
            let rawValue : UInt16
            if  isRaw {
                rawValue = value
            } else {
                rawValue = value / 10
            }
            if let rawPeriod = UInt8(uintValue:rawValue), let period = TiSensorTag.AccelerometerService.UpdatePeriod(rawValue:rawPeriod) {
                let writeFuture = self.characteristic?.write(period, timeout: 5.0)
                writeFuture?.onSuccess {_ in
                    textField.resignFirstResponder()
                    _ = self.navigationController?.popViewController(animated: true)
                }
                writeFuture?.onFailure { [weak self] error in
                    self?.present(UIAlertController.alertOnError(error), animated:true) { () -> Void in
                        textField.resignFirstResponder()
                        _ = self?.navigationController?.popViewController(animated: true)
                    }
                }
                return true
            } else {
                return false
            }
        } else {
            return false
        }
    }
}
