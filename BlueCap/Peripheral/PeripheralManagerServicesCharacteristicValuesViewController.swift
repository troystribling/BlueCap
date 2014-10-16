//
//  PeripheralManagerServicesCharacteristicValuesViewController.swift
//  BlueCap
//
//  Created by Troy Stribling on 8/20/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import UIKit
import BlueCapKit

class PeripheralManagerServicesCharacteristicValuesViewController : UITableViewController {
    
    var characteristic                  : MutableCharacteristic?
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
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"didBecomeActive", name:BlueCapNotification.didBecomeActive, object:nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"didResignActive", name:BlueCapNotification.didResignActive, object:nil)
    }
    
    override func viewWillDisappear(animated:Bool) {
        super.viewWillDisappear(animated)
        self.navigationItem.title = ""
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func prepareForSegue(segue:UIStoryboardSegue, sender:AnyObject!) {
        if segue.identifier == MainStoryboard.peripheralManagerServiceCharacteristicEditValueSegue {
            let viewController = segue.destinationViewController as PeripheralManagerServiceCharacteristicEditValueViewController
            viewController.characteristic = self.characteristic
            let selectedIndex = sender as NSIndexPath
            if let stringValues = self.characteristic?.stringValues {
                let values = stringValues.keys.array
                viewController.valueName = values[selectedIndex.row]
            }
        } else if segue.identifier == MainStoryboard.peripheralManagerServiceCharacteristicEditDiscreteValuesSegue {
            let viewController = segue.destinationViewController as PeripheralManagerServiceCharacteristicEditDiscreteValuesViewController
            viewController.characteristic = self.characteristic
        }
    }
    
    func didResignActive() {
        Logger.debug("PeripheralManagerServicesViewController#didResignActive")
    }
    
    func didBecomeActive() {
        Logger.debug("PeripheralManagerServicesViewController#didBecomeActive")
    }

    override func numberOfSectionsInTableView(tableView:UITableView) -> Int {
        return 1
    }
    
    override func tableView(_:UITableView, numberOfRowsInSection section:Int) -> Int {
        if let values = self.characteristic?.stringValues {
            return values.count
        } else {
            return 0
        }
    }
    
    override func tableView(tableView:UITableView, cellForRowAtIndexPath indexPath:NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(MainStoryboard.peripheralManagerServicesCharacteristicValueCell, forIndexPath: indexPath) as CharacteristicValueCell
        if let values = self.characteristic?.stringValues {
            let characteristicValueNames = values.keys.array
            let characteristicValues = values.values.array
            cell.valueNameLabel.text = characteristicValueNames[indexPath.row]
            cell.valueLable.text = characteristicValues[indexPath.row]
        }
        return cell
    }
    
    override func tableView(tableView:UITableView, didSelectRowAtIndexPath indexPath:NSIndexPath) {
        if let characteristic = self.characteristic {
            if characteristic.discreteStringValues.isEmpty {
                self.performSegueWithIdentifier(MainStoryboard.peripheralManagerServiceCharacteristicEditValueSegue, sender:indexPath)
            } else {
                self.performSegueWithIdentifier(MainStoryboard.peripheralManagerServiceCharacteristicEditDiscreteValuesSegue, sender:indexPath)
            }
        }
    }

}
