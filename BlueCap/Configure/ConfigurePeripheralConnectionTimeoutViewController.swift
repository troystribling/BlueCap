//
//  ConfigurePeripheralConnectionTimeoutViewController.swift
//  BlueCap
//
//  Created by Troy Stribling on 10/24/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import UIKit

class ConfigurePeripheralConnectionTimeoutViewController: UIViewController {

    @IBOutlet var peripheralConnectionTimeoutTextField : UITextField!
    
    required init(coder aDecoder:NSCoder) {
        super.init(coder:aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.peripheralConnectionTimeoutTextField.text = "\(ConfigStore.getPeripheralConnectionTimeout())"
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    // UITextFieldDelegate
    func textFieldShouldReturn(textField: UITextField!) -> Bool {
        if let timeout = self.peripheralConnectionTimeoutTextField.text {
            if !timeout.isEmpty {
                if let timeoutInt = timeout.toInt() {
                    ConfigStore.setPeripheralConnectionTimeout(timeoutInt)
                    self.navigationController?.popToRootViewControllerAnimated(true)
                }
            }
        }
        return true
    }

}
