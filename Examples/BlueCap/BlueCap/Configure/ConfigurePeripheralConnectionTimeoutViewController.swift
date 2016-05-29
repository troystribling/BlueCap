//
//  ConfigurePeripheralConnectionTimeoutViewController.swift
//  BlueCap
//
//  Created by Troy Stribling on 10/24/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import UIKit

class ConfigurePeripheralConnectionTimeoutViewController: UIViewController {

    @IBOutlet var peripheralConnectionTimeoutTextField: UITextField!
    
    required init?(coder aDecoder:NSCoder) {
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
        if let timeoutText = self.peripheralConnectionTimeoutTextField.text, timeout = UInt(timeoutText)  where !timeoutText.isEmpty  {
            ConfigStore.setPeripheralConnectionTimeout(timeout)
            self.navigationController?.popToRootViewControllerAnimated(true)
        }
        return true
    }

}
