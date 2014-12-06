//
//  PeripheralServiceCharacteristicEditDiscreteValuesViewController.swift
//  BlueCap
//
//  Created by Troy Stribling on 7/20/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import UIKit
import BlueCapKit

class PeripheralServiceCharacteristicEditDiscreteValuesViewController : UITableViewController {
   
    weak var characteristic         : Characteristic!
    var peripheralViewController    : PeripheralViewController?

    var progressView                = ProgressView()
    
    struct MainStoryboard {
        static let peripheralServiceCharacteristicDiscreteValueCell  = "PeripheraServiceCharacteristicEditDiscreteValueCell"
    }

    required init(coder aDecoder:NSCoder) {
        super.init(coder:aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = self.characteristic.name
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.Bordered, target:nil, action:nil)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"peripheralDisconnected", name:BlueCapNotification.peripheralDisconnected, object:self.characteristic?.service.peripheral)
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"didBecomeActive", name:BlueCapNotification.didBecomeActive, object:nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"didResignActive", name:BlueCapNotification.didResignActive, object:nil)
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func prepareForSegue(segue:UIStoryboardSegue, sender:AnyObject!) {
    }

    func peripheralDisconnected() {
        Logger.debug("PeripheralServiceCharacteristicEditDiscreteValuesViewController#peripheralDisconnected")
        if let peripheralViewController = self.peripheralViewController {
            if peripheralViewController.peripehealConnected {
                self.presentViewController(UIAlertController.alertWithMessage("Peripheral disconnected") {(action) in
                        peripheralViewController.peripehealConnected = false
                        self.navigationController?.popViewControllerAnimated(true)
                    }, animated:true, completion:nil)
            }
        }
    }

    func didResignActive() {
        self.navigationController?.popToRootViewControllerAnimated(false)
        Logger.debug("PeripheralServiceCharacteristicEditDiscreteValuesViewController#didResignActive")
    }
    
    func didBecomeActive() {
        Logger.debug("PeripheralServiceCharacteristicEditDiscreteValuesViewController#didBecomeActive")
    }

    // UITableViewDataSource
    override func numberOfSectionsInTableView(tableView:UITableView) -> Int {
        return 1
    }
    
    override func tableView(_:UITableView, numberOfRowsInSection section:Int) -> Int {
        return self.characteristic.discreteStringValues.count
    }
    
    override func tableView(tableView:UITableView, cellForRowAtIndexPath indexPath:NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(MainStoryboard.peripheralServiceCharacteristicDiscreteValueCell, forIndexPath:indexPath) as UITableViewCell
        let stringValue = self.characteristic.discreteStringValues[indexPath.row]
        cell.textLabel.text = stringValue
        if let value = self.characteristic.stringValues?[characteristic.name] {
            if value == stringValue {
                cell.accessoryType = UITableViewCellAccessoryType.Checkmark
            } else {
                cell.accessoryType = UITableViewCellAccessoryType.None
            }
        }
        return cell
    }
    
    // UITableViewDelegate
    override func tableView(tableView:UITableView, didSelectRowAtIndexPath indexPath:NSIndexPath) {
        self.progressView.show()
        if let characteristic = self.characteristic {
            let stringValue = [characteristic.name:characteristic.discreteStringValues[indexPath.row]]
            characteristic.writeString(stringValue)
                .onSuccess {
                    self.progressView.remove()
                    self.navigationController?.popViewControllerAnimated(true)
                    return
                }
                .onFailure {(error) in
                    self.presentViewController(UIAlertController.alertOnError(error), animated:true, completion:nil)
                    self.progressView.remove()
                    self.navigationController?.popViewControllerAnimated(true)
                    return
                }
        }
    }
    
}
