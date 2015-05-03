//
//  ConfigurePeripheralReconnectionsViewController.swift
//  BlueCap
//
//  Created by Troy Stribling on 10/22/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import UIKit

class ConfigurePeripheralReconnectionsViewController: UIViewController {

    @IBOutlet var maximumReconnectionsTextField    : UITextField!
    
    required init(coder aDecoder:NSCoder) {
        super.init(coder:aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.maximumReconnectionsTextField.text = "\(ConfigStore.getMaximumReconnections())"
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    // UITextFieldDelegate
    func textFieldShouldReturn(textField: UITextField!) -> Bool {
        if let maximumReconnections = self.maximumReconnectionsTextField.text, maximumReconnectionsInt = maximumReconnections.toInt()
            where !maximumReconnections.isEmpty && maximumReconnectionsInt > 0 {
            ConfigStore.setMaximumReconnections(UInt(maximumReconnectionsInt))
            self.navigationController?.popToRootViewControllerAnimated(true)
            return true
        } else {
            return false
        }
    }

}
