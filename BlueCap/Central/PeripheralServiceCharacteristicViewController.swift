//
//  PeripheralServiceCharacteristicViewController.swift
//  BlueCap
//
//  Created by Troy Stribling on 6/23/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import UIKit
import BlueCapKit

class PeripheralServiceCharacteristicViewController : UITableViewController {

    struct MainStoryboard {
        static let peripheralServiceCharacteristicValueSegue                        = "PeripheralServiceCharacteristicValues"
        static let peripheralServiceCharacteristicEditWriteOnlyDiscreteValuesSegue  = "PeripheralServiceCharacteristicEditWriteOnlyDiscreteValues"
        static let peripheralServiceCharacteristicEditWriteOnlyValueSeque           = "PeripheralServiceCharacteristicEditWriteOnlyValue"
    }
    
    weak var characteristic                                 : Characteristic!
    var peripheralViewController                            : PeripheralViewController!
    
    @IBOutlet var valuesLabel                               : UILabel!

    @IBOutlet var notifySwitch                              : UISwitch!
    @IBOutlet var notifyLabel                               : UILabel!
    
    @IBOutlet var uuidLabel                                 : UILabel!
    @IBOutlet var broadcastingLabel                         : UILabel!
    @IBOutlet var notifyingLabel                            : UILabel!
    
    @IBOutlet var propertyBroadcastLabel                    : UILabel!
    @IBOutlet var propertyReadLabel                         : UILabel!
    @IBOutlet var propertyWriteWithoutResponseLabel         : UILabel!
    @IBOutlet var propertyWriteLabel                        : UILabel!
    @IBOutlet var propertyNotifyLabel                       : UILabel!
    @IBOutlet var propertyIndicateLabel                     : UILabel!
    @IBOutlet var propertyAuthenticatedSignedWritesLabel    : UILabel!
    @IBOutlet var propertyExtendedPropertiesLabel           : UILabel!
    @IBOutlet var propertyNotifyEncryptionRequiredLabel     : UILabel!
    @IBOutlet var propertyIndicateEncryptionRequiredLabel   : UILabel!
    
    required init(coder aDecoder:NSCoder) {
        super.init(coder:aDecoder)
    }
    
