//
//  PeripheralManagerServiceCharacteristicEditDiscreteValuesViewController.swift
//  BlueCap
//
//  Created by Troy Stribling on 8/20/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import UIKit
import BlueCapKit

class PeripheralManagerServiceCharacteristicEditDiscreteValuesViewController : UITableViewController {
    
    var characteristic: BCMutableCharacteristic!
    var peripheralManagerViewController: PeripheralManagerViewController?

    struct MainStoryboard {
        static let peripheralManagerServiceCharacteristicDiscreteValueCell  = "PeripheralManagerServiceCharacteristicEditDiscreteValueCell"
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder:aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = self.characteristic.name
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(PeripheralManagerServiceCharacteristicEditDiscreteValuesViewController.didEnterBackground), name: UIApplicationDidEnterBackgroundNotification, object: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func didEnterBackground() {
        BCLogger.debug()
        if let peripheralManagerViewController = self.peripheralManagerViewController {
            self.navigationController?.popToViewController(peripheralManagerViewController, animated: false)
        }
    }
    
    // UITableViewDataSource
    override func numberOfSectionsInTableView(tableView:UITableView) -> Int {
        return 1
    }
    
    override func tableView(_:UITableView, numberOfRowsInSection section:Int) -> Int {
        return self.characteristic.stringValues.count
    }
    
    override func tableView(tableView:UITableView, cellForRowAtIndexPath indexPath:NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(MainStoryboard.peripheralManagerServiceCharacteristicDiscreteValueCell, forIndexPath: indexPath) as UITableViewCell
        let stringValue = characteristic.stringValues[indexPath.row]
        cell.textLabel?.text = stringValue
        if let valueName = self.characteristic.stringValue?.keys.first {
            if let value = self.characteristic.stringValue?[valueName] {
                if value == stringValue {
                    cell.accessoryType = UITableViewCellAccessoryType.Checkmark
                } else {
                    cell.accessoryType = UITableViewCellAccessoryType.None
                }
            }
        }
        return cell
    }
    
    // UITableViewDelegate
    override func tableView(tableView:UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let characteristic = self.characteristic {
            if let valueName = self.characteristic.stringValue?.keys.first {
                let stringValue = [valueName:characteristic.stringValues[indexPath.row]]
                characteristic.updateValueWithString(stringValue)
                self.navigationController?.popViewControllerAnimated(true)
            }
        }
    }
    
}
