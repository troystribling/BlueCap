//
//  BeaconRegionViewController.swift
//  BlueCap
//
//  Created by Troy Stribling on 9/13/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import UIKit
import BlueCapKit

class BeaconRegionViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet var nameTextField : UITextField!
    @IBOutlet var uuidTextField : UITextField!
    var regionName              : String?
    
    required init(coder aDecoder:NSCoder) {
        super.init(coder:aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if let regionName = self.regionName {
            self.nameTextField.text = regionName
            let beacons = BeaconStore.getBeacons()
            if let uuid = beacons[regionName] {
                self.uuidTextField.text = uuid.UUIDString
            }
        }
    }

    // UITextFieldDelegate
    func textFieldShouldReturn(textField: UITextField!) -> Bool {
        self.nameTextField.resignFirstResponder()
        let enteredUUID = self.uuidTextField.text
        let enteredName = self.nameTextField.text
        if enteredName != nil && enteredUUID != nil  {
            if !enteredName!.isEmpty && !enteredUUID!.isEmpty {
                if let uuid = Optional(NSUUID(UUIDString:enteredUUID)) {
                    if let regionName = self.regionName {
                        // updating
                        BeaconStore.addBeacon(enteredName!, uuid:uuid)
                        if regionName != enteredName! {
                            BeaconStore.removeBeacon(regionName)
                        }
                    } else {
                        // new region
                        BeaconStore.addBeacon(enteredName!, uuid:uuid)
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
