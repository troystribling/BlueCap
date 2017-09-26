//
//  ConfigurePeripheralMaximumTimeoutsViewController.swift
//  BlueCap
//
//  Created by Troy Stribling on 10/22/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import UIKit

class ConfigurePeripheralMaximumTimeoutsViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet var maximumTimeoutsTextField: UITextField!
    
    required init?(coder aDecoder:NSCoder) {
        super.init(coder:aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.maximumTimeoutsTextField.text = "\(ConfigStore.getPeripheralMaximumTimeouts())"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        maximumTimeoutsTextField.becomeFirstResponder()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    // UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let maximumTimeouts = self.maximumTimeoutsTextField.text, let maximumTimeoutsInt = UInt(maximumTimeouts) , !maximumTimeouts.isEmpty {
            ConfigStore.setPeripheralMaximumTimeouts(maximumTimeoutsInt)
            _ = self.navigationController?.popToRootViewController(animated: true)
            return true
        } else {
            return false
        }
    }

}
