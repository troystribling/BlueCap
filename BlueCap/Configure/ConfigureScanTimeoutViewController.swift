//
//  ConfigureScanTimeoutViewController.swift
//  BlueCap
//
//  Created by Troy Stribling on 9/9/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import UIKit
import BlueCapKit

class ConfigureScanTimeoutViewController : UIViewController, UITextFieldDelegate {
    
    @IBOutlet var timeoutTextField    : UITextField!
    
    required init(coder aDecoder:NSCoder) {
        super.init(coder:aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    // UITextFieldDelegate
    func textFieldShouldReturn(textField: UITextField!) -> Bool {
        if let timeout = self.timeoutTextField.text {
            if !timeout.isEmpty {
                if let timeoutInt = timeout.toInt() {
                    ConfigStore.setScanTimeout(timeoutInt)
                    self.navigationController!.popToRootViewControllerAnimated(true)
                }
            }
        }
        return true
    }
    
}
