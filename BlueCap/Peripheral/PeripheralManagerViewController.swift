//
//  PeripheralManagerViewController.swift
//  BlueCapUI
//
//  Created by Troy Stribling on 6/5/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import UIKit
import BlueCapKit
import CoreBluetooth

class PeripheralManagerViewController : UITableViewController, UITextFieldDelegate {
    
    @IBOutlet var nameTextField             : UITextField!
    @IBOutlet var advertiseButton           : UIButton!
    @IBOutlet var advertisedBeaconButton    : UIButton!
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
        PeripheralManager.sharedInstance().powerOn({
                self.setPeripheralManagerServices()
            }, afterPowerOff:{
                self.setUIState()
        })
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
            self.setUIState()
        }
    }

    override func viewWillDisappear(animated: Bool) {
        self.navigationItem.title = ""
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func prepareForSegue(segue:UIStoryboardSegue, sender:AnyObject!) {
        if segue.identifier == MainStoryboard.peripheralManagerServicesSegue {
            let viewController = segue.destinationViewController as PeripheralManagerServicesViewController
            viewController.peripheral = self.peripheral
        } else if segue.identifier == MainStoryboard.peripheralManagerAdvertisedServicesSegue {
            let viewController = segue.destinationViewController as PeripheralManagerAdvertisedServicesViewController
            viewController.peripheral = self.peripheral
        } else if segue.identifier == MainStoryboard.peripheralManagerBeaconsSegue {
            let viewController = segue.destinationViewController as PeripheralManagerBeaconsViewController
            viewController.peripheral = self.peripheral
        }
    }
    
    override func shouldPerformSegueWithIdentifier(identifier:String, sender:AnyObject!) -> Bool {
        if let peripheral = self.peripheral {
            return !PeripheralManager.sharedInstance().isPoweredOn
        } else {
            return false
        }
    }

    @IBAction func toggleAdvertise(sender:AnyObject) {
        let manager = PeripheralManager.sharedInstance()
        if manager.isAdvertising {
            manager.stopAdvertising(){
                self.setUIState()
            }
        } else {
            if let peripheral = self.peripheral {
                let afterAdvertisingStarted = {
                    self.setUIState()
                }
                let afterAdvertisingStartFailed:(error:NSError!)->() = {(error) in
                    self.setUIState()
                    self.presentViewController(UIAlertController.alertOnError(error), animated:true, completion:nil)
                }
                let advertisedServices = PeripheralStore.getAdvertisedPeripheralServicesForPeripheral(peripheral)
                if PeripheralStore.getBeaconEnabled(peripheral) {
                    if let name = self.advertisedBeaconLabel.text {
                        if let uuid = PeripheralStore.getBeacon(name) {
                            let beaconConfig = PeripheralStore.getBeaconConfig(name)
                            let beaconRegion = BeaconRegion(proximityUUID:uuid, identifier:name, major:beaconConfig[1], minor:beaconConfig[0])
                            manager.startAdvertising(beaconRegion, afterAdvertisingStartedSuccess:afterAdvertisingStarted, afterAdvertisingStartFailed:afterAdvertisingStartFailed)
                        }
                    }
                } else if advertisedServices.count > 0 {
                    manager.startAdvertising(peripheral, uuids:advertisedServices, afterAdvertisingStartedSuccess:afterAdvertisingStarted, afterAdvertisingStartFailed:afterAdvertisingStartFailed)
                } else {
                    manager.startAdvertising(peripheral, afterAdvertisingStartedSuccess:afterAdvertisingStarted, afterAdvertisingStartFailed:afterAdvertisingStartFailed)
                }
            }
        }
    }
    
    @IBAction func toggleBeacon(sender:AnyObject) {
        if let peripheral = self.peripheral {
            if PeripheralStore.getBeaconEnabled(peripheral) {
                PeripheralStore.setBeaconEnabled(peripheral, enabled:false)
            } else {
                PeripheralStore.setBeaconEnabled(peripheral, enabled:true)
            }
            self.setUIState()
        }
    }

    func setPeripheralManagerServices() {
        let peripheralManager = PeripheralManager.sharedInstance()
        let profileManager = ProfileManager.sharedInstance()
        peripheralManager.removeAllServices() {
            if let peripheral = self.peripheral {
                self.loadPeripheralServicesFromConfig()
            } else {
                self.setUIState()
            }
        }
    }

    func loadPeripheralServicesFromConfig() {
        if let peripheral = self.peripheral {
            let peripheralManager = PeripheralManager.sharedInstance()
            let profileManager = ProfileManager.sharedInstance()
            let serviceUUIDs = PeripheralStore.getPeripheralServicesForPeripheral(peripheral)
            let services = serviceUUIDs.reduce([MutableService]()){(services, uuid) in
                if let serviceProfile = profileManager.service(uuid) {
                    let service = MutableService(profile:serviceProfile)
                    service.characteristicsFromProfiles(serviceProfile.characteristics)
                    return services + [service]
                } else {
                    return services
                }
            }
            peripheralManager.addServices(services, afterServiceAddSuccess:{
                self.setUIState()
                },  afterServiceAddFailed:{(error) in
                    self.setUIState()
                    self.presentViewController(UIAlertController.alertOnError(error), animated:true, completion:nil)
            })
        }
    }

    func setUIState() {
        if let peripheral = self.peripheral {
            self.advertiseButton.enabled = true
            self.advertisedBeaconButton.enabled = true
            let peripheralManager = PeripheralManager.sharedInstance()
            if peripheralManager.isAdvertising {
                self.advertiseButton.setTitleColor(UIColor(red:0.1, green:0.7, blue:0.1, alpha:1.0), forState:.Normal)
                self.navigationItem.setHidesBackButton(true, animated:true)
                self.nameTextField.enabled = false
            } else {
                self.advertiseButton.setTitleColor(UIColor(red:0.7, green:0.1, blue:0.1, alpha:1.0), forState:.Normal)
                self.navigationItem.setHidesBackButton(false, animated:true)
                self.nameTextField.enabled = true
            }
            if let advertisedBeacon = PeripheralStore.getAdvertisedBeacon(peripheral) {
                if PeripheralStore.getBeaconEnabled(peripheral) {
                    self.advertisedBeaconButton.setTitleColor(UIColor(red:0.1, green:0.7, blue:0.1, alpha:1.0), forState:.Normal)
                } else {
                    self.advertisedBeaconButton.setTitleColor(UIColor(red:0.7, green:0.1, blue:0.1, alpha:1.0), forState:.Normal)
                }
            } else {
                self.advertisedBeaconButton.setTitleColor(UIColor(red:0.7, green:0.7, blue:0.7, alpha:1.0), forState:.Normal)
                self.advertisedBeaconButton.enabled = false
            }
        } else {
            self.advertiseButton.setTitleColor(UIColor(red:0.7, green:0.7, blue:0.7, alpha:1.0), forState:.Normal)
            self.advertisedBeaconButton.setTitleColor(UIColor(red:0.7, green:0.7, blue:0.7, alpha:1.0), forState:.Normal)
            self.advertiseButton.enabled = false
            self.advertisedBeaconButton.enabled = false
        }
    }
    
    // UITextFieldDelegate
    func textFieldShouldReturn(textField: UITextField!) -> Bool {
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
