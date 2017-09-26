//
//  ConfigureCharacteristicReadWriteTimeoutViewController.swift
//  BlueCap
//
//  Created by Troy Stribling on 10/24/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import UIKit

class ConfigureCharacteristicReadWriteTimeoutViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet var readWriteTimeoutTextField : UITextField!
    
    required init?(coder aDecoder:NSCoder) {
        super.init(coder:aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.readWriteTimeoutTextField.text = "\(ConfigStore.getCharacteristicReadWriteTimeout())"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        readWriteTimeoutTextField.becomeFirstResponder()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    // UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let readWriteTimeoutText = self.readWriteTimeoutTextField.text, let readWriteTimeout = UInt(readWriteTimeoutText) , !readWriteTimeoutText.isEmpty  {
            ConfigStore.setCharacteristicReadWriteTimeout(readWriteTimeout)
            _ = self.navigationController?.popToRootViewController(animated: true)
        }
        return true
    }

}
