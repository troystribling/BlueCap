//
//  PeripheralAdvertisements.swift
//  BlueCap
//
//  Created by Troy Stribling on 6/19/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import UIKit
import BlueCapKit

class PeripheralAdvertisementsViewController : UITableViewController {
   
    weak var peripheral : Peripheral?
    var names           : Array<String>  = []
    var values          : Array<String>  = []
    
    struct MainStoryboard {
        static let peripheralAdvertisementCell = "PeripheralAdvertisementCell"
    }
    
    required init(coder aDecoder:NSCoder)  {
        super.init(coder:aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let peripheral = self.peripheral {
            self.names = peripheral.advertisements.keys.array
            self.values = peripheral.advertisements.values.array
        }
    }
    
    // UITableViewDataSource
    override func numberOfSectionsInTableView(tableView:UITableView!) -> Int {
        return 1
    }
    
    override func tableView(_:UITableView!, numberOfRowsInSection section:Int) -> Int {
        println("Count:\(self.names.count)")
        return self.names.count
    }
    
    override func tableView(tableView: UITableView!, cellForRowAtIndexPath indexPath: NSIndexPath!) -> UITableViewCell! {
        let cell = tableView.dequeueReusableCellWithIdentifier(MainStoryboard.peripheralAdvertisementCell, forIndexPath: indexPath) as PeripheralAdvertisementCell
        cell.nameLabel.text = self.names[indexPath.row]
        cell.valueLabel.text = self.values[indexPath.row]
        return cell
    }

    
    // UITableViewDelegate
    
    // PRIVATE INTERFACE

}
