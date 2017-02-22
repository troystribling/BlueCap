//
//  ViewController.swift
//  Beacon
//
//  Created by Troy Stribling on 4/13/15.
//  Copyright (c) 2015 Troy Stribling. The MIT License (MIT).
//

import UIKit
import CoreBluetooth
import BlueCapKit

enum AppError: Error {
    case invalidState
    case resetting
    case poweredOff
    case unsupported
}

class ViewController: UITableViewController, UITextFieldDelegate {
    
    @IBOutlet var nameTextField: UITextField!
    @IBOutlet var uuidTextField: UITextField!
    @IBOutlet var majorTextField: UITextField!
    @IBOutlet var minorTextField: UITextField!
    @IBOutlet var generateUUIDButton: UIButton!
    @IBOutlet var startAdvertisingSwitch: UISwitch!
    @IBOutlet var startAdvertisingLabel: UILabel!
    
    let estimoteUUID = UUID(uuidString: "B9407F30-F5F8-466E-AFF9-25556B57FE6D")!

    let manager = PeripheralManager(options: [CBPeripheralManagerOptionRestoreIdentifierKey : "us.gnos.BlueCap.ibeacon-simulator.example" as NSString])

    required init?(coder aDecoder: NSCoder) {
        if BeaconStore.getBeaconUUID() == nil {
            BeaconStore.setBeaconUUID(estimoteUUID)
        }
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startAdvertisingLabel.textColor = UIColor.lightGray
        startAdvertisingSwitch.isOn = false
        setUI()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    @IBAction func generateUUID(_ sender: AnyObject) {
        let uuid = UUID()
        uuidTextField.text = uuid.uuidString
        BeaconStore.setBeaconUUID(uuid)
        setUI()
    }

    @IBAction func toggleAdvertise(_ sender: AnyObject) {
        if manager.isAdvertising {
            _ = manager.stopAdvertising()
        } else {
            startAdvertising()
        }
    }

    // UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return self.addBeacon(textField)
    }
    
    func addBeacon(_ textField: UITextField) -> Bool {
        guard let enteredName = self.nameTextField.text,
              let enteredMajor = self.majorTextField.text,
              let enteredMinor = self.minorTextField.text,
              !enteredName.isEmpty && !enteredMinor.isEmpty && !enteredMajor.isEmpty else {
            return false
        }
        guard let minor = Int(enteredMinor),  let major = Int(enteredMajor), minor < 65536 && major < 65536 else {
            self.present(UIAlertController.alertOnErrorWithMessage("major and minor not convertable to a number"), animated: true, completion: nil)
            return false
        }
        guard let enteredUUID = self.uuidTextField.text, !enteredUUID.isEmpty else {
            return false
        }
        guard let uuid = UUID(uuidString: enteredUUID) else {
            present(UIAlertController.alertOnErrorWithMessage("UUID '\(enteredUUID)' is Invalid"), animated: true, completion: nil)
            startAdvertisingSwitch.isOn = false
            return false
        }
        BeaconStore.setBeaconUUID(uuid)
        BeaconStore.setBeaconConfig([UInt16(minor), UInt16(major)])
        BeaconStore.setBeaconName(enteredName)
        textField.resignFirstResponder()
        setUI()
        return true
    }
    
    func startAdvertising() {
        guard let beaconRegion = createBeaconRegion() else {
            return
        }
        
        let startAdvertiseFuture = manager.whenStateChanges().flatMap { [unowned self] state -> Future<Void> in
            switch state {
            case .poweredOn:
                return self.manager.startAdvertising(beaconRegion)
            case .poweredOff:
                throw AppError.poweredOff
            case .unauthorized, .unknown:
                throw AppError.invalidState
            case .unsupported:
                throw AppError.unsupported
            case .resetting:
                throw AppError.resetting
            }
        }

        startAdvertiseFuture.onSuccess { [unowned self] in
            self.present(UIAlertController.alertWithMessage("powered on and started advertising"), animated: true, completion: nil)
        }

        startAdvertiseFuture.onFailure { [unowned self] error in
            switch error {
            case AppError.poweredOff:
                self.present(UIAlertController.alertWithMessage("PeripheralManager powered off") { _ in
                    self.manager.reset()
                }, animated: true)
            case AppError.resetting:
                let message = "PeripheralManager state \"\(self.manager.state)\". The connection with the system bluetooth service was momentarily lost.\n Restart advertising."
                self.present(UIAlertController.alertWithMessage(message) { _ in
                    self.manager.reset()
                }, animated: true)
            case AppError.unsupported:
                self.present(UIAlertController.alertWithMessage("Bluetooth not supported"), animated: true)
            default:
                self.present(UIAlertController.alertOnError(error) { _ in
                    self.manager.reset()
                }, animated: true, completion: nil)
            }
            _ = self.manager.stopAdvertising()
        }
    }

    func createBeaconRegion() -> BeaconRegion? {
        guard let name = BeaconStore.getBeaconName(), let uuid = BeaconStore.getBeaconUUID() else {
            present(UIAlertController.alertOnErrorWithMessage("configuration invalid"), animated: true, completion: nil)
            return nil
        }
        let config = BeaconStore.getBeaconConfig()
        if config.count == 2 {
            return BeaconRegion(proximityUUID: uuid, identifier: name, major: config[1], minor: config[0])
        } else {
            present(UIAlertController.alertOnErrorWithMessage("configuration invalid"), animated: true, completion: nil)
            return nil
        }
    }
    
    func setUI() {
        var uuidSet = false
        if let uuid = BeaconStore.getBeaconUUID() {
            uuidTextField.text = uuid.uuidString
            uuidSet = true
        }
        var nameSet = false
        if let name = BeaconStore.getBeaconName() {
            nameTextField.text = name
            nameSet = true
        }
        var majoMinorSet = false
        let beaconConfig = BeaconStore.getBeaconConfig()
        if beaconConfig.count == 2 {
            minorTextField.text = "\(beaconConfig[0])"
            majorTextField.text = "\(beaconConfig[1])"
            majoMinorSet = true
        }
        if uuidSet && nameSet && majoMinorSet {
            startAdvertisingLabel.textColor = UIColor.black
            startAdvertisingSwitch.isEnabled = true
        } else {
            startAdvertisingLabel.textColor = UIColor.lightGray
            startAdvertisingSwitch.isEnabled = false
        }
    }
}
