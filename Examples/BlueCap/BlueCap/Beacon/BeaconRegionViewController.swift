//
//  BeaconRegionViewController.swift
//  BlueCap
//
//  Created by Troy Stribling on 9/13/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import UIKit
import BlueCapKit

class BeaconRegionViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet var nameTextField : UITextField!
    @IBOutlet var uuidTextField : UITextField!
    var regionName              : String?
    
    required init?(coder aDecoder:NSCoder) {
        super.init(coder:aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if let regionName = self.regionName {
            self.navigationItem.title = regionName
            self.nameTextField.text = regionName
            let beacons = BeaconStore.getBeacons()
            if let uuid = beacons[regionName] {
                self.uuidTextField.text = uuid.uuidString
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        NotificationCenter.default.addObserver(self, selector:#selector(BeaconRegionViewController.didEnterBackground), name: NSNotification.Name.UIApplicationDidEnterBackground, object:nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func didEnterBackground() {
        Logger.debug()
        _ = self.navigationController?.popToRootViewController(animated: false)
    }
    
    // UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.nameTextField.resignFirstResponder()
        if let enteredUUID = self.uuidTextField.text, let enteredName = self.nameTextField.text , !enteredName.isEmpty && !enteredUUID.isEmpty {
            if let uuid = UUID(uuidString:enteredUUID) {
                BeaconStore.addBeacon(enteredName, uuid:uuid)
                if let regionName = self.regionName {
                    if regionName != enteredName {
                        BeaconStore.removeBeacon(regionName)
                    }
                }
                _ = navigationController?.popViewController(animated: true)
                return true
            } else {
                present(UIAlertController.alertOnErrorWithMessage("UUID '\(enteredUUID)' is Invalid"), animated:true)
                return false
            }
        } else {
            return false
        }
    }

}
