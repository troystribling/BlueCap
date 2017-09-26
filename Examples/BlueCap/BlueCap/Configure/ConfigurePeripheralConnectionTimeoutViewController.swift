//
//  ConfigurePeripheralConnectionTimeoutViewController.swift
//  BlueCap
//
//  Created by Troy Stribling on 10/24/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import UIKit

class ConfigurePeripheralConnectionTimeoutViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet var peripheralConnectionTimeoutTextField: UITextField!
    
    required init?(coder aDecoder:NSCoder) {
        super.init(coder:aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.peripheralConnectionTimeoutTextField.text = "\(ConfigStore.getPeripheralConnectionTimeout())"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        peripheralConnectionTimeoutTextField.becomeFirstResponder()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    // UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let timeoutText = self.peripheralConnectionTimeoutTextField.text, let timeout = UInt(timeoutText)  , !timeoutText.isEmpty  {
            ConfigStore.setPeripheralConnectionTimeout(timeout)
            _ = self.navigationController?.popToRootViewController(animated: true)
        }
        return true
    }

}
