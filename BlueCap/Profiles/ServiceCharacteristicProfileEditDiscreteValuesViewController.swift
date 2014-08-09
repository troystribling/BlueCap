//
//  ServiceCharacteristicProfileEditDiscreteValuesViewController.swift
//  BlueCap
//
//  Created by Troy Stribling on 8/7/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import UIKit
import BlueCapKit

class ServiceCharacteristicProfileEditDiscreteValuesViewController : UITableViewController {
   
    weak var characteristicProfile  : CharacteristicProfile?
    
    struct MainStoryboard {
        static let serviceCharacteristicProfileEditDiscreteValuesCell  = "ServiceCharacteristicProfileEditDiscreteValuesCell"
    }
    
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
    
    required init(coder aDecoder:NSCoder!) {
        super.init(coder:aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let characteristicProfile = self.characteristicProfile {
            self.navigationItem.title = characteristicProfile.name
        }
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.Bordered, target:nil, action:nil)
    }
    
    // UITableViewDataSource
    override func numberOfSectionsInTableView(tableView:UITableView!) -> Int {
        return 1
    }
    
    override func tableView(_:UITableView!, numberOfRowsInSection section:Int) -> Int {
        if let characteristicProfile = self.characteristicProfile {
            return characteristicProfile.discreteStringValues.count
        } else {
            return 0
        }
    }
    
    override func tableView(tableView:UITableView!, cellForRowAtIndexPath indexPath:NSIndexPath!) -> UITableViewCell! {
        let cell = tableView.dequeueReusableCellWithIdentifier(MainStoryboard.serviceCharacteristicProfileEditDiscreteValuesCell, forIndexPath:indexPath) as UITableViewCell
        if let characteristicProfile = self.characteristicProfile {
            let stringValue = characteristicProfile.discreteStringValues[indexPath.row]
            cell.textLabel.text = stringValue
            if let value = self.values?[characteristicProfile.name] {
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
    override func tableView(tableView:UITableView!, didSelectRowAtIndexPath indexPath:NSIndexPath!) {
        if let characteristicProfile = self.characteristicProfile {
            let stringValue : Dictionary<String, String> = [characteristicProfile.name:characteristicProfile.discreteStringValues[indexPath.row]]
            characteristicProfile.initialValue = characteristicProfile.dataFromStringValue(stringValue)
            self.navigationController.popViewControllerAnimated(true)
        }
    }
    
}
