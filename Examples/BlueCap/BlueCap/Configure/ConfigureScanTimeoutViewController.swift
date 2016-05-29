//
//  ConfigureScanTimeoutViewController.swift
//  BlueCap
//
//  Created by Troy Stribling on 9/9/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import UIKit
import BlueCapKit

class ConfigureScanTimeoutViewController : UIViewController, UITextFieldDelegate {
    
    @IBOutlet var timeoutTextField    : UITextField!
    
    required init?(coder aDecoder:NSCoder) {
        super.init(coder:aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.timeoutTextField.text = "\(ConfigStore.getScanTimeout())"
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    // UITextFieldDelegate
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if let timeoutText = self.timeoutTextField.text, timeout = UInt(timeoutText) where !timeoutText.isEmpty {
            ConfigStore.setScanTimeout(timeout)
            self.navigationController?.popToRootViewControllerAnimated(true)
        }
        return true
    }
    
}
