//
//  ConfigurePeripheralMaximumDisconnections.swift
//  BlueCap
//
//  Created by Troy Stribling on 3/6/16.
//  Copyright © 2016 Troy Stribling. All rights reserved.
//

import UIKit

class ConfigurePeripheralMaximumDisconnections: UIViewController {

    @IBOutlet var maximumDisconnectionsTextField: UITextField!

    required init?(coder aDecoder:NSCoder) {
        super.init(coder:aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.maximumDisconnectionsTextField.text = "\(ConfigStore.getMaximumDisconnections())"
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
    }

    // UITextFieldDelegate
    func textFieldShouldReturn(textField: UITextField!) -> Bool {
        if let maximumDisconnections = self.maximumDisconnectionsTextField.text, maximumDisconnectionsInt = UInt(maximumDisconnections) where !maximumDisconnections.isEmpty {
            ConfigStore.setMaximumDisconnections(maximumDisconnectionsInt)
            self.navigationController?.popToRootViewControllerAnimated(true)
            return true
        } else {
            return false
        }
    }
    
}
