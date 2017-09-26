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
        let addServicesFuture = Singletons.peripheralManager.whenStateChanges().flatMap { [unowned self] state -> Future<[Void]> in
            switch state {
            case .poweredOn:
                return self.loadPeripheralServicesFromConfig()
            case .poweredOff:
                throw AppError.poweredOff
            case .unauthorized:
                throw AppError.unauthorized
            case .unknown:
                throw AppError.unknown
            case .unsupported:
                throw AppError.unsupported
            case .resetting:
                throw AppError.resetting
            }
        }

        addServicesFuture.onSuccess { [weak self] _ in
            self?.setUIState()
        }

        addServicesFuture.onFailure { [weak self] error in
            self.forEach { strongSelf in
                switch error {
                case AppError.poweredOff:
                    strongSelf.present(UIAlertController.alert(message: "Bluetooth powered off"), animated: true)
                case AppError.resetting:
                    let message = "PeripheralManager state \"\(Singletons.peripheralManager.state)\". The connection with the system bluetooth service was momentarily lost.\n Restart advertising."
                    strongSelf.present(UIAlertController.alert(message: message) { _ in
                        Singletons.peripheralManager.reset()
                    }, animated: true)
                case AppError.unsupported:
                    strongSelf.present(UIAlertController.alert(message: "Bluetooth not supported."), animated: true)
                case AppError.unknown:
                    break;
                default:
                    strongSelf.present(UIAlertController.alert(error: error) { _ in
                        Singletons.peripheralManager.reset()
                    }, animated: true, completion: nil)
                }
                strongSelf.setUIState()
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
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

    override func willMove(toParentViewController parent: UIViewController?) {
        if parent == nil {
            Singletons.peripheralManager.invalidate()
        }
    }

    @IBAction func toggleAdvertise(_ sender:AnyObject) {
        if Singletons.peripheralManager.isAdvertising {
            let stopAdvertisingFuture = Singletons.peripheralManager.stopAdvertising()
            stopAdvertisingFuture.onSuccess { [weak self] _ in
                self?.setUIState()
            }
            stopAdvertisingFuture.onFailure { [weak self] _ in
                self?.present(UIAlertController.alert(message: "Failed to stop advertising."), animated: true)
            }
            return
        }
        guard let name = PeripheralStore.getPeripheralName() else {
            return
        }
        let startAdvertiseFuture = loadPeripheralServicesFromConfig().flatMap { _ -> Future<Void> in
            let advertisedServices = PeripheralStore.getAdvertisedPeripheralServices()
            if advertisedServices.count > 0 {
                return Singletons.peripheralManager.startAdvertising(name, uuids: advertisedServices)
            } else {
                return Singletons.peripheralManager.startAdvertising(name)
            }
        }

        startAdvertiseFuture.onSuccess { [weak self] _ in
            self?.setUIState()
            self?.present(UIAlertController.alert(message: "Powered on and started advertising."), animated: true, completion: nil)
        }

        startAdvertiseFuture.onFailure { [weak self] error in
            self.forEach { strongSelf in
                switch error {
                case AppError.poweredOff:
                    break
                case AppError.resetting:
                    let message = "PeripheralManager state \"\(Singletons.peripheralManager.state)\". The connection with the system bluetooth service was momentarily lost.\n Restart advertising."
                    strongSelf.present(UIAlertController.alert(message: message) { _ in
                        Singletons.peripheralManager.reset()
                    }, animated: true)
                case AppError.unsupported:
                    strongSelf.present(UIAlertController.alert(message: "Bluetooth not supported."), animated: true)
                case AppError.unknown:
                    break;
                default:
                    strongSelf.present(UIAlertController.alert(error: error) { _ in
                        Singletons.peripheralManager.reset()
                    }, animated: true, completion: nil)
                }
                let stopAdvertisingFuture = Singletons.peripheralManager.stopAdvertising()
                stopAdvertisingFuture.onSuccess { _ in
                    strongSelf.setUIState()

                }
                stopAdvertisingFuture.onFailure { _ in
                    strongSelf.setUIState()
                }
            }
        }
    }

    func loadPeripheralServicesFromConfig() -> Future<[Void]> {
        let serviceUUIDs = PeripheralStore.getSupportedPeripheralServices()
        let services = serviceUUIDs.reduce([MutableService]()){ services, uuid in
            if let serviceProfile = Singletons.profileManager.services[uuid] {
                let service = MutableService(profile: serviceProfile)
                service.characteristicsFromProfiles()
                return services + [service]
            } else {
                return services
            }
        }
        Singletons.peripheralManager.removeAllServices()
        return services.map { Singletons.peripheralManager.add($0) }.sequence()
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
        if !Singletons.peripheralManager.poweredOn {
            advertiseSwitch.isEnabled = false
            advertiseLabel.textColor = UIColor.lightGray
        }
    }

    func alert(message: String) {
        present(UIAlertController.alert(message: message), animated:true) { [weak self] () -> Void in
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
