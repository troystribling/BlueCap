//
//  ConfigureMaximumPeripheralsConnected
//  BlueCap
//
//  Created by Troy Stribling on 2/20/16.
//  Copyright © 2016 Troy Stribling. All rights reserved.
//

import Foundation

import UIKit

class ConfigureMaximumPeripheralsConnected: UIViewController, UITextFieldDelegate {

    @IBOutlet var maximumPeripheralsConnectedTextField: UITextField!

    required init?(coder aDecoder:NSCoder) {
        super.init(coder:aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.maximumPeripheralsConnectedTextField.text = "\(ConfigStore.getMaximumPeripheralsConnected())"
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        maximumPeripheralsConnectedTextField.becomeFirstResponder()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }

    // UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let maxConnectedText = self.maximumPeripheralsConnectedTextField.text, let maxConnected = Int(maxConnectedText) , !maxConnectedText.isEmpty {
            ConfigStore.setMaximumPeripheralsConnected(maxConnected)
            _ = self.navigationController?.popToRootViewController(animated: true)
        }
        return true
    }
    
}
