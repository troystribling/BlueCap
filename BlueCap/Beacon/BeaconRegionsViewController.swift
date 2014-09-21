//
//  BeaconRegionsViewController.swift
//  BlueCap
//
//  Created by Troy Stribling on 9/16/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import UIKit
import BlueCapKit

class BeaconRegionsViewController: UITableViewController {

    var stopScanBarButtonItem   : UIBarButtonItem!
    var startScanBarButtonItem  : UIBarButtonItem!
    
    struct MainStoryBoard {
        static let beaconRegionCell         = "BeaconRegionCell"
        static let beaconsSegue             = "Beacons"
        static let beaconRegionAddSegue     = "BeaconRegionAdd"
        static let beaconRegionEditSegue    = "BeaconRegionEdit"
    }
    
    required init(coder aDecoder:NSCoder) {
        super.init(coder:aDecoder)
        self.stopScanBarButtonItem = UIBarButtonItem(barButtonSystemItem:.Stop, target:self, action:"toggleScan:")
        self.startScanBarButtonItem = UIBarButtonItem(barButtonSystemItem:.Refresh, target:self, action:"toggleScan:")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.tableView.reloadData()
        self.navigationItem.title = "Beacon Regions"
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationItem.title = ""
    }
    
    
    override func prepareForSegue(segue:UIStoryboardSegue, sender: AnyObject!) {
        if segue.identifier == MainStoryBoard.beaconsSegue {
        } else if segue.identifier == MainStoryBoard.beaconRegionAddSegue {
        } else if segue.identifier == MainStoryBoard.beaconRegionEditSegue {            
        }
    }
    
    @IBAction func toggleRanging(sender:AnyObject) {
        self.startRanging()
    }
    
    // UITableViewDataSource
    override func numberOfSectionsInTableView(tableView:UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return BeaconStore.getBeacons().count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(MainStoryBoard.beaconRegionCell, forIndexPath: indexPath) as BeaconRegionCell
        let name = BeaconStore.getBeaconNames()[indexPath.row]
        let beacons = BeaconStore.getBeacons()
        if let beacon = beacons[name] {
            cell.nameLabel.text = name
            cell.uuidLabel.text = beacon.UUIDString
        }
        return cell
    }
    
    override func tableView(tableView:UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    override func tableView(tableView:UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath:NSIndexPath) {
        if editingStyle == .Delete {
            let name = BeaconStore.getBeaconNames()[indexPath.row]
            BeaconStore.removeBeacon(name)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation:.Fade)
        }
    }
    
    func setScanButton() {
        if (CentralManager.sharedInstance().isScanning) {
            self.navigationItem.setRightBarButtonItem(self.stopScanBarButtonItem, animated:false)
        } else {
            self.navigationItem.setRightBarButtonItem(self.startScanBarButtonItem, animated:false)
        }
    }
    
    func startRanging() {
        for (name, uuid) in BeaconStore.getBeacons() {
            let beacon = BeaconRegion(proximityUUID:uuid, identifier:name) {(beaconRegion) in
                beaconRegion.startMonitoringRegion = {
                    BeaconManager.sharedInstance().startRangingBeaconsInRegion(beaconRegion)
                    self.presentViewController(UIAlertController.alertWithMessage("Started monitoring region \(name). Ranging beacons."), animated:true, completion:nil)
                }
                beaconRegion.enterRegion = {
                    self.presentViewController(UIAlertController.alertWithMessage("Did enter region \(name). Ranging beacons."), animated:true, completion:nil)
                }
                beaconRegion.exitRegion = {
                    BeaconManager.sharedInstance().stopRangingBeaconsInRegion(beaconRegion)
                    self.presentViewController(UIAlertController.alertWithMessage("Did exit region \(name). Stop ranging beacons."), animated:true, completion:nil)
                }
                beaconRegion.errorMonitoringRegion = {(error) in
                    BeaconManager.sharedInstance().stopRangingBeaconsInRegion(beaconRegion)
                    self.presentViewController(UIAlertController.alertOnError(error), animated:true, completion:nil)
                }
                beaconRegion.rangedBeacons = {(beacons) in
                    for beacon in beacons {
                        Logger.debug("major:\(beacon.major), minor: \(beacon.minor), rssi: \(beacon.rssi)")
                    }
                }
            }
            BeaconManager.sharedInstance().startMonitoringForRegion(beacon)
        }
    }
    
    // UITableViewDelegate
    override func tableView(tableView:UITableView, didSelectRowAtIndexPath indexPath:NSIndexPath) {
    }

}
