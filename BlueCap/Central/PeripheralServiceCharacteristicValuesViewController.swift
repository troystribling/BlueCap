//
//  PeripheralServiceCharacteristicValuesViewController.swift
//  BlueCap
//
//  Created by Troy Stribling on 7/5/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import UIKit
import BlueCapKit

class PeripheralServiceCharacteristicValuesViewController : UITableViewController {
   
    weak var characteristic         : Characteristic?
    let progressView                : ProgressView!
    var peripheralViewController    : PeripheralViewController?

    
    @IBOutlet var refreshButton :UIButton!
    
    struct MainStoryboard {
        static let peripheralServiceCharactertisticValueCell                = "PeripheralServiceCharacteristicValueCell"
        static let peripheralServiceCharacteristicEditDiscreteValuesSegue   = "PeripheralServiceCharacteristicEditDiscreteValues"
        static let peripheralServiceCharacteristicEditValueSeque            = "PeripheralServiceCharacteristicEditValue"
    }
    
    required init?(coder aDecoder:NSCoder) {
        self.progressView = ProgressView()
        super.init(coder:aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let characteristic = self.characteristic {
            self.navigationItem.title = characteristic.name
            if characteristic.isNotifying {
                self.refreshButton.enabled = false
            } else {
                self.refreshButton.enabled = true
            }
        }
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.Plain, target:nil, action:nil)
    }
    
    override func viewDidAppear(animated:Bool)  {
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"peripheralDisconnected", name:BlueCapNotification.peripheralDisconnected, object:self.characteristic?.service?.peripheral)
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"didBecomeActive", name:BlueCapNotification.didBecomeActive, object:nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"didResignActive", name:BlueCapNotification.didResignActive, object:nil)
        self.updateValues()
    }
    
    override func viewDidDisappear(animated: Bool) {
        if let characteristic = self.characteristic {
            if characteristic.isNotifying {
                characteristic.stopNotificationUpdates()
            }
        }
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func prepareForSegue(segue:UIStoryboardSegue, sender:AnyObject!) {
        if segue.identifier == MainStoryboard.peripheralServiceCharacteristicEditDiscreteValuesSegue {
            let viewController = segue.destinationViewController as! PeripheralServiceCharacteristicEditDiscreteValuesViewController
            viewController.characteristic = self.characteristic
        } else if segue.identifier == MainStoryboard.peripheralServiceCharacteristicEditValueSeque {
            let viewController = segue.destinationViewController as! PeripheralServiceCharacteristicEditValueViewController
            viewController.characteristic = self.characteristic
            if let stringValues = self.characteristic?.stringValue {
                let selectedIndex = sender as! NSIndexPath
                let names = Array(stringValues.keys)
                viewController.valueName = names[selectedIndex.row]
            }
        }
    }
    
    @IBAction func updateValues() {
        if let characteristic = self.characteristic {
            if characteristic.isNotifying {
                let future = characteristic.receiveNotificationUpdates(10)
                future.onSuccess {_ in
                    self.updateWhenActive()
                }
                future.onFailure{(error) in
                    self.presentViewController(UIAlertController.alertOnError("Characteristic Notification Error", error:error), animated:true, completion:nil)
                }
            } else if characteristic.propertyEnabled(.Read) {
                self.progressView.show()
                let future = characteristic.read(Double(ConfigStore.getCharacteristicReadWriteTimeout()))
                future.onSuccess {_ in
                    self.updateWhenActive()
                    self.progressView.remove()
                }
                future.onFailure {(error) in
                    self.progressView.remove()
                    self.presentViewController(UIAlertController.alertOnError("Charcteristic Read Error", error:error) {(action) in
                        self.navigationController?.popViewControllerAnimated(true)
                        return
                    }, animated:true, completion:nil)
                }
            }
        }
    }
    
    func peripheralDisconnected() {
        Logger.debug()
        if let peripheralViewController = self.peripheralViewController {
            if peripheralViewController.peripehealConnected {
                self.progressView.remove()
                self.presentViewController(UIAlertController.alertWithMessage("Peripheral disconnected") {(action) in
                        peripheralViewController.peripehealConnected = false
                }, animated:true, completion:nil)
            }
        }
    }

    func didResignActive() {
        self.navigationController?.popToRootViewControllerAnimated(false)
       Logger.debug()
    }
    
    func didBecomeActive() {
        Logger.debug()
    }

    // UITableViewDataSource
    override func numberOfSectionsInTableView(tableView:UITableView) -> Int {
        return 1
    }
    
    override func tableView(_:UITableView, numberOfRowsInSection section:Int) -> Int {
        if let values = self.characteristic?.stringValue {
            return values.count
        } else {
            return 0;
        }
    }
    
    override func tableView(tableView:UITableView, cellForRowAtIndexPath indexPath:NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(MainStoryboard.peripheralServiceCharactertisticValueCell, forIndexPath:indexPath) as! CharacteristicValueCell
        if let characteristic = self.characteristic {
            if let stringValues = characteristic.stringValue {
                let names = Array(stringValues.keys)
                let values = Array(stringValues.values)
                cell.valueNameLabel.text = names[indexPath.row]
                cell.valueLable.text = values[indexPath.row]
            }
            if characteristic.propertyEnabled(.Write) || characteristic.propertyEnabled(.WriteWithoutResponse) {
                cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
            } else {
                cell.accessoryType = UITableViewCellAccessoryType.None
            }
        }
        return cell
    }
    
    // UITableViewDelegate
    override func tableView(tableView:UITableView, didSelectRowAtIndexPath indexPath:NSIndexPath) {
        if let characteristic = self.characteristic {
            if characteristic.propertyEnabled(.Write) || characteristic.propertyEnabled(.WriteWithoutResponse) {
                if characteristic.stringValues.isEmpty {
                    self.performSegueWithIdentifier(MainStoryboard.peripheralServiceCharacteristicEditValueSeque, sender:indexPath)
                } else {
                    self.performSegueWithIdentifier(MainStoryboard.peripheralServiceCharacteristicEditDiscreteValuesSegue, sender:indexPath)
                }
            }
        }
    }
}
