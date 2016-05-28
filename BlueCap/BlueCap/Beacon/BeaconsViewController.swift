//
//  BeaconsViewController.swift
//  BlueCap
//
//  Created by Troy Stribling on 9/13/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import UIKit
import BlueCapKit

class BeaconsViewController: UITableViewController {

    var beaconRegion: FLBeaconRegion?

    struct MainStoryBoard {
        static let beaconCell   = "BeaconCell"
    }
    
    required init?(coder aDecoder:NSCoder) {
        super.init(coder:aDecoder)
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if let beaconRegion = self.beaconRegion {
            self.navigationItem.title = beaconRegion.identifier
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(BeaconsViewController.updateBeacons), name: BlueCapNotification.didUpdateBeacon, object: beaconRegion)
        } else {
            self.navigationItem.title = "Beacons"
        }
        NSNotificationCenter.defaultCenter().addObserver(self, selector:#selector(BeaconsViewController.didEnterBackground), name: UIApplicationDidEnterBackgroundNotification, object: nil)
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationItem.title = ""
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func prepareForSegue(segue:UIStoryboardSegue, sender: AnyObject!) {
    }

    func updateBeacons() {
        BCLogger.debug()
        self.tableView.reloadData()
    }
    
    func sortBeacons(beacons: [FLBeacon]) -> [FLBeacon] {
        return beacons.sort(){(b1: FLBeacon, b2: FLBeacon) -> Bool in
            if b1.major > b2.major {
                return true
            } else if b1.major == b2.major && b1.minor > b2.minor {
                return true
            } else {
                return false
            }
        }
    }
    
    func didEnterBackground() {
        BCLogger.debug()
        self.navigationController?.popToRootViewControllerAnimated(false)
    }
    
    // UITableViewDataSource
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let beaconRegion = self.beaconRegion {
            return beaconRegion.beacons.count
        } else {
            return 0
        }
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(MainStoryBoard.beaconCell, forIndexPath: indexPath) as! BeaconCell
        if let beaconRegion = self.beaconRegion {
            let beacon = self.sortBeacons(beaconRegion.beacons)[indexPath.row]
            cell.proximityUUIDLabel.text = beacon.proximityUUID.UUIDString
            cell.majorLabel.text = "\(beacon.major)"
            cell.minorLabel.text = "\(beacon.minor)"
            cell.proximityLabel.text = beacon.proximity.stringValue
            cell.rssiLabel.text = "\(beacon.rssi)"
            let accuracy = NSString(format:"%.4f", beacon.accuracy)
            cell.accuracyLabel.text = "\(accuracy)m"
        }
        return cell
    }

}
