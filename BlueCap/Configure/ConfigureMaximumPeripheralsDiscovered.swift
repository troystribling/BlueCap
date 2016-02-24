//
//  ConfigureMaximumPeripheralsDiscovered.swift
//  BlueCap
//
//  Created by Troy Stribling on 2/20/16.
//  Copyright © 2016 Troy Stribling. All rights reserved.
//

import UIKit

class ConfigureMaximumPeripheralsDiscovered: UIViewController {

    @IBOutlet var maximumPeripheralsDiscoveredTextField: UITextField!

    required init?(coder aDecoder:NSCoder) {
        super.init(coder:aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.maximumPeripheralsDiscoveredTextField.text = "\(ConfigStore.getMaximumPeripheralsDiscovered())"
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
    }

    // UITextFieldDelegate
    func textFieldShouldReturn(textField: UITextField!) -> Bool {
        if let maxPeripheralsText = self.maximumPeripheralsDiscoveredTextField.text, maxPeripherals = Int(maxPeripheralsText) where !maxPeripheralsText.isEmpty {
            ConfigStore.setMaximumPeripheralsDiscovered(maxPeripherals)
            self.navigationController?.popToRootViewControllerAnimated(true)
        }
        return true
    }
    
}
