//
//  PeripheralManagerViewController.swift
//  BlueCapUI
//
//  Created by Troy Stribling on 6/5/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import UIKit
import BlueCapKit
import CoreBluetooth

class PeripheralManagerViewController : UITableViewController, UITextFieldDelegate {
    
    @IBOutlet var nameTextField: UITextField!
    @IBOutlet var advertiseSwitch: UISwitch!
    @IBOutlet var advertiseLabel: UILabel!
    @IBOutlet var advertisedServicesLabel: UILabel!
    @IBOutlet var advertisedServicesCountLabel: UILabel!
    @IBOutlet var servicesLabel: UILabel!
    @IBOutlet var servicesCountLabel: UILabel!

    struct MainStoryboard {
        static let peripheralManagerServicesSegue = "PeripheralManagerServices"
        static let peripheralManagerAdvertisedServicesSegue = "PeripheralManagerAdvertisedServices"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated:Bool) {
        super.viewWillAppear(animated)
        nameTextField.text = PeripheralStore.getPeripheralName()
        Singletons.peripheralManager.whenStateChanges().onSuccess { [weak self] state in
            self.forEach { strongSelf in
                switch state {
                case .poweredOn:
                    strongSelf.setPeripheralManagerServices()
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
        self.navigationItem.title = ""
        NotificationCenter.default.removeObserver(self)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func prepare(for segue:UIStoryboardSegue, sender:Any!) {
        if segue.identifier == MainStoryboard.peripheralManagerServicesSegue {
            let viewController = segue.destination as! PeripheralManagerServicesViewController
            viewController.peripheralManagerViewController = self
        } else if segue.identifier == MainStoryboard.peripheralManagerAdvertisedServicesSegue {
            let viewController = segue.destination as! PeripheralManagerAdvertisedServicesViewController
            viewController.peripheralManagerViewController = self
        }
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String?, sender: Any?) -> Bool {
        if let identifier = identifier {
            if Singletons.peripheralManager.isAdvertising {
                return identifier == MainStoryboard.peripheralManagerServicesSegue
            } else if identifier == MainStoryboard.peripheralManagerAdvertisedServicesSegue {
                return PeripheralStore.getSupportedPeripheralServices().count > 0
            } else {
                return true
            }
        } else {
            return true
        }
    }

    @IBAction func toggleAdvertise(_ sender:AnyObject) {
        if Singletons.peripheralManager.isAdvertising {
            Singletons.peripheralManager.stopAdvertising()
            self.setUIState()
            return
        }
        guard let name = PeripheralStore.getPeripheralName() else {
            return
        }
        func afterAdvertisingStarted() {
            self.setUIState()
        }
        func afterAdvertisingStartFailed(_ error: Swift.Error) {
            self.setUIState()
            self.present(UIAlertController.alert(title: "Peripheral Advertise Error", error: error), animated: true, completion: nil)
        }
        let advertisedServices = PeripheralStore.getAdvertisedPeripheralServices()
        if advertisedServices.count > 0 {
            let future = Singletons.peripheralManager.startAdvertising(name, uuids: advertisedServices)
            future.onSuccess(completion: afterAdvertisingStarted)
            future.onFailure(completion: afterAdvertisingStartFailed)
        } else {
            let future = Singletons.peripheralManager.startAdvertising(name)
            future.onSuccess(completion: afterAdvertisingStarted)
            future.onFailure(completion: afterAdvertisingStartFailed)
        }
    }

    func setPeripheralManagerServices() {
        guard !Singletons.peripheralManager.isAdvertising else {
            return
        }
        Singletons.peripheralManager.removeAllServices()
        self.loadPeripheralServicesFromConfig()
    }

    func loadPeripheralServicesFromConfig() {
        let serviceUUIDs = PeripheralStore.getSupportedPeripheralServices()
        guard serviceUUIDs.count > 0 else {
            return
        }
        let services = serviceUUIDs.reduce([MutableService]()){ services, uuid in
            if let serviceProfile = Singletons.profileManager.services[uuid] {
                let service = MutableService(profile: serviceProfile)
                service.characteristicsFromProfiles()
                return services + [service]
            } else {
                return services
            }
        }
        let future = services.map { Singletons.peripheralManager.add($0) }.sequence()
        future.onSuccess { _ in
            self.setUIState()
        }
        future.onFailure { [weak self] error in
            self?.setUIState()
            self?.present(UIAlertController.alert(title: "Add Services Error", error:error), animated:true, completion:nil)
        }
    }

    func setUIState() {
        let advertisedServicesCount = PeripheralStore.getAdvertisedPeripheralServices().count
        let supportedServicesCount = PeripheralStore.getSupportedPeripheralServices().count
        advertisedServicesCountLabel.text = "\(advertisedServicesCount)"
        servicesCountLabel.text = "\(supportedServicesCount)"
        if Singletons.peripheralManager.isAdvertising {
            navigationItem.setHidesBackButton(true, animated:true)
            advertiseSwitch.isOn = true
            nameTextField.isEnabled = false
            advertisedServicesLabel.textColor = UIColor.lightGray
        } else {
            nameTextField.isEnabled = true
            navigationItem.setHidesBackButton(false, animated:true)
            if canAdvertise() {
                advertiseSwitch.isEnabled = true
                advertiseLabel.textColor = UIColor.black
            } else {
                advertiseSwitch.isEnabled = false
                advertiseLabel.textColor = UIColor.lightGray
            }
            if supportedServicesCount == 0 {
                advertiseSwitch.isOn = false
                advertisedServicesLabel.textColor = UIColor.lightGray
            } else {
                navigationItem.setHidesBackButton(false, animated:true)
                advertiseSwitch.isOn = false
                advertisedServicesLabel.textColor = UIColor.black
            }
        }
    }

    func alert(message: String) {
        present(UIAlertController.alert(message: message), animated:true) { [weak self] _ in
            self.forEach { strongSelf in
                Singletons.peripheralManager.reset()
            }
        }
    }

    func canAdvertise() -> Bool {
        return PeripheralStore.getPeripheralName() != nil && PeripheralStore.getSupportedPeripheralServices().count > 0
    }

    // UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.nameTextField.resignFirstResponder()
        if let enteredName = self.nameTextField.text, !enteredName.isEmpty {
            PeripheralStore.setPeripheralName(enteredName)
        }
        self.setUIState()
        return true
    }

}
