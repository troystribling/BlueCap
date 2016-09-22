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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    // UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let timeoutText = self.timeoutTextField.text, let timeout = UInt(timeoutText) , !timeoutText.isEmpty {
            ConfigStore.setScanTimeout(timeout)
            _ = self.navigationController?.popToRootViewController(animated: true)
        }
        return true
    }
    
}
