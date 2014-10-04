//
//  PeripheralManagerBeaconsViewController.swift
//  BlueCap
//
//  Created by Troy Stribling on 9/28/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import UIKit

class PeripheralManagerBeaconsViewController: UITableViewController {

    struct MainStoryboard {
        static let peripheralManagerBeaconCell      = "PeripheralManagerBeaconCell"
        static let peripheralManagerEditBeaconSegue = "PeripheralManagerEditBeacon"
        static let peripheralManagerAddBeaconSegue  = "PeripheralManagerAddBeacon"
    }
    
    var peripheral : String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.tableView.reloadData()
        self.navigationItem.title = "Beacons"
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationItem.title = ""
    }


    override func prepareForSegue(segue:UIStoryboardSegue, sender:AnyObject?) {
        if segue.identifier == MainStoryboard.peripheralManagerAddBeaconSegue {
        } else if segue.identifier == MainStoryboard.peripheralManagerEditBeaconSegue {
            if let selectedIndexPath = self.tableView.indexPathForCell(sender as UITableViewCell) {
                let viewController = segue.destinationViewController as PeripheralManagerBeaconViewController
                let beaconNames = PeripheralStore.getBeaconNames()
                viewController.beaconName = beaconNames[selectedIndexPath.row]
            }
        }
    }
    
    override func numberOfSectionsInTableView(tableView:UITableView) -> Int {
        return 1
    }

    override func tableView(tableView:UITableView, numberOfRowsInSection section: Int) -> Int {
        return PeripheralStore.getBeaconNames().count
    }

    override func tableView(tableView:UITableView, cellForRowAtIndexPath indexPath:NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(MainStoryboard.peripheralManagerBeaconCell, forIndexPath: indexPath) as NameUUIDCell
        let name = PeripheralStore.getBeaconNames()[indexPath.row]
        cell.nameLabel.text = name
        if let uuid = PeripheralStore.getBeacon(name) {
            cell.uuidLabel.text = uuid.UUIDString
        }
        return cell
    }

    override func tableView(tableView:UITableView, canEditRowAtIndexPath indexPath:NSIndexPath) -> Bool {
        return true
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath:NSIndexPath) {
        if let peripheral = self.peripheral {
            let beaconNames = PeripheralStore.getBeaconNames()
            PeripheralStore.setAdvertisedBeaconConfig(peripheral, beacon:beaconNames[indexPath.row])
            self.navigationController?.popViewControllerAnimated(true)
        }
    }
    
    override func tableView(tableView:UITableView, commitEditingStyle editingStyle:UITableViewCellEditingStyle, forRowAtIndexPath indexPath:NSIndexPath) {
        if editingStyle == .Delete {
            let beaconNames = PeripheralStore.getBeaconNames()
            PeripheralStore.removeBeacon(beaconNames[indexPath.row])
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        }
    }
}
