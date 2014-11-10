//
//  ConfigureScanRegionsViewController.swift
//  BlueCap
//
//  Created by Troy Stribling on 8/30/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//
import UIKit
import BlueCapKit
import CoreLocation

class ConfigureScanRegionsViewController : UITableViewController {
    
    struct MainStoryboard {
        static let configureScanRegionsCell     = "ConfigureScanRegionsCell"
        static let configureAddScanRegionSegue  = "ConfigureAddScanRegion"
        static let configureScanRegionSegue     = "ConfigureScanRegion"
    }
    
    required init(coder aDecoder:NSCoder) {
        super.init(coder:aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationItem.title = "Scan Regions"
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationItem.title = ""
    }
    
    override func prepareForSegue(segue:UIStoryboardSegue, sender:AnyObject!) {
        if segue.identifier == MainStoryboard.configureScanRegionSegue {
            if let selectedIndexPath = self.tableView.indexPathForCell(sender as UITableViewCell) {
                let viewController = segue.destinationViewController as ConfigureScanRegionViewController
                viewController.regionName = ConfigStore.getScanRegionNames()[selectedIndexPath.row]
            }
        }
    }
    
    // UITableViewDataSource
    override func numberOfSectionsInTableView(tableView:UITableView) -> Int {
        return 1
    }
    
    override func tableView(_:UITableView, numberOfRowsInSection section:Int) -> Int {
        return ConfigStore.getScanRegionNames().count
    }
    
    override func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        return UITableViewCellEditingStyle.Delete
    }
    
    override func tableView(tableView:UITableView, commitEditingStyle editingStyle:UITableViewCellEditingStyle, forRowAtIndexPath indexPath:NSIndexPath) {
        if editingStyle == UITableViewCellEditingStyle.Delete {
            let regionName = ConfigStore.getScanRegionNames()[indexPath.row]
            ConfigStore.removeScanRegion(regionName)
            self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation:UITableViewRowAnimation.Fade)
        }
    }
    
    override func tableView(tableView:UITableView, cellForRowAtIndexPath indexPath:NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(MainStoryboard.configureScanRegionsCell, forIndexPath: indexPath) as SimpleCell
        cell.nameLabel.text = ConfigStore.getScanRegionNames()[indexPath.row]
        return cell
    }
    
    // UITableViewDelegate
    
}