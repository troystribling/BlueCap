//
//  BeaconRegionsViewController.swift
//  BlueCap
//
//  Created by Troy Stribling on 9/16/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import UIKit
import BlueCapKit

class BeaconRegionsViewController: UITableViewController {

    var stopScanBarButtonItem: UIBarButtonItem!
    var startScanBarButtonItem: UIBarButtonItem!
    var beaconRegions = [String: FLBeaconRegion]()

    struct MainStoryBoard {
        static let beaconRegionCell = "BeaconRegionCell"
        static let beaconsSegue = "Beacons"
        static let beaconRegionAddSegue = "BeaconRegionAdd"
        static let beaconRegionEditSegue = "BeaconRegionEdit"
    }
    
    required init?(coder aDecoder:NSCoder) {
        super.init(coder:aDecoder)
        self.stopScanBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Stop, target: self, action: #selector(BeaconRegionsViewController.toggleMonitoring(_:)))
        self.startScanBarButtonItem = UIBarButtonItem(title: "Scan", style: UIBarButtonItemStyle.Plain, target: self, action: #selector(BeaconRegionsViewController.toggleMonitoring(_:)))
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
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(BeaconRegionsViewController.didBecomeActive), name: UIApplicationDidBecomeActiveNotification, object: nil)
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
        if !Singletons.centralManager.isScanning {
            if Singletons.beaconManager.isMonitoring {
                Singletons.beaconManager.stopRangingAllBeacons()
                Singletons.beaconManager.stopMonitoringAllRegions()
                self.beaconRegions.removeAll(keepCapacity:false)
                self.setScanButton()
            } else {
                self.startMonitoring()
            }
            self.tableView.reloadData()
        } else {
            self.presentViewController(UIAlertController.alertWithMessage("Central scan is active. Cannot scan and monitor simutaneously. Stop scan to start monitoring"), animated: true, completion: nil)
        }
    }
    
    func setScanButton() {
        if Singletons.beaconManager.isRanging {
            self.navigationItem.setLeftBarButtonItem(self.stopScanBarButtonItem, animated: false)
        } else {
            self.navigationItem.setLeftBarButtonItem(self.startScanBarButtonItem, animated: false)
        }
    }
    
    func startMonitoring() {
        for (name, uuid) in BeaconStore.getBeacons() {
            let beacon = FLBeaconRegion(proximityUUID: uuid, identifier: name)
            let regionFuture = Singletons.beaconManager.startMonitoringForRegion(beacon, authorization: .AuthorizedAlways)
            let beaconFuture = regionFuture.flatmap { status -> FutureStream<[FLBeacon]> in
                switch status {
                case .Inside:
                    if !Singletons.beaconManager.isRangingRegion(beacon.identifier) {
                        self.updateDisplay()
                        Notify.withMessage("Entering region '\(name)'. Started ranging beacons.")
                        return Singletons.beaconManager.startRangingBeaconsInRegion(beacon)
                    } else {
                        let errorPromise = StreamPromise<[FLBeacon]>()
                        errorPromise.failure(BCAppError.rangingBeacons)
                        return errorPromise.future
                    }
                case .Outside:
                    Singletons.beaconManager.stopRangingBeaconsInRegion(beacon)
                    self.updateWhenActive()
                    Notify.withMessage("Exited region '\(name)'. Stoped ranging beacons.")
                    let errorPromise = StreamPromise<[FLBeacon]>()
                    errorPromise.failure(BCAppError.outOfRegion)
                    return errorPromise.future
                case .Start:
                    BCLogger.debug("started monitoring region \(name)")
                    self.navigationItem.setLeftBarButtonItem(self.stopScanBarButtonItem, animated: false)
                    return Singletons.beaconManager.startRangingBeaconsInRegion(beacon)
                }
            }
            beaconFuture.onSuccess {beacons in
                self.setScanButton()
                for beacon in beacons {
                    BCLogger.debug("major:\(beacon.major), minor: \(beacon.minor), rssi: \(beacon.rssi)")
                }
                self.updateWhenActive()
                if UIApplication.sharedApplication().applicationState == .Active && beacons.count > 0 {
                    NSNotificationCenter.defaultCenter().postNotificationName(BlueCapNotification.didUpdateBeacon, object:beacon)
                }
            }
            regionFuture.onFailure {error in
                self.setScanButton()
                Singletons.beaconManager.stopRangingBeaconsInRegion(beacon)
                self.updateWhenActive()
                self.presentViewController(UIAlertController.alertOnError("Region Monitoring Error", error:error), animated:true, completion:nil)
            }
            self.beaconRegions[name] = beacon
        }
    }
    
    func updateDisplay() {
        if UIApplication.sharedApplication().applicationState == .Active {
            self.tableView.reloadData()
        }
    }

    func didBecomeActive() {
        BCLogger.debug()
        self.updateWhenActive()
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
        if Singletons.beaconManager.isRangingRegion(name) {
            if let region = Singletons.beaconManager.beaconRegion(name) {
                if region.beacons.count == 0 {
                    cell.statusLabel.text = "Monitoring"
                } else {
                    cell.nameLabel.textColor = UIColor.blackColor()
                    cell.beaconsLabel.text = "\(region.beacons.count)"
                    cell.statusLabel.text = "Ranging"
                    cell.statusLabel.textColor = UIColor(red: 0.1, green: 0.7, blue: 0.1, alpha: 0.5)
                }
            }
        } else if Singletons.centralManager.isScanning {
            cell.statusLabel.text = "Monitoring"
        } else {
            cell.statusLabel.text = "Idle"
        }
        return cell
    }
    
    override func tableView(tableView:UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        let name = BeaconStore.getBeaconNames()[indexPath.row]
        return !Singletons.beaconManager.isRangingRegion(name)
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
        if Singletons.beaconManager.isRangingRegion(name) {
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
