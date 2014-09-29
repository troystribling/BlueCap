//
//  PeripheralManagerBeaconViewController.swift
//  BlueCap
//
//  Created by Troy Stribling on 9/28/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import UIKit

class PeripheralManagerBeaconViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet var nameTextField     : UITextField!
    @IBOutlet var uuidTextField     : UITextField!
    @IBOutlet var majotTextField    : UITextField!
    @IBOutlet var minorTextField    : UITextField!
    
    var beaconName : String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func generateUUID(sender:AnyObject) {
        
    }
    
    // UITextFieldDelegate
    func textFieldShouldReturn(textField: UITextField!) -> Bool {
        self.nameTextField.resignFirstResponder()
        let enteredUUID = self.uuidTextField.text
        let enteredName = self.nameTextField.text
        if enteredName != nil && enteredUUID != nil  {
            if !enteredName!.isEmpty && !enteredUUID!.isEmpty {
                if let uuid = Optional(NSUUID(UUIDString:enteredUUID)) {
                    if let beacon = self.beaconName {
                        // updating
                        if beaconName != enteredName! {
                        }
                    } else {
                        // new region
                    }
                    self.navigationController?.popViewControllerAnimated(true)
                    return true
                } else {
                    self.presentViewController(UIAlertController.alertOnErrorWithMessage("UUID '\(enteredUUID)' is Invalid"), animated:true, completion:nil)
                    return false
                }
            }
        }
        return true
    }

}
