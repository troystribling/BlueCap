//
//  BeaconsViewController.swift
//  BlueCap
//
//  Created by Troy Stribling on 9/13/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import UIKit
import BlueCapKit

class BeaconsViewController: UITableViewController {

    var stopScanBarButtonItem   : UIBarButtonItem!
    var startScanBarButtonItem  : UIBarButtonItem!

    struct MainStoryBoard {
        static let beaconCell = "BeaconCell"
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
        self.navigationItem.title = "Beacons"
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationItem.title = ""
    }
    
    @IBAction func toggleScan(sender:AnyObject) {
        self.startMonitoring()
    }
    
    override func prepareForSegue(segue:UIStoryboardSegue, sender: AnyObject!) {
    }

    override func numberOfSectionsInTableView(tableView:UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(MainStoryBoard.beaconCell, forIndexPath: indexPath) as UITableViewCell
        return cell
    }

    override func tableView(tableView:UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }

    override func tableView(tableView:UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath:NSIndexPath) {
        if editingStyle == .Delete {
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
    
    func startMonitoring() {
        let uuids = ["estimote":"B9407F30-F5F8-466E-AFF9-25556B57FE6D"]
        for (name, uuid) in uuids {
            let nsuuid = NSUUID(UUIDString:uuid)
            let beacon = BeaconMonitor(proximityUUID:nsuuid, identifier:name) {(beaconMonitor) in
                beaconMonitor.startMonitoringRegion = {
                    BeaconManager.sharedInstance().startRangingBeaconsInRegion(beaconMonitor)
                }
                beaconMonitor.rangedBeacons = {(beacons) in
                    for beacon in beacons {
                        Logger.debug("major:\(beacon.major), minor: \(beacon.minor), rssi: \(beacon.rssi)")
                    }
                }
            }
            BeaconManager.sharedInstance().startMonitoringForRegion(beacon)
        }
    }

}
