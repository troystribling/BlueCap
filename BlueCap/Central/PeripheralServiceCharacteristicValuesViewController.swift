//
//  PeripheralServiceCharacteristicValuesViewController.swift
//  BlueCap
//
//  Created by Troy Stribling on 7/5/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import UIKit
import BlueCapKit

class PeripheralServiceCharacteristicValuesViewController : UITableViewController {
   
    weak var characteristic     : Characteristic?
    let progressView            : ProgressView!
    var selectedIndex           : NSIndexPath?
    
    @IBOutlet var refreshButton :UIButton!
    
    struct MainStoryboard {
        static let peripheralServiceCharactertisticValueCell                = "PeripheralServiceCharacteristicValueCell"
        static let peripheralServiceCharacteristicEditDiscreteValuesSegue   = "PeripheralServiceCharacteristicEditDiscreteValues"
        static let peripheralServiceCharacteristicEditValueSeque            = "PeripheralServiceCharacteristicEditValue"
    }
    
    init(coder aDecoder:NSCoder!) {
        super.init(coder:aDecoder)
        self.progressView = ProgressView()
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
            self.updateValues()
        }
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.Bordered, target:nil, action:nil)
    }
    
    override func viewDidAppear(animated:Bool)  {
        self.updateValues()
    }
    
    override func prepareForSegue(segue:UIStoryboardSegue!, sender:AnyObject!) {
        if let characteristic = self.characteristic {
            if segue.identifier == MainStoryboard.peripheralServiceCharacteristicEditDiscreteValuesSegue {
                let viewController = segue.destinationViewController as PeripheralServiceCharacteristicEditDiscreteValuesViewController
                viewController.characteristic = self.characteristic
            } else if segue.identifier == MainStoryboard.peripheralServiceCharacteristicEditValueSeque {
                if let stringValues = characteristic.stringValues {
                    let viewController = segue.destinationViewController as PeripheralServiceCharacteristicEditValueViewController
                    viewController.characteristic = self.characteristic
                    if let selectedIndex = self.selectedIndex {
                        let names = Array(stringValues.keys)
                        viewController.valueName = names[selectedIndex.row]
                    }
                }
            }
        }
    }
    
    @IBAction func updateValues() {
        self.progressView.show()
        self.readValues()
    }
    
    // UITableViewDataSource
    override func numberOfSectionsInTableView(tableView:UITableView!) -> Int {
        return 1
    }
    
    override func tableView(_:UITableView!, numberOfRowsInSection section:Int) -> Int {
        if let values = self.characteristic?.stringValues {
            return values.count
        } else {
            return 0;
        }
    }
    
    override func tableView(tableView:UITableView!, cellForRowAtIndexPath indexPath:NSIndexPath!) -> UITableViewCell! {
        let cell = tableView.dequeueReusableCellWithIdentifier(MainStoryboard.peripheralServiceCharactertisticValueCell, forIndexPath:indexPath) as PeripheralServiceCharacteristicValueCell
        if let characteristic = self.characteristic {
            if let stringValues = characteristic.stringValues {
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
    override func tableView(tableView:UITableView!, didSelectRowAtIndexPath indexPath:NSIndexPath!) {
        self.selectedIndex = indexPath
        if let characteristic = self.characteristic {
            if characteristic.propertyEnabled(.Write) || characteristic.propertyEnabled(.WriteWithoutResponse) {
                if characteristic.discreteStringValues.isEmpty {
                    self.performSegueWithIdentifier(MainStoryboard.peripheralServiceCharacteristicEditValueSeque, sender:self)
                } else {
                    self.performSegueWithIdentifier(MainStoryboard.peripheralServiceCharacteristicEditDiscreteValuesSegue, sender:self)
                }
            }
        }
    }
    
    // PRIVATE
    func readValues() {
        if let characteristic = self.characteristic {
            if characteristic.propertyEnabled(.Read) {
                characteristic.read({
                        self.tableView.reloadData()
                        self.progressView.remove()
                    },
                    afterReadFailedCallback:{(error) in
                        self.progressView.remove()
                        self.presentViewController(UIAlertController.alertOnError(error), animated:true, completion:nil)
                    })
            } else if characteristic.propertyEnabled(.Notify) {
                characteristic.startUpdates({
                        self.tableView.reloadData()
                        self.progressView.remove()
                    },
                    afterUpdateFailedCallback:{(error) in
                        self.progressView.remove()
                        self.presentViewController(UIAlertController.alertOnError(error), animated:true, completion:nil)
                    })
            }
        }
    }
}
