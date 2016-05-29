//
//  ConfigureCharacteristicReadWriteTimeoutViewController.swift
//  BlueCap
//
//  Created by Troy Stribling on 10/24/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import UIKit

class ConfigureCharacteristicReadWriteTimeoutViewController: UIViewController {

    @IBOutlet var readWriteTimeoutTextField : UITextField!
    
    required init?(coder aDecoder:NSCoder) {
        super.init(coder:aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.readWriteTimeoutTextField.text = "\(ConfigStore.getCharacteristicReadWriteTimeout())"
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    // UITextFieldDelegate
    func textFieldShouldReturn(textField: UITextField!) -> Bool {
        if let readWriteTimeoutText = self.readWriteTimeoutTextField.text, readWriteTimeout = UInt(readWriteTimeoutText) where !readWriteTimeoutText.isEmpty  {
            ConfigStore.setCharacteristicReadWriteTimeout(readWriteTimeout)
            self.navigationController?.popToRootViewControllerAnimated(true)
        }
        return true
    }

}