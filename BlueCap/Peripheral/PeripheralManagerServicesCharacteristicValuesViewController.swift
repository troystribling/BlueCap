//
//  PeripheralManagerServicesCharacteristicValuesViewController.swift
//  BlueCap
//
//  Created by Troy Stribling on 8/20/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import UIKit
import BlueCapKit
import CoreBluetooth

class PeripheralManagerServicesCharacteristicValuesViewController : UITableViewController {
    
    var characteristic                  : MutableCharacteristic!
    var peripheralManagerViewController : PeripheralManagerViewController?

    
    struct MainStoryboard {
        static let peripheralManagerServiceCharacteristicEditValueSegue             = "PeripheralManagerServiceCharacteristicEditValue"
        static let peripheralManagerServiceCharacteristicEditDiscreteValuesSegue    = "PeripheralManagerServiceCharacteristicEditDiscreteValues"
        static let peripheralManagerServicesCharacteristicValueCell                 = "PeripheralManagerServicesCharacteristicValueCell"
    }
    
    required init(coder aDecoder:NSCoder) {
        super.init(coder:aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated:Bool) {
        super.viewWillAppear(animated)
        self.tableView.reloadData()
        if let characteristic = self.characteristic {
            self.navigationItem.title = characteristic.name
        }
        let future = self.characteristic.startProcessingWriteRequests(capacity:10)
        future.onSuccess {(request) in
            if request.value.length > 0 {
                self.characteristic.value = request.value
                self.characteristic.respondToRequest(request, withResult:CBATTError.Success)
                self.updateWhenActive()
            } else {
                self.characteristic.respondToRequest(request, withResult:CBATTError.InvalidAttributeValueLength)
            }
        }
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"didBecomeActive", name:BlueCapNotification.didBecomeActive, object:nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"didResignActive", name:BlueCapNotification.didResignActive, object:nil)
    }
    
    override func viewWillDisappear(animated:Bool) {
        super.viewWillDisappear(animated)
        self.navigationItem.title = ""
        NSNotificationCenter.defaultCenter().removeObserver(self)
        self.characteristic.stopProcessingWriteRequests()
    }
    
    override func prepareForSegue(segue:UIStoryboardSegue, sender:AnyObject!) {
        if segue.identifier == MainStoryboard.peripheralManagerServiceCharacteristicEditValueSegue {
            let viewController = segue.destinationViewController as PeripheralManagerServiceCharacteristicEditValueViewController
            viewController.characteristic = self.characteristic
            let selectedIndex = sender as NSIndexPath
            if let stringValues = self.characteristic?.stringValue {
                let values = stringValues.keys.array
                viewController.valueName = values[selectedIndex.row]
            }
            if let peripheralManagerViewController = self.peripheralManagerViewController {
                viewController.peripheralManagerViewController = peripheralManagerViewController
            }
        } else if segue.identifier == MainStoryboard.peripheralManagerServiceCharacteristicEditDiscreteValuesSegue {
            let viewController = segue.destinationViewController as PeripheralManagerServiceCharacteristicEditDiscreteValuesViewController
            viewController.characteristic = self.characteristic
            if let peripheralManagerViewController = self.peripheralManagerViewController {
                viewController.peripheralManagerViewController = peripheralManagerViewController
            }
        }
    }
    
    func didResignActive() {
        Logger.debug("PeripheralManagerServicesViewController#didResignActive")
        if let peripheralManagerViewController = self.peripheralManagerViewController {
            self.navigationController?.popToViewController(peripheralManagerViewController, animated:false)
        }
    }
    
    func didBecomeActive() {
        Logger.debug("PeripheralManagerServicesViewController#didBecomeActive")
    }

    override func numberOfSectionsInTableView(tableView:UITableView) -> Int {
        return 1
    }
    
    override func tableView(_:UITableView, numberOfRowsInSection section:Int) -> Int {
        if let values = self.characteristic?.stringValue {
            return values.count
        } else {
            return 0
        }
    }
    
    override func tableView(tableView:UITableView, cellForRowAtIndexPath indexPath:NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(MainStoryboard.peripheralManagerServicesCharacteristicValueCell, forIndexPath: indexPath) as CharacteristicValueCell
        if let values = self.characteristic?.stringValue {
            let characteristicValueNames = values.keys.array
            let characteristicValues = values.values.array
            cell.valueNameLabel.text = characteristicValueNames[indexPath.row]
            cell.valueLable.text = characteristicValues[indexPath.row]
        }
        return cell
    }
    
    override func tableView(tableView:UITableView, didSelectRowAtIndexPath indexPath:NSIndexPath) {
        if self.characteristic.stringValues.isEmpty {
            self.performSegueWithIdentifier(MainStoryboard.peripheralManagerServiceCharacteristicEditValueSegue, sender:indexPath)
        } else {
            self.performSegueWithIdentifier(MainStoryboard.peripheralManagerServiceCharacteristicEditDiscreteValuesSegue, sender:indexPath)
        }
    }

}
