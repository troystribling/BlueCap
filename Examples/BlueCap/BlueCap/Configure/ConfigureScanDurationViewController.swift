//
//  ConfigureScanDurationViewController.swift
//  BlueCap
//
//  Created by Troy Stribling on 9/9/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import UIKit
import BlueCapKit

class ConfigureScanDurauinViewController : UIViewController, UITextFieldDelegate {
    
    @IBOutlet var timeoutDurationField    : UITextField!
    
    required init?(coder aDecoder:NSCoder) {
        super.init(coder:aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.timeoutDurationField.text = "\(ConfigStore.getScanDuration())"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        timeoutDurationField.becomeFirstResponder()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    // UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let durationText = self.timeoutDurationField.text, let duration = UInt(durationText), !durationText.isEmpty {
            ConfigStore.setScanDuration(duration)
            _ = self.navigationController?.popToRootViewController(animated: true)
        }
        return true
    }
    
}
