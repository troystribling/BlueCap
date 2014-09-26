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

    var beaconRegion    : String?
    var beacons         = [Beacon]()

    struct MainStoryBoard {
        static let beaconCell   = "BeaconCell"
    }
    
    required init(coder aDecoder:NSCoder) {
        super.init(coder:aDecoder)
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if let beaconRegion = self.beaconRegion {
            self.navigationItem.title = beaconRegion
        } else {
            self.navigationItem.title = "Beacons"
        }
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationItem.title = ""
    }
    
    override func prepareForSegue(segue:UIStoryboardSegue, sender: AnyObject!) {
    }

    func updateBeacons(beacons:[Beacon]) {
        self.beacons = beacons
        self.tableView.reloadData()
    }
    
    // UITableViewDataSource
    override func numberOfSectionsInTableView(tableView:UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.beacons.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(MainStoryBoard.beaconCell, forIndexPath: indexPath) as BeaconCell
        let beacon = self.beacons[indexPath.row]
        if let uuid = beacon.proximityUUID {
            cell.proximityUUIDLabel.text = uuid.UUIDString
        } else {
            cell.proximityUUIDLabel.text = "Unknown"
        }
        if let major = beacon.major {
            cell.majorLabel.text = "\(major)"
        } else {
            cell.majorLabel.text = "0"
        }
        if let minor = beacon.minor {
            cell.minorLabel.text = "\(minor)"
        } else {
            cell.minorLabel.text = "0"
        }
//        cell.proximityLabel.text = beacon.proximity.stringValue
        return cell
    }

}
