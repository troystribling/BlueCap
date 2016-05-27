//
//  ConfigureScanServiceViewController.swift
//  BlueCap
//
//  Created by Troy Stribling on 9/27/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import UIKit
import CoreBluetooth

class ConfigureScanServiceViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet var nameTextField : UITextField!
    @IBOutlet var uuidTextField : UITextField!
    
    var serviceName             : String?
    
    required init?(coder aDecoder:NSCoder) {
        super.init(coder:aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if let serviceName = self.serviceName {
            self.nameTextField.text = serviceName
            if let uuid = ConfigStore.getScannedServiceUUID(serviceName) {
                self.uuidTextField.text = uuid.UUIDString
            }
        }
    }

    // UITextFieldDelegate
    func textFieldShouldReturn(textField:UITextField) -> Bool {
        textField.resignFirstResponder()
        if let enteredUUID = self.uuidTextField.text, enteredName = self.nameTextField.text where !enteredName.isEmpty && !enteredUUID.isEmpty {
            if let nsuuid = NSUUID(UUIDString:enteredUUID) {
                let uuid = CBUUID(NSUUID:nsuuid)
                if let serviceName = self.serviceName {
                    // updating
                    ConfigStore.addScannedService(enteredName, uuid:uuid)
                    if serviceName != enteredName {
                        ConfigStore.removeScannedService(self.serviceName!)
                    }
                } else {
                    // new region
                    ConfigStore.addScannedService(enteredName, uuid:uuid)
                }
                self.navigationController?.popViewControllerAnimated(true)
                return true
            } else {
                self.presentViewController(UIAlertController.alertOnErrorWithMessage("UUID '\(enteredUUID)' is Invalid"), animated:true, completion:nil)
                return false
            }
        }
        return true
    }

}
