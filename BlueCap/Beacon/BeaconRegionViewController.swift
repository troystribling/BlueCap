//
//  BeaconRegionViewController.swift
//  BlueCap
//
//  Created by Troy Stribling on 9/13/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import UIKit

class BeaconRegionViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet var nameTextField : UITextField!
    @IBOutlet var uuidTextField : UITextField!
    
    required init(coder aDecoder:NSCoder) {
        super.init(coder:aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    // UITextFieldDelegate
    func textFieldShouldReturn(textField: UITextField!) -> Bool {
        self.nameTextField.resignFirstResponder()
        if let enteredName = self.nameTextField.text {
            if !enteredName.isEmpty {
            }
        }
        return true
    }

}
