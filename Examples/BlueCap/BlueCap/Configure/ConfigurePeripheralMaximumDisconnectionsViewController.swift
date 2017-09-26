//
//  ConfigurePeripheralMaximumDisconnections.swift
//  BlueCap
//
//  Created by Troy Stribling on 3/6/16.
//  Copyright © 2016 Troy Stribling. All rights reserved.
//

import UIKit

class ConfigurePeripheralMaximumDisconnections: UIViewController, UITextFieldDelegate {

    @IBOutlet var maximumDisconnectionsTextField: UITextField!

    required init?(coder aDecoder:NSCoder) {
        super.init(coder:aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.maximumDisconnectionsTextField.text = "\(ConfigStore.getPeripheralMaximumDisconnections())"
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        maximumDisconnectionsTextField.becomeFirstResponder()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }

    // UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let maximumDisconnections = self.maximumDisconnectionsTextField.text, let maximumDisconnectionsInt = UInt(maximumDisconnections) , !maximumDisconnections.isEmpty {
            ConfigStore.setPeripheralMaximumDisconnections(maximumDisconnectionsInt)
            _ = self.navigationController?.popToRootViewController(animated: true)
            return true
        } else {
            return false
        }
    }
    
}
