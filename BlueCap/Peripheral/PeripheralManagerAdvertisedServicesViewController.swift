//
//  PeripheralManagerAdvertisedServicesViewController.swift
//  BlueCap
//
//  Created by Troy Stribling on 10/2/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import UIKit
import BlueCapKit

class PeripheralManagerAdvertisedServicesViewController: UITableViewController {

    struct MainStoryboard {
        static let peripheralManagerAddAdvertisedServiceSegue   = "PeripheralManagerAddAdvertisedService"
        static let peripheralManagerAdvertisedServiceCell       = "PeripheralManagerAdvertisedServiceCell"
    }
    
    var peripheral : String?
    
    required init(coder aDecoder:NSCoder) {
        super.init(coder:aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationItem.title = "Advertised Services"
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationItem.title = ""
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == MainStoryboard.peripheralManagerAddAdvertisedServiceSegue {
            let viewController = segue.destinationViewController as PeripheralManagerAddAdvertisedServiceViewController
            viewController.peripheral = self.peripheral
        }
    }
    
    override func numberOfSectionsInTableView(tableView:UITableView) -> Int {
        return 1
    }

    override func tableView(tableView:UITableView, numberOfRowsInSection section:Int) -> Int {
        if let peripheral = self.peripheral {
            return PeripheralStore.getAdvertisedPeripheralServicesForPeripheral(peripheral).count
        } else {
            return 0
        }
    }

    override func tableView(tableView:UITableView, cellForRowAtIndexPath indexPath:NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(MainStoryboard.peripheralManagerAdvertisedServiceCell, forIndexPath: indexPath) as NameUUIDCell
        if let peripheral = self.peripheral {
            let serviceUUIDs = PeripheralStore.getAdvertisedPeripheralServicesForPeripheral(peripheral)
            let service = PeripheralManager.sharedInstance().services[indexPath.row]
            cell.uuidLabel.text = serviceUUIDs[indexPath.row].UUIDString
            cell.nameLabel.text = service.name
        } else {
            cell.uuidLabel.text = "Unknown"
            cell.nameLabel.text = "Unknown"
        }
        return cell
    }

    override func tableView(tableView:UITableView, canEditRowAtIndexPath indexPath:NSIndexPath) -> Bool {
        return true
    }

    override func tableView(tableView:UITableView, commitEditingStyle editingStyle:UITableViewCellEditingStyle, forRowAtIndexPath indexPath:NSIndexPath) {
        if editingStyle == .Delete {
            if let peripheral = self.peripheral {
                let serviceUUIDs = PeripheralStore.getAdvertisedPeripheralServicesForPeripheral(peripheral)
                PeripheralStore.removeAdvertisedPeripheralService(peripheral, service:serviceUUIDs[indexPath.row])
                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation:.Fade)
            }
        }
    }

}
