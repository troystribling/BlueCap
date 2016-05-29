//
//  PeripheralManagerBeaconsViewController.swift
//  BlueCap
//
//  Created by Troy Stribling on 9/28/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import UIKit
import BlueCapKit

class PeripheralManagerBeaconsViewController: UITableViewController {

    struct MainStoryboard {
        static let peripheralManagerBeaconCell      = "PeripheralManagerBeaconCell"
        static let peripheralManagerEditBeaconSegue = "PeripheralManagerEditBeacon"
        static let peripheralManagerAddBeaconSegue  = "PeripheralManagerAddBeacon"
    }
    
    var peripheral                      : String?
    var peripheralManagerViewController : PeripheralManagerViewController?

    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.tableView.reloadData()
        self.navigationItem.title = "Beacons"
        NSNotificationCenter.defaultCenter().addObserver(self, selector:#selector(PeripheralManagerBeaconsViewController.didEnterBackground), name: UIApplicationDidEnterBackgroundNotification, object:nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationItem.title = ""
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }


    override func prepareForSegue(segue:UIStoryboardSegue, sender:AnyObject?) {
        if segue.identifier == MainStoryboard.peripheralManagerAddBeaconSegue {
        } else if segue.identifier == MainStoryboard.peripheralManagerEditBeaconSegue {
            if let selectedIndexPath = self.tableView.indexPathForCell(sender as! UITableViewCell) {
                let viewController = segue.destinationViewController as! PeripheralManagerBeaconViewController
                let beaconNames = PeripheralStore.getBeaconNames()
                viewController.beaconName = beaconNames[selectedIndexPath.row]
                if let peripheralManagerViewController = self.peripheralManagerViewController {
                    viewController.peripheralManagerViewController = peripheralManagerViewController
                }
            }
        }
    }
    
    func didEnterBackground() {
        BCLogger.debug()
        if let peripheralManagerViewController = self.peripheralManagerViewController {
            self.navigationController?.popToViewController(peripheralManagerViewController, animated:false)
        }
    }
    
    override func numberOfSectionsInTableView(tableView:UITableView) -> Int {
        return 1
    }

    override func tableView(tableView:UITableView, numberOfRowsInSection section: Int) -> Int {
        return PeripheralStore.getBeaconNames().count
    }

    override func tableView(tableView:UITableView, cellForRowAtIndexPath indexPath:NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(MainStoryboard.peripheralManagerBeaconCell, forIndexPath: indexPath) as! PeripheralManagerBeaconCell
        let name = PeripheralStore.getBeaconNames()[indexPath.row]
        cell.nameLabel.text = name
        if let uuid = PeripheralStore.getBeacon(name) {
            let beaconConfig = PeripheralStore.getBeaconConfig(name)
            cell.uuidLabel.text = uuid.UUIDString
            cell.majorLabel.text = "\(beaconConfig[1])"
            cell.minorLabel.text = "\(beaconConfig[0])"
            cell.accessoryType = .None
            if let peripheral = self.peripheral {
                if let advertisedBeacon = PeripheralStore.getAdvertisedBeacon(peripheral) {
                    if advertisedBeacon == name {
                        cell.accessoryType = .Checkmark
                    }
                }
            }
        }
        return cell
    }

    override func tableView(tableView:UITableView, canEditRowAtIndexPath indexPath:NSIndexPath) -> Bool {
        return true
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath:NSIndexPath) {
        if let peripheral = self.peripheral {
            let beaconNames = PeripheralStore.getBeaconNames()
            PeripheralStore.setAdvertisedBeacon(peripheral, beacon:beaconNames[indexPath.row])
            self.navigationController?.popViewControllerAnimated(true)
        }
    }
    
    override func tableView(tableView:UITableView, commitEditingStyle editingStyle:UITableViewCellEditingStyle, forRowAtIndexPath indexPath:NSIndexPath) {
        if editingStyle == .Delete {
            let beaconNames = PeripheralStore.getBeaconNames()
            PeripheralStore.removeBeacon(beaconNames[indexPath.row])
            if let peripheral = self.peripheral {
                PeripheralStore.removeAdvertisedBeacon(peripheral)
                PeripheralStore.removeBeaconEnabled(peripheral)
            }
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation:.Fade)
        }
    }
}
