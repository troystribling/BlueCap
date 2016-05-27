//
//  ConfigurePeripheralMaximumTimeoutsViewController.swift
//  BlueCap
//
//  Created by Troy Stribling on 10/22/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import UIKit

class ConfigurePeripheralMaximumTimeoutsViewController: UIViewController {

    @IBOutlet var maximumTimeoutsTextField: UITextField!
    
    required init?(coder aDecoder:NSCoder) {
        super.init(coder:aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.maximumTimeoutsTextField.text = "\(ConfigStore.getMaximumTimeouts())"
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    // UITextFieldDelegate
    func textFieldShouldReturn(textField: UITextField!) -> Bool {
        if let maximumTimeouts = self.maximumTimeoutsTextField.text, maximumTimeoutsInt = UInt(maximumTimeouts) where !maximumTimeouts.isEmpty {
            ConfigStore.setMaximumTimeouts(maximumTimeoutsInt)
            self.navigationController?.popToRootViewControllerAnimated(true)
            return true
        } else {
            return false
        }
    }

}
