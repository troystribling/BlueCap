//
//  ServiceCharacteristicProfileValuesViewController.swift
//  BlueCap
//
//  Created by Troy Stribling on 8/5/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import Foundation
import CoreBluetooth
import BlueCapKit

class ServiceCharacteristicProfileValuesViewController : UITableViewController {
    
    var characteristicProfile : BCCharacteristicProfile?
    
    var  values : [String:String]? {
        if let characteristicProfile = self.characteristicProfile {
            if let initialValue = characteristicProfile.initialValue {
                return characteristicProfile.stringValue(initialValue)
            } else {
                return nil
            }
        } else {
            return nil
        }
    }

    struct MainStoryboard {
        static let serviceCharacteristicProfileValueCell = "ServiceCharacteristicProfileValueCell"
    }
    
    required init?(coder aDecoder:NSCoder) {
        super.init(coder:aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let characteristicProfile = self.characteristicProfile {
            self.navigationItem.title = characteristicProfile.name
            self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.Plain, target:nil, action:nil)
        }
    }
    
    override func viewWillAppear(animated:Bool) {
        self.tableView.reloadData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func prepareForSegue(segue:UIStoryboardSegue, sender:AnyObject!) {
    }
    
    // UITableViewDataSource
    override func numberOfSectionsInTableView(tableView:UITableView) -> Int {
        return 1
    }
    
    override func tableView(_:UITableView, numberOfRowsInSection section:Int) -> Int {
        if let values = self.values {
            return values.count
        } else {
            return 0
        }
    }
    
    override func tableView(tableView:UITableView, cellForRowAtIndexPath indexPath:NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(MainStoryboard.serviceCharacteristicProfileValueCell, forIndexPath: indexPath) as! CharacteristicValueCell
        if let values = self.values {
            let characteristicValueNames = Array(values.keys)
            let characteristicValues = Array(values.values)
            cell.valueNameLabel.text = characteristicValueNames[indexPath.row]
            cell.valueLable.text = characteristicValues[indexPath.row]
        }
        return cell
    }
    
}