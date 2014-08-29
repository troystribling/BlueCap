//
//  ConfigureScanModeViewController.swift
//  BlueCap
//
//  Created by Troy Stribling on 8/29/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import UIKit
import BlueCapKit

class ConfigureScanModeViewController : UITableViewController {
    
    struct MainStoryboard {
        static let configureScanModeCell = "ConfigureScanModeCell"
    }

    // UITableViewDataSource
    override func numberOfSectionsInTableView(tableView:UITableView!) -> Int {
        return 1
    }
    
    override func tableView(_:UITableView!, numberOfRowsInSection section:Int) -> Int {
        return 0
    }
    
    override func tableView(tableView: UITableView!, editingStyleForRowAtIndexPath indexPath: NSIndexPath!) -> UITableViewCellEditingStyle {
        return UITableViewCellEditingStyle.Delete
    }
    
    override func tableView(tableView:UITableView!, commitEditingStyle editingStyle:UITableViewCellEditingStyle, forRowAtIndexPath indexPath:NSIndexPath!) {
        if editingStyle == UITableViewCellEditingStyle.Delete {
            self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation:UITableViewRowAnimation.Fade)
        }
    }
    
    override func tableView(tableView: UITableView!, cellForRowAtIndexPath indexPath:NSIndexPath!) -> UITableViewCell! {
        let cell = tableView.dequeueReusableCellWithIdentifier(MainStoryboard.configureScanModeCell, forIndexPath: indexPath) as UITableViewCell
        return cell
    }
    
    // UITableViewDelegate
    override func tableView(tableView:UITableView!, didSelectRowAtIndexPath indexPath:NSIndexPath!) {
    }

}