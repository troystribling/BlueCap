//
//  PeripheralManagersViewController.swift
//  BlueCap
//
//  Created by Troy Stribling on 8/10/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import UIKit
import BlueCapKit

class PeripheralManagersViewController : UITableViewController {
   
    struct MainStoryboard {
        static let peripheralManagerCell        = "PeripheralManagerCell"
        static let peripheralManagerViewSegue   = "PeripheralManagerView"
        static let peripheralManagerAddSegue    = "PeripheralManagerAdd"
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder:aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.styleNavigationBar()
        self.navigationItem.leftBarButtonItem = self.editButtonItem()
        self.navigationItem.leftBarButtonItem?.tintColor = UIColor.blackColor()
    }
    
    override func viewWillAppear(animated:Bool) {
        super.viewWillAppear(animated)
        self.tableView.reloadData()
        self.navigationItem.title = "Peripherals"
    }
    
    override func viewWillDisappear(animated:Bool) {
        super.viewWillDisappear(animated)
        self.navigationItem.title = ""
    }
    
    override func prepareForSegue(segue:UIStoryboardSegue, sender:AnyObject!) {
        if segue.identifier == MainStoryboard.peripheralManagerViewSegue {
            if let selectedIndex = self.tableView.indexPathForCell(sender as! UITableViewCell) {
                let viewController = segue.destinationViewController as! PeripheralManagerViewController
                let peripherals = PeripheralStore.getPeripheralNames()
                viewController.peripheral = peripherals[selectedIndex.row]
            }
        } else if segue.identifier == MainStoryboard.peripheralManagerAddSegue {
            let viewController = segue.destinationViewController as! PeripheralManagerViewController
            viewController.peripheral = nil
        }
    }
    
    // UITableViewDataSource
    override func numberOfSectionsInTableView(tableView:UITableView) -> Int {
        return 1
    }
    
    override func tableView(_:UITableView, numberOfRowsInSection section:Int) -> Int {
        return PeripheralStore.getPeripheralNames().count
    }
    
    override func tableView(tableView:UITableView, editingStyleForRowAtIndexPath indexPath:NSIndexPath) -> UITableViewCellEditingStyle {
        return UITableViewCellEditingStyle.Delete
    }
    
    override func tableView(tableView:UITableView, commitEditingStyle editingStyle:UITableViewCellEditingStyle, forRowAtIndexPath indexPath:NSIndexPath) {
        if editingStyle == UITableViewCellEditingStyle.Delete {
            let peripherals = PeripheralStore.getPeripheralNames()
            PeripheralStore.removePeripheral(peripherals[indexPath.row])
            self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation:UITableViewRowAnimation.Fade)
        }
    }
    
    override func tableView(tableView:UITableView, cellForRowAtIndexPath indexPath:NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(MainStoryboard.peripheralManagerCell, forIndexPath: indexPath) as! SimpleCell
        let peripherals = PeripheralStore.getPeripheralNames()
        cell.nameLabel.text = peripherals[indexPath.row]
        return cell
    }

    // UITableViewDelegate
    
}
