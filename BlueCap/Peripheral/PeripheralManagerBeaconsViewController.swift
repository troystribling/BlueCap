//
//  PeripheralManagerBeaconsViewController.swift
//  BlueCap
//
//  Created by Troy Stribling on 9/28/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import UIKit

class PeripheralManagerBeaconsViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func performSegueWithIdentifier(identifier: String, sender: AnyObject?) {
    }
    
    override func numberOfSectionsInTableView(tableView:UITableView) -> Int {
        return 1
    }

    override func tableView(tableView:UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }

    override func tableView(tableView:UITableView, cellForRowAtIndexPath indexPath:NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("reuseIdentifier", forIndexPath: indexPath) as UITableViewCell
        return cell
    }

    override func tableView(tableView:UITableView, canEditRowAtIndexPath indexPath:NSIndexPath) -> Bool {
        return true
    }

    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        }
    }
}
