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
    
    @IBOutlet var nameTextField             : UITextField!
    @IBOutlet var advertiseSwitch           : UISwitch!
    @IBOutlet var advertisedBeaconSwitch    : UISwitch!
    @IBOutlet var advertisedBeaconLabel     : UILabel!
    @IBOutlet var advertisedServicesLabel   : UILabel!
    @IBOutlet var servicesLabel             : UILabel!
    @IBOutlet var beaconLabel               : UILabel!

    struct MainStoryboard {
        static let peripheralManagerServicesSegue           = "PeripheralManagerServices"
        static let peripheralManagerAdvertisedServicesSegue = "PeripheralManagerAdvertisedServices"
        static let peripheralManagerBeaconsSegue            = "PeripheralManagerBeacons"
    }
    
    var peripheral : String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let peripheral = self.peripheral {
            self.nameTextField.text = peripheral
        }
    }
    
    override func viewWillAppear(animated:Bool) {
        super.viewWillAppear(animated)
        self.navigationItem.title = "Peripheral"
        if let peripheral = self.peripheral {
            if let advertisedBeacon = PeripheralStore.getAdvertisedBeacon(peripheral) {
                self.advertisedBeaconLabel.text = advertisedBeacon
            } else {
                self.advertisedBeaconLabel.text = "None"
            }
            Singletons.peripheralManager.whenPowerOn().onSuccess {
                self.setPeripheralManagerServices()
            }
            self.setUIState()
        }
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "didBecomeActive", name: BlueCapNotification.didBecomeActive, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "didResignActive", name: BlueCapNotification.didResignActive, object: nil)
    }

    override func viewWillDisappear(animated: Bool) {
        self.navigationItem.title = ""
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func prepareForSegue(segue:UIStoryboardSegue, sender:AnyObject!) {
        if segue.identifier == MainStoryboard.peripheralManagerServicesSegue {
            let viewController = segue.destinationViewController as! PeripheralManagerServicesViewController
            viewController.peripheral = self.peripheral
            viewController.peripheralManagerViewController = self
        } else if segue.identifier == MainStoryboard.peripheralManagerAdvertisedServicesSegue {
            let viewController = segue.destinationViewController as! PeripheralManagerAdvertisedServicesViewController
            viewController.peripheral = self.peripheral
            viewController.peripheralManagerViewController = self
        } else if segue.identifier == MainStoryboard.peripheralManagerBeaconsSegue {
            let viewController = segue.destinationViewController as! PeripheralManagerBeaconsViewController
            viewController.peripheral = self.peripheral
            viewController.peripheralManagerViewController = self
        }
    }
    
    override func shouldPerformSegueWithIdentifier(identifier: String?, sender: AnyObject?) -> Bool {
        if let _ = self.peripheral {
            if let identifier = identifier {
                if identifier != MainStoryboard.peripheralManagerServicesSegue {
                    return !Singletons.peripheralManager.isAdvertising
                } else {
                    return true
                }
            } else {
                return true
            }
        } else {
            return false
        }
    }

    @IBAction func toggleAdvertise(sender:AnyObject) {
        if Singletons.peripheralManager.isAdvertising {
            Singletons.peripheralManager.stopAdvertising().onSuccess {
                self.setUIState()
            }
        } else {
            if let peripheral = self.peripheral {
                let afterAdvertisingStarted = {
                    self.setUIState()
                }
                let afterAdvertisingStartFailed:(error:NSError)->() = {(error) in
                    self.setUIState()
                    self.presentViewController(UIAlertController.alertOnError("Peripheral Advertise Error", error: error), animated: true, completion: nil)
                }
                let advertisedServices = PeripheralStore.getAdvertisedPeripheralServicesForPeripheral(peripheral)
                if PeripheralStore.getBeaconEnabled(peripheral) {
                    if let name = self.advertisedBeaconLabel.text {
                        if let uuid = PeripheralStore.getBeacon(name) {
                            let beaconConfig = PeripheralStore.getBeaconConfig(name)
                            let beaconRegion = FLBeaconRegion(proximityUUID: uuid, identifier: name, major: beaconConfig[1], minor: beaconConfig[0])
                            let future = Singletons.peripheralManager.startAdvertising(beaconRegion)
                            future.onSuccess(afterAdvertisingStarted)
                            future.onFailure(afterAdvertisingStartFailed)
                        }
                    }
                } else if advertisedServices.count > 0 {
                    let future = Singletons.peripheralManager.startAdvertising(peripheral, uuids: advertisedServices)
                    future.onSuccess(afterAdvertisingStarted)
                    future.onFailure(afterAdvertisingStartFailed)
                } else {
                    let future = Singletons.peripheralManager.startAdvertising(peripheral)
                    future.onSuccess(afterAdvertisingStarted)
                    future.onFailure(afterAdvertisingStartFailed)
                }
            }
        }
    }
    
    @IBAction func toggleBeacon(sender:AnyObject) {
        if let peripheral = self.peripheral {
            if PeripheralStore.getBeaconEnabled(peripheral) {
                PeripheralStore.setBeaconEnabled(peripheral, enabled:false)
            } else {
                if let name = self.advertisedBeaconLabel.text {
                    if PeripheralStore.getBeacon(name) != nil {
                        PeripheralStore.setBeaconEnabled(peripheral, enabled:true)
                    } else {
                        self.presentViewController(UIAlertController.alertWithMessage("iBeacon is invalid"), animated: true, completion: nil)
                    }
                }
            }
            self.setUIState()
        }
    }

    func setPeripheralManagerServices() {
        if !Singletons.peripheralManager.isAdvertising {
            let future = Singletons.peripheralManager.removeAllServices()
            future.onSuccess {
                if self.peripheral != nil {
                    self.loadPeripheralServicesFromConfig()
                } else {
                    self.setUIState()
                }
            }
            future.onFailure {error in
                self.presentViewController(UIAlertController.alertOnError("Remove Services Error", error: error), animated: true, completion: nil)
            }
        }
    }

    func loadPeripheralServicesFromConfig() {
        if let peripheral = self.peripheral {
            let serviceUUIDs = PeripheralStore.getPeripheralServicesForPeripheral(peripheral)
            let services = serviceUUIDs.reduce([BCMutableService]()){ (services, uuid) in
                if let serviceProfile = Singletons.peripheralManager.service[uuid] {
                    let service = BCMutableService(profile:serviceProfile)
                    service.characteristicsFromProfiles()
                    return services + [service]
                } else {
                    return services
                }
            }
            let future = Singletons.peripheralManager.addServices(services)
            future.onSuccess {
                self.setUIState()
            }
            future.onFailure {(error) in
                self.setUIState()
                self.presentViewController(UIAlertController.alertOnError("Add Services Error", error:error), animated:true, completion:nil)
            }
        }
    }

    func setUIState() {
        if let peripheral = self.peripheral {
            self.advertisedBeaconSwitch.on = PeripheralStore.getBeaconEnabled(peripheral)
            if Singletons.peripheralManager.isAdvertising {
                self.navigationItem.setHidesBackButton(true, animated:true)
                self.advertiseSwitch.on = true
                self.nameTextField.enabled = false
                self.beaconLabel.textColor = UIColor(red:0.7, green:0.7, blue:0.7, alpha:1.0)
                self.advertisedServicesLabel.textColor = UIColor(red:0.7, green:0.7, blue:0.7, alpha:1.0)
            } else {
                self.advertiseSwitch.on = false
                self.beaconLabel.textColor = UIColor.blackColor()
                self.advertisedServicesLabel.textColor = UIColor.blackColor()
                self.navigationItem.setHidesBackButton(false, animated:true)
                self.nameTextField.enabled = true
            }
        }
    }
    
    func didResignActive() {
        BCLogger.debug()
    }
    
    func didBecomeActive() {
        BCLogger.debug()
    }

    // UITextFieldDelegate
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        self.nameTextField.resignFirstResponder()
        if let enteredName = self.nameTextField.text {
            if !enteredName.isEmpty {
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
        }
        return true
    }

}
