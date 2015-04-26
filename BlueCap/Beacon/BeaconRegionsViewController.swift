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
    var beaconRegions           = [String:BeaconRegion]()

    struct MainStoryBoard {
        static let beaconRegionCell         = "BeaconRegionCell"
        static let beaconsSegue             = "Beacons"
        static let beaconRegionAddSegue     = "BeaconRegionAdd"
        static let beaconRegionEditSegue    = "BeaconRegionEdit"
    }
    
    required init(coder aDecoder:NSCoder) {
        super.init(coder:aDecoder)
        self.stopScanBarButtonItem = UIBarButtonItem(barButtonSystemItem:.Stop, target:self, action:"toggleMonitoring:")
        self.startScanBarButtonItem = UIBarButtonItem(title:"Scan", style:UIBarButtonItemStyle.Plain, target:self, action:"toggleMonitoring:")
        self.styleUIBarButton(self.startScanBarButtonItem)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.styleNavigationBar()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.tableView.reloadData()
        self.navigationItem.title = "Beacon Regions"
        self.setScanButton()
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"didBecomeActive", name:BlueCapNotification.didBecomeActive, object:nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"didResignActive", name:BlueCapNotification.didResignActive, object:nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self)
        self.navigationItem.title = ""
    }
    
    
    override func prepareForSegue(segue:UIStoryboardSegue, sender:AnyObject!) {
        if segue.identifier == MainStoryBoard.beaconsSegue {
            let selectedIndexPath = sender as! NSIndexPath
            let beaconsViewController = segue.destinationViewController as! BeaconsViewController
            let beaconName = BeaconStore.getBeaconNames()[selectedIndexPath.row]
            if let beaconRegion = self.beaconRegions[beaconName] {
                beaconsViewController.beaconRegion = beaconRegion
            }
        } else if segue.identifier == MainStoryBoard.beaconRegionAddSegue {
        } else if segue.identifier == MainStoryBoard.beaconRegionEditSegue {
            let selectedIndexPath = sender as! NSIndexPath
            let viewController = segue.destinationViewController as! BeaconRegionViewController
            viewController.regionName = BeaconStore.getBeaconNames()[selectedIndexPath.row]
        }
    }
    
    func toggleMonitoring(sender:AnyObject) {
        if CentralManager.sharedInstance.isScanning == false {
            let beaconManager = BeaconManager.sharedInstance
            if beaconManager.isRanging {
                beaconManager.stopRangingAllBeacons()
                beaconManager.stopMonitoringAllRegions()
                self.beaconRegions.removeAll(keepCapacity:false)
                self.setScanButton()
            } else {
                self.startMonitoring()
            }
            self.tableView.reloadData()
        } else {
            self.presentViewController(UIAlertController.alertWithMessage("Central scan is active. Cannot scan and monitor simutaneously. Stop scan to start monitoring"), animated:true, completion:nil)
        }
    }
    
    func setScanButton() {
        if BeaconManager.sharedInstance.isRanging {
            self.navigationItem.setLeftBarButtonItem(self.stopScanBarButtonItem, animated:false)
        } else {
            self.navigationItem.setLeftBarButtonItem(self.startScanBarButtonItem, animated:false)
        }
    }
    
    func startMonitoring() {
        for (name, uuid) in BeaconStore.getBeacons() {
            let beacon = BeaconRegion(proximityUUID:uuid, identifier:name)
            let regionFuture = BeaconManager.sharedInstance.startMonitoringForRegion(beacon)
            let beaconFuture = regionFuture.flatmap {status -> FutureStream<[Beacon]> in
                switch status {
                case .Inside:
                    let beaconManager = BeaconManager.sharedInstance
                    if !beaconManager.isRangingRegion(beacon.identifier) {
                        self.updateDisplay()
                        Notify.withMessage("Entering region '\(name)'. Started ranging beacons.")
                        return beaconManager.startRangingBeaconsInRegion(beacon)
                    } else {
                        let errorPromise = StreamPromise<[Beacon]>()
                        errorPromise.failure(BCAppError.rangingBeacons)
                        return errorPromise.future
                    }
                case .Outside:
                    BeaconManager.sharedInstance.stopRangingBeaconsInRegion(beacon)
                    self.updateWhenActive()
                    Notify.withMessage("Exited region '\(name)'. Stoped ranging beacons.")
                    let errorPromise = StreamPromise<[Beacon]>()
                    errorPromise.failure(BCAppError.outOfRegion)
                    return errorPromise.future
                case .Start:
                    Logger.debug(message:"started monitoring region \(name)")
                    self.navigationItem.setLeftBarButtonItem(self.stopScanBarButtonItem, animated:false)
                    return BeaconManager.sharedInstance.startRangingBeaconsInRegion(beacon)
                }
            }
            beaconFuture.onSuccess {beacons in
                self.setScanButton()
                for beacon in beacons {
                    Logger.debug(message:"major:\(beacon.major), minor: \(beacon.minor), rssi: \(beacon.rssi)")
                }
                self.updateWhenActive()
                if UIApplication.sharedApplication().applicationState == .Active && beacons.count > 0 {
                    NSNotificationCenter.defaultCenter().postNotificationName(BlueCapNotification.didUpdateBeacon, object:beacon)
                }
            }
            regionFuture.onFailure {error in
                self.setScanButton()
                BeaconManager.sharedInstance.stopRangingBeaconsInRegion(beacon)
                self.updateWhenActive()
                self.presentViewController(UIAlertController.alertOnError(error), animated:true, completion:nil)
            }
            self.beaconRegions[name] = beacon
        }
    }
    
    func updateDisplay() {
        if UIApplication.sharedApplication().applicationState == .Active {
            self.tableView.reloadData()
        }
    }

    func didResignActive() {
        Logger.debug()
    }
    
    func didBecomeActive() {
        Logger.debug()
        self.tableView.reloadData()
    }

    // UITableViewDataSource
    override func numberOfSectionsInTableView(tableView:UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return BeaconStore.getBeacons().count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(MainStoryBoard.beaconRegionCell, forIndexPath: indexPath) as! BeaconRegionCell
        let name = BeaconStore.getBeaconNames()[indexPath.row]
        let beaconRegions = BeaconStore.getBeacons()
        if let beaconRegionUUID = beaconRegions[name] {
            cell.nameLabel.text = name
            cell.uuidLabel.text = beaconRegionUUID.UUIDString
        }
        cell.nameLabel.textColor = UIColor.blackColor()
        cell.beaconsLabel.text = "0"
        cell.nameLabel.textColor = UIColor.lightGrayColor()
        cell.statusLabel.textColor = UIColor.lightGrayColor()
        if BeaconManager.sharedInstance.isRangingRegion(name) {
            if let region = BeaconManager.sharedInstance.beaconRegion(name) {
                if region.beacons.count == 0 {
                    cell.statusLabel.text = "Monitoring"
                } else {
                    cell.nameLabel.textColor = UIColor.blackColor()
                    cell.beaconsLabel.text = "\(region.beacons.count)"
                    cell.statusLabel.text = "Ranging"
                    cell.statusLabel.textColor = UIColor(red:0.1, green:0.7, blue:0.1, alpha:0.5)
                }
            }
        } else if CentralManager.sharedInstance.isScanning {
            cell.statusLabel.text = "Monitoring"
        } else {
            cell.statusLabel.text = "Idle"
        }
        return cell
    }
    
    override func tableView(tableView:UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        let name = BeaconStore.getBeaconNames()[indexPath.row]
        return !BeaconManager.sharedInstance.isRangingRegion(name)
    }
    
    override func tableView(tableView:UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath:NSIndexPath) {
        if editingStyle == .Delete {
            let name = BeaconStore.getBeaconNames()[indexPath.row]
            BeaconStore.removeBeacon(name)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation:.Fade)
        }
    }
    
    // UITableViewDelegate
    override func tableView(tableView:UITableView, didSelectRowAtIndexPath indexPath:NSIndexPath) {
        let name = BeaconStore.getBeaconNames()[indexPath.row]
        if BeaconManager.sharedInstance.isRangingRegion(name) {
            if let beaconRegion = self.beaconRegions[name] {
                if beaconRegion.beacons.count > 0 {
                    self.performSegueWithIdentifier(MainStoryBoard.beaconsSegue, sender:indexPath)
                }
            }
        } else {
            self.performSegueWithIdentifier(MainStoryBoard.beaconRegionEditSegue, sender:indexPath)
        }
    }
    
}