    override func viewDidLoad()  {
        self.navigationItem.title = self.characteristic.name

        self.setUI()
        
        self.uuidLabel.text = self.characteristic.uuid.UUIDString
        self.notifyingLabel.text = self.booleanStringValue(self.characteristic.isNotifying)
        self.broadcastingLabel.text = self.booleanStringValue(self.characteristic.isBroadcasted)
        
        self.propertyBroadcastLabel.text = self.booleanStringValue(self.characteristic.propertyEnabled(.Broadcast))
        self.propertyReadLabel.text = self.booleanStringValue(self.characteristic.propertyEnabled(.Read))
        self.propertyWriteWithoutResponseLabel.text = self.booleanStringValue(self.characteristic.propertyEnabled(.WriteWithoutResponse))
        self.propertyWriteLabel.text = self.booleanStringValue(self.characteristic.propertyEnabled(.Write))
        self.propertyNotifyLabel.text = self.booleanStringValue(self.characteristic.propertyEnabled(.Notify))
        self.propertyIndicateLabel.text = self.booleanStringValue(self.characteristic.propertyEnabled(.Indicate))
        self.propertyAuthenticatedSignedWritesLabel.text = self.booleanStringValue(self.characteristic.propertyEnabled(.AuthenticatedSignedWrites))
        self.propertyExtendedPropertiesLabel.text = self.booleanStringValue(self.characteristic.propertyEnabled(.ExtendedProperties))
        self.propertyNotifyEncryptionRequiredLabel.text = self.booleanStringValue(self.characteristic.propertyEnabled(.NotifyEncryptionRequired))
        self.propertyIndicateEncryptionRequiredLabel.text = self.booleanStringValue(self.characteristic.propertyEnabled(.IndicateEncryptionRequired))
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.Bordered, target:nil, action:nil)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.setUI()
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"peripheralDisconnected", name:BlueCapNotification.peripheralDisconnected, object:self.characteristic?.service.peripheral)
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"didBecomeActive", name:BlueCapNotification.didBecomeActive, object:nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"didResignActive", name:BlueCapNotification.didResignActive, object:nil)
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    override func prepareForSegue(segue:UIStoryboardSegue, sender:AnyObject!) {
        if segue.identifier == MainStoryboard.peripheralServiceCharacteristicValueSegue {
            let viewController = segue.destinationViewController as PeripheralServiceCharacteristicValuesViewController
            viewController.characteristic = self.characteristic
        } else if segue.identifier == MainStoryboard.peripheralServiceCharacteristicEditWriteOnlyDiscreteValuesSegue {
            let viewController = segue.destinationViewController as PeripheralServiceCharacteristicEditDiscreteValuesViewController
            viewController.characteristic = self.characteristic
        } else if segue.identifier == MainStoryboard.peripheralServiceCharacteristicEditWriteOnlyValueSeque {
            let viewController = segue.destinationViewController as PeripheralServiceCharacteristicEditValueViewController
            viewController.characteristic = self.characteristic
            if let stringValues = self.characteristic.stringValues {
                let names = stringValues.keys.array
                viewController.valueName = names[0]
            }
        }
    }
    
    override func shouldPerformSegueWithIdentifier(identifier:String?, sender:AnyObject?) -> Bool {
        if let identifier = identifier {
            return (self.characteristic.propertyEnabled(.Read) || self.characteristic.isNotifying || self.characteristic.propertyEnabled(.Write)) && self.peripheralViewController.peripehealConnected
        } else {
            return false
        }
    }
    
    @IBAction func toggleNotificatons() {
        if self.characteristic.isNotifying {
            self.characteristic.stopNotifying({
                    self.setUI()
                    self.characteristic.stopUpdates()
                },
                notificationStateChangedFailedCallback: {(error) in
                    self.notifySwitch.on = false
                    self.setUI()
                    self.presentViewController(UIAlertController.alertOnError(error), animated:true, completion:nil)
                })
        } else {
            self.characteristic.startNotifying({
                    self.setUI()
                },
                notificationStateChangedFailedCallback:{(error) in
                    self.notifySwitch.on = false
                    self.setUI()
                    self.presentViewController(UIAlertController.alertOnError(error), animated:true, completion:nil)
                }
            )
        }
    }
    
    func setUI() {
        if (!self.characteristic.propertyEnabled(.Read) && !self.characteristic.propertyEnabled(.Write) && !self.characteristic.isNotifying) || !self.peripheralViewController.peripehealConnected {
            self.valuesLabel.textColor = UIColor.lightGrayColor()
        } else {
            self.valuesLabel.textColor = UIColor.blackColor()
        }
        if self.characteristic.propertyEnabled(.Notify)  && self.peripheralViewController.peripehealConnected {
            self.notifyLabel.textColor = UIColor.blackColor()
            self.notifySwitch.enabled = true
            self.notifySwitch.on = self.characteristic.isNotifying
        } else {
            self.notifyLabel.textColor = UIColor.lightGrayColor()
            self.notifySwitch.enabled = false
            self.notifySwitch.on = false
        }
    }
    
    func booleanStringValue(value:Bool) -> String {
        return value ? "YES" : "NO"
    }
    
    func peripheralDisconnected() {
        Logger.debug("PeripheralServiceCharacteristicViewController#peripheralDisconnected")
        if self.peripheralViewController.peripehealConnected {
            self.presentViewController(UIAlertController.alertWithMessage("Peripheral disconnected") {(action) in
                    self.peripheralViewController.peripehealConnected = false
                    self.setUI()
                }, animated:true, completion:nil)
        }
    }

    func didResignActive() {
        self.navigationController?.popToRootViewControllerAnimated(false)
       Logger.debug("PeripheralServiceCharacteristicViewController#didResignActive")
    }
    
    func didBecomeActive() {
        Logger.debug("PeripheralServiceCharacteristicViewController#didBecomeActive")
    }
    
    override func tableView(tableView:UITableView, didSelectRowAtIndexPath indexPath:NSIndexPath) {
        if indexPath.row == 0 {
            if (self.characteristic.propertyEnabled(.Write) || self.characteristic.propertyEnabled(.WriteWithoutResponse)) && !self.characteristic.propertyEnabled(.Read) {
                if self.characteristic.discreteStringValues.isEmpty {
                    self.performSegueWithIdentifier(MainStoryboard.peripheralServiceCharacteristicEditWriteOnlyValueSeque, sender:indexPath)
                } else {
                    self.performSegueWithIdentifier(MainStoryboard.peripheralServiceCharacteristicEditWriteOnlyDiscreteValuesSegue, sender:indexPath)
                }
            } else if self.characteristic.propertyEnabled(.Read) || self.characteristic.isNotifying  {
                self.performSegueWithIdentifier(MainStoryboard.peripheralServiceCharacteristicValueSegue, sender:indexPath)
            }
        }
    }

}
