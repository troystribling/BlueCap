//
//  ServiceCharacteristicProfileValuesViewController.swift
//  BlueCap
//
//  Created by Troy Stribling on 8/5/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation
import CoreBluetooth
import BlueCapKit

class ServiceCharacteristicProfileValuesViewController : UITableViewController {
    
    var characteristicProfile : CharacteristicProfile?
    
    var  values : Dictionary<String, String>? {
        if let characteristicProfile = self.characteristicProfile {
            if let initialValue = characteristicProfile.initialValue {
                return characteristicProfile.stringValues(initialValue)
            } else {
                return nil
            }
        } else {
            return nil
        }
    }

    struct MainStoryboard {
        static let serviceCharacteristicProfileValueCell                = "ServiceCharacteristicProfileValueCell"
        static let serviceCharacteristicProfileEditValueSegue           = "ServiceCharacteristicProfileEditValue"
        static let serviceCharacteristicProfileEditDiscreteValuesSegue  = "ServiceCharacteristicProfileEditDiscreteValues"
    }
    
    init(coder aDecoder:NSCoder!) {
        super.init(coder:aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let characteristicProfile = self.characteristicProfile {
            self.navigationItem.title = characteristicProfile.name
            self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.Bordered, target:nil, action:nil)
        }
    }
    
    override func viewWillAppear(animated:Bool) {
        self.tableView.reloadData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue!, sender:AnyObject!) {
        let selectedIndex = sender as NSIndexPath
        if segue.identifier == MainStoryboard.serviceCharacteristicProfileEditValueSegue {
            let viewController = segue.destinationViewController as ServiceCharacteristicProfileEditValueViewController
            viewController.characteristicProfile = self.characteristicProfile
            if let selectedIndex = sender as? NSIndexPath {
                if let values = self.values {
                    let valueNames = Array(values.keys)
                    viewController.valueName = valueNames[selectedIndex.row]
                }
            }
        } else if segue.identifier == MainStoryboard.serviceCharacteristicProfileEditDiscreteValuesSegue {
            let viewController = segue.destinationViewController as ServiceCharacteristicProfileEditDiscreteValuesViewController
            viewController.characteristicProfile = self.characteristicProfile
        }
    }
    
    // UITableViewDataSource
    override func numberOfSectionsInTableView(tableView:UITableView!) -> Int {
        return 1
    }
    
    override func tableView(_:UITableView!, numberOfRowsInSection section:Int) -> Int {
        if let values = self.values {
            return values.count
        } else {
            return 0
        }
    }
    
    override func tableView(tableView:UITableView!, cellForRowAtIndexPath indexPath:NSIndexPath!) -> UITableViewCell! {
        let cell = tableView.dequeueReusableCellWithIdentifier(MainStoryboard.serviceCharacteristicProfileValueCell, forIndexPath: indexPath) as CharacteristicValueCell
        if let values = self.values {
            let characteristicValueNames = Array(values.keys)
            let characteristicValues = Array(values.values)
            cell.valueNameLabel.text = characteristicValueNames[indexPath.row]
            cell.valueLable.text = characteristicValues[indexPath.row]
        }
        return cell
    }
    
    override func tableView(tableView:UITableView!, didSelectRowAtIndexPath indexPath:NSIndexPath!) {
        if let characteristicProfile = self.characteristicProfile {
            if characteristicProfile.discreteStringValues.isEmpty {
                self.performSegueWithIdentifier(MainStoryboard.serviceCharacteristicProfileEditValueSegue, sender:indexPath)
            } else {
                self.performSegueWithIdentifier(MainStoryboard.serviceCharacteristicProfileEditDiscreteValuesSegue, sender:indexPath)
            }
        }
    }
}