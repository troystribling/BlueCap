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
    var characteristic: BCCharacteristic?
    var isRaw : Bool?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if let isRaw = self.isRaw, data = self.characteristic?.stringValue, period = data["period"], rawPeriod = data["periodRaw"] {
            if isRaw {
                self.updatePeriodTextField.text = rawPeriod
            } else {
                self.updatePeriodTextField.text = period
            }
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    // UITextFieldDelegate
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if let enteredPeriod = self.updatePeriodTextField.text, isRaw = self.isRaw, value = UInt16(enteredPeriod) where !enteredPeriod.isEmpty {
            let rawValue : String
            if  isRaw {
                rawValue = enteredPeriod
            } else {
                rawValue = "\(value / 10)"
            }
            let writeFuture = self.characteristic?.writeString(["periodRaw": rawValue], timeout:10.0)
            writeFuture?.onSuccess {_ in
                textField.resignFirstResponder()
                self.navigationController?.popViewControllerAnimated(true)
            }
            writeFuture?.onFailure {error in
                self.presentViewController(UIAlertController.alertOnError(error), animated: true) {action in
                    textField.resignFirstResponder()
                    self.navigationController?.popViewControllerAnimated(true)
                }
            }
            return true
        } else {
            return false
        }
    }
    
}
