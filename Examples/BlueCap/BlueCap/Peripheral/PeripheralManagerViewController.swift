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
    @IBOutlet var advertisedBeaconSwitch: UISwitch!
    @IBOutlet var advertisedBeaconLabel: UILabel!
    @IBOutlet var advertisedServicesLabel: UILabel!
    @IBOutlet var advertisedServicesCountLabel: UILabel!
    @IBOutlet var servicesLabel: UILabel!
    @IBOutlet var servicesCountLabel: UILabel!
    @IBOutlet var beaconLabel: UILabel!
    @IBOutlet var advertisedLabel: UILabel!

    struct MainStoryboard {
        static let peripheralManagerServicesSegue = "PeripheralManagerServices"
        static let peripheralManagerAdvertisedServicesSegue = "PeripheralManagerAdvertisedServices"
        static let peripheralManagerBeaconsSegue = "PeripheralManagerBeacons"
    }
    
    var peripheral : String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let peripheral = peripheral {
            nameTextField.text = peripheral
        }
    }
    
    override func viewWillAppear(_ animated:Bool) {
        super.viewWillAppear(animated)
        self.navigationItem.title = "Peripheral"
        guard let peripheral = peripheral else {
            return
        }
        if let advertisedBeacon = PeripheralStore.getAdvertisedBeacon(peripheral) {
            self.advertisedBeaconLabel.text = advertisedBeacon
        } else {
            self.advertisedBeaconLabel.text = "None"
        }
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
            viewController.peripheral = self.peripheral
            viewController.peripheralManagerViewController = self
        } else if segue.identifier == MainStoryboard.peripheralManagerAdvertisedServicesSegue {
            let viewController = segue.destination as! PeripheralManagerAdvertisedServicesViewController
            viewController.peripheral = self.peripheral
            viewController.peripheralManagerViewController = self
        } else if segue.identifier == MainStoryboard.peripheralManagerBeaconsSegue {
            let viewController = segue.destination as! PeripheralManagerBeaconsViewController
            viewController.peripheral = self.peripheral
            viewController.peripheralManagerViewController = self
        }
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String?, sender: Any?) -> Bool {
        guard let peripheral = self.peripheral else {
            return false
        }
        if let identifier = identifier {
            if Singletons.peripheralManager.isAdvertising {
                return identifier == MainStoryboard.peripheralManagerServicesSegue
            } else if identifier == MainStoryboard.peripheralManagerAdvertisedServicesSegue {
                return PeripheralStore.getPeripheralServicesForPeripheral(peripheral).count > 0
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
        guard let peripheral = peripheral else {
            return
        }
        func afterAdvertisingStarted() {
            self.setUIState()
        }
        func afterAdvertisingStartFailed(_ error: Swift.Error) {
            self.setUIState()
            self.present(UIAlertController.alert(title: "Peripheral Advertise Error", error: error), animated: true, completion: nil)
        }
        let advertisedServices = PeripheralStore.getAdvertisedPeripheralServicesForPeripheral(peripheral)
        if PeripheralStore.getBeaconEnabled(peripheral) {
            if let name = self.advertisedBeaconLabel.text {
                if let uuid = PeripheralStore.getBeacon(name) {
                    let beaconConfig = PeripheralStore.getBeaconConfig(name)
                    let beaconRegion = BeaconRegion(proximityUUID: uuid, identifier: name, major: beaconConfig[1], minor: beaconConfig[0])
                    let future = Singletons.peripheralManager.startAdvertising(beaconRegion)
                    future.onSuccess(completion: afterAdvertisingStarted)
                    future.onFailure(completion: afterAdvertisingStartFailed)
                }
            }
        } else if advertisedServices.count > 0 {
            let future = Singletons.peripheralManager.startAdvertising(peripheral, uuids: advertisedServices)
            future.onSuccess(completion: afterAdvertisingStarted)
            future.onFailure(completion: afterAdvertisingStartFailed)
        } else {
            let future = Singletons.peripheralManager.startAdvertising(peripheral)
            future.onSuccess(completion: afterAdvertisingStarted)
            future.onFailure(completion: afterAdvertisingStartFailed)
        }
    }
    
    @IBAction func toggleBeacon(_ sender:AnyObject) {
        guard let peripheral = self.peripheral else {
            return
        }
        if PeripheralStore.getBeaconEnabled(peripheral) {
            PeripheralStore.setBeaconEnabled(peripheral, enabled:false)
        } else {
            if let name = self.advertisedBeaconLabel.text {
                if PeripheralStore.getBeacon(name) != nil {
                    PeripheralStore.setBeaconEnabled(peripheral, enabled:true)
                } else {
                    self.present(UIAlertController.alert(message: "iBeacon is invalid"), animated: true, completion: nil)
                }
            }
        }
        self.setUIState()
    }

    func setPeripheralManagerServices() {
        guard !Singletons.peripheralManager.isAdvertising else {
            return
        }
        Singletons.peripheralManager.removeAllServices()
        if self.peripheral != nil {
            self.loadPeripheralServicesFromConfig()
        } else {
            self.setUIState()
        }
    }

    func loadPeripheralServicesFromConfig() {
        guard let peripheral = self.peripheral else {
            return
        }
        let serviceUUIDs = PeripheralStore.getPeripheralServicesForPeripheral(peripheral)
        let services = serviceUUIDs.reduce([MutableService]()){ (services, uuid) in
            if let serviceProfile = Singletons.profileManager.services[uuid] {
                let service = MutableService(profile:serviceProfile)
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
        guard let peripheral = self.peripheral else {
            return
        }
        advertisedBeaconSwitch.isOn = PeripheralStore.getBeaconEnabled(peripheral)
        advertisedServicesCountLabel.text = "\(PeripheralStore.getAdvertisedPeripheralServicesForPeripheral(peripheral).count)"
        servicesCountLabel.text = "\(PeripheralStore.getPeripheralServicesForPeripheral(peripheral).count)"
        if Singletons.peripheralManager.isAdvertising {
            navigationItem.setHidesBackButton(true, animated:true)
            advertiseSwitch.isOn = true
            nameTextField.isEnabled = false
            beaconLabel.textColor = UIColor(red:0.7, green:0.7, blue:0.7, alpha:1.0)
            advertisedLabel.textColor = UIColor(red:0.7, green:0.7, blue:0.7, alpha:1.0)
            advertisedServicesLabel.textColor = UIColor(red:0.7, green:0.7, blue:0.7, alpha:1.0)
            advertisedBeaconSwitch.isEnabled = false
        } else if PeripheralStore.getPeripheralServicesForPeripheral(peripheral).count == 0 {
            advertiseSwitch.isOn = false
            beaconLabel.textColor = UIColor.black
            advertisedLabel.textColor = UIColor.black
            advertisedServicesLabel.textColor = UIColor(red:0.7, green:0.7, blue:0.7, alpha:1.0)
            navigationItem.setHidesBackButton(false, animated:true)
            nameTextField.isEnabled = true
            advertisedBeaconSwitch.isEnabled = true
        } else {
            advertiseSwitch.isOn = false
            beaconLabel.textColor = UIColor.black
            advertisedLabel.textColor = UIColor.black
            advertisedServicesLabel.textColor = UIColor.black
            navigationItem.setHidesBackButton(false, animated:true)
            nameTextField.isEnabled = true
            advertisedBeaconSwitch.isEnabled = true
        }
    }

    func alert(message: String) {
        present(UIAlertController.alert(message: message), animated:true) { [weak self] _ in
            self.forEach { strongSelf in
                Singletons.peripheralManager.reset()
            }
        }
    }

    // UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.nameTextField.resignFirstResponder()
        if let enteredName = self.nameTextField.text , !enteredName.isEmpty {
            if let oldname = self.peripheral {
                let services = PeripheralStore.getPeripheralServicesForPeripheral(oldname)
                PeripheralStore.removePeripheral(oldname)
                PeripheralStore.addPeripheralName(enteredName)
                PeripheralStore.addPeripheralServices(enteredName, services:services)
                self.peripheral = enteredName
            } else {
                self.peripheral = enteredName
                PeripheralStore.addPeripheralName(enteredName)
            }
        }
        self.setUIState()
        return true
    }

}
