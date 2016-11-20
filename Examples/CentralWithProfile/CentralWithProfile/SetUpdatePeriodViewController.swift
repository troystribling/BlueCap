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
    var characteristic: Characteristic?
    var isRaw : Bool?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let isRaw = self.isRaw, let data = self.characteristic?.stringValue, let period = data["period"], let rawPeriod = data["periodRaw"] {
            if isRaw {
                self.updatePeriodTextField.text = rawPeriod
            } else {
                self.updatePeriodTextField.text = period
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    // UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let enteredPeriod = self.updatePeriodTextField.text, let isRaw = self.isRaw, let value = UInt16(enteredPeriod), !enteredPeriod.isEmpty {
            let rawValue : String
            if  isRaw {
                rawValue = enteredPeriod
            } else {
                rawValue = "\(value / 10)"
            }
            let writeFuture = self.characteristic?.write(string: ["periodRaw": rawValue], timeout: 10.0)
            writeFuture?.onSuccess { [unowned self] _ in
                textField.resignFirstResponder()
                _ = self.navigationController?.popViewController(animated: true)
            }
            writeFuture?.onFailure { [unowned self] error in
                self.present(UIAlertController.alertOnError(error), animated: true) {action in
                    textField.resignFirstResponder()
                    _ = self.navigationController?.popViewController(animated: true)
                }
            }
            return true
        } else {
            return false
        }
    }
}
