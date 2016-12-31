//
//  PeripheralManagerBeaconViewController.swift
//  BlueCap
//
//  Created by Troy Stribling on 9/28/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import UIKit
import BlueCapKit

class PeripheralManagerBeaconViewController: UITableViewController, UITextFieldDelegate {

    @IBOutlet var advertiseSwitch: UISwitch!
    @IBOutlet var advertiseLabel: UILabel!
    @IBOutlet var nameTextField: UITextField!
    @IBOutlet var uuidTextField: UITextField!
    @IBOutlet var majorTextField: UITextField!
    @IBOutlet var minorTextField: UITextField!
    @IBOutlet var generaUUIDBuuton: UIButton!

    required init?(coder aDecoder:NSCoder) {
        super.init(coder:aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.nameTextField.text = PeripheralStore.getBeaconName()
        self.uuidTextField.text = PeripheralStore.getBeaconUUID()?.uuidString
        let beaconMinorMajor = PeripheralStore.getBeaconMinorMajor()
        if beaconMinorMajor.count == 2 {
            self.minorTextField.text = "\(beaconMinorMajor[0])"
            self.majorTextField.text = "\(beaconMinorMajor[1])"
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Singletons.peripheralManager.whenStateChanges().onSuccess { [weak self] state in
            self.forEach { strongSelf in
                switch state {
                case .poweredOn:
                    break
                case .poweredOff, .unauthorized:
                    strongSelf.alert(message: "PeripheralManager state \"\(state)\"")
                case .resetting:
                    strongSelf.alert(message:
                        "PeripheralManager state \"\(state)\". The connection with the system bluetooth service was momentarily lost.\n Restart advertising.")
                case .unknown:
                    break
                case .unsupported:
                    strongSelf.alert(message: "PeripheralManager state \"\(state)\". Bluetooth not supported.")
                }
            }
        }
        self.setUIState()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }

    @IBAction func generateUUID(_ sender: AnyObject) {
        self.uuidTextField.text = UUID().uuidString
    }
        
    // UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return self.addBeacon()
    }
    
    func addBeacon() -> Bool {
        if let enteredUUID = self.uuidTextField.text, !enteredUUID.isEmpty {
            if let uuid = UUID(uuidString:enteredUUID) {
                PeripheralStore.setBeaconUUID(uuid)
            } else {
                self.present(UIAlertController.alertOnErrorWithMessage("UUID '\(enteredUUID)' is Invalid"), animated:true, completion:nil)
                return false
            }
        }
        if let enteredName = self.nameTextField.text, !enteredName.isEmpty {
            PeripheralStore.setBeaconName(enteredName)
        }
        if let enteredMinor = self.minorTextField.text, let enteredMajor = self.majorTextField.text, !enteredMinor.isEmpty, !enteredMajor.isEmpty {
            if let minor = UInt16(enteredMinor), let major = UInt16(enteredMajor), minor <= 65535, major <= 65535 {
                PeripheralStore.setBeaconMinorMajor([minor, major])
            } else {
                self.present(UIAlertController.alertOnErrorWithMessage("major or minor not convertable to a number"), animated:true, completion:nil)
                return false
            }
        }
        return true
    }

    @IBAction func toggleAdvertise(_ sender:AnyObject) {
        if Singletons.peripheralManager.isAdvertising {
            Singletons.peripheralManager.stopAdvertising()
            self.setUIState()
            return
        }
        func afterAdvertisingStarted() {
            self.setUIState()
        }
        func afterAdvertisingStartFailed(_ error: Swift.Error) {
            self.setUIState()
            self.present(UIAlertController.alert(title: "Peripheral Advertise Error", error: error), animated: true, completion: nil)
        }
        let beaconMinorMajor = PeripheralStore.getBeaconMinorMajor()
        if let uuid = PeripheralStore.getBeaconUUID(), let name = PeripheralStore.getBeaconName(), beaconMinorMajor.count == 2 {
            let beaconRegion = BeaconRegion(proximityUUID: uuid, identifier: name, major: beaconMinorMajor[1], minor: beaconMinorMajor[0])
            let future = Singletons.peripheralManager.startAdvertising(beaconRegion)
            future.onSuccess(completion: afterAdvertisingStarted)
            future.onFailure(completion: afterAdvertisingStartFailed)
        } else {
            self.present(UIAlertController.alert(message: "iBeacon config is invalid"), animated: true, completion: nil)
        }
    }

    func setUIState() {
        if Singletons.peripheralManager.isAdvertising {
            navigationItem.setHidesBackButton(true, animated:true)
            advertiseSwitch.isOn = true
            nameTextField.isEnabled = false
            uuidTextField.isEnabled = false
            majorTextField.isEnabled = false
            minorTextField.isEnabled = false
            generaUUIDBuuton.isEnabled = false
            advertiseLabel.textColor = UIColor.black
        } else {
            navigationItem.setHidesBackButton(false, animated:true)
            nameTextField.isEnabled = true
            uuidTextField.isEnabled = true
            majorTextField.isEnabled = true
            minorTextField.isEnabled = true
            generaUUIDBuuton.isEnabled = false
            if canAdvertise() {
                advertiseSwitch.isEnabled = true
                advertiseLabel.textColor = UIColor.black
            } else {
                advertiseSwitch.isEnabled = false
                advertiseLabel.textColor = UIColor.lightGray
            }
        }
    }

    func canAdvertise() -> Bool {
        return PeripheralStore.getBeaconUUID() != nil && PeripheralStore.getBeaconName() != nil && PeripheralStore.getBeaconMinorMajor().count == 2
    }

    func alert(message: String) {
        present(UIAlertController.alert(message: message), animated:true) { [weak self] _ in
            self.forEach { strongSelf in
                Singletons.peripheralManager.reset()
            }
        }
    }
}
