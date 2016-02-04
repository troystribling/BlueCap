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
    var characteristic : BCCharacteristic?
    var isRaw : Bool?
    
    required init?(coder aDecoder:NSCoder) {
        super.init(coder:aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if let isRaw = self.isRaw, updatePeriod : TISensorTag.AccelerometerService.UpdatePeriod = characteristic?.value() {
            if isRaw {
                self.updatePeriodTextField.text = "\(updatePeriod.rawValue)"
            } else {
                self.updatePeriodTextField.text = "\(updatePeriod.period)"
            }
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    // UITextFieldDelegate
    func textFieldShouldReturn(textField:UITextField) -> Bool {
        if let enteredPeriod = self.updatePeriodTextField.text, isRaw = self.isRaw, value = UInt16(enteredPeriod) where !enteredPeriod.isEmpty {
            let rawValue : UInt16
            if  isRaw {
                rawValue = value
            } else {
                rawValue = value / 10
            }
            if let rawPeriod = UInt8(uintValue:rawValue), period = TISensorTag.AccelerometerService.UpdatePeriod(rawValue:rawPeriod) {
                let writeFuture = self.characteristic?.write(period, timeout:10.0)
                writeFuture?.onSuccess {_ in
                    textField.resignFirstResponder()
                    self.navigationController?.popViewControllerAnimated(true)
                }
                writeFuture?.onFailure {error in
                    self.presentViewController(UIAlertController.alertOnError(error), animated:true) {action in
                        textField.resignFirstResponder()
                        self.navigationController?.popViewControllerAnimated(true)
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
