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
   
    var characteristic  : Characteristic?
    
    struct MainStoryboard {
        static let PeripheralServiceCharacteristicDiscreteValueCell  = "PeripheralServiceCharacteristicDiscreteValueCell"
    }

    init(coder aDecoder:NSCoder!) {
        super.init(coder:aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let characteristic = self.characteristic {
            self.navigationItem.title = characteristic.name
        }
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.Bordered, target:nil, action:nil)
    }
    
    override func prepareForSegue(segue:UIStoryboardSegue!, sender:AnyObject!) {
    }

    // UITableViewDataSource
    override func numberOfSectionsInTableView(tableView:UITableView!) -> Int {
        return 1
    }
    
    override func tableView(_:UITableView!, numberOfRowsInSection section:Int) -> Int {
        if let characteristic = self.characteristic {
            return 0
        } else {
            return 0
        }
    }
    
    override func tableView(tableView: UITableView!, cellForRowAtIndexPath indexPath: NSIndexPath!) -> UITableViewCell! {
        let cell = tableView.dequeueReusableCellWithIdentifier(MainStoryboard.PeripheralServiceCharacteristicDiscreteValueCell, forIndexPath:indexPath) as UITableViewCell
        if let stringValues = self.characteristic?.stringValues {
            let names = Array(stringValues.keys)
            let values = Array(stringValues.values)
            cell.textLabel.text = names[indexPath.row]
        }
        return cell
    }
    
    // UITableViewDelegate

}
