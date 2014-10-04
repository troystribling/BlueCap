//
//  PeripheralManagerAddAdvertisedServiceViewController.swift
//  BlueCap
//
//  Created by Troy Stribling on 10/2/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import UIKit
import BlueCapKit

class PeripheralManagerAddAdvertisedServiceViewController: UITableViewController {

    struct MainStoryboard {
        static let peripheralManagerAddAdverstisedServiceCell = "PeripheralManagerAddAdverstisedServiceCell"
    }
    
    var peripheral : String?

    var services : [MutableService] {
        if let peripheral = self.peripheral {
            let serviceUUIDs = PeripheralStore.getAdvertisedPeripheralServicesForPeripheral(peripheral)
            return PeripheralManager.sharedInstance().services.filter{!contains(serviceUUIDs, $0.uuid)}
        } else {
            return []
        }
    }
    

    required init(coder aDecoder:NSCoder) {
        super.init(coder:aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated:Bool) {
        super.viewWillAppear(animated)
        self.tableView.reloadData()
    }
    
    override func prepareForSegue(segue:UIStoryboardSegue, sender:AnyObject?) {
    }
    
    override func numberOfSectionsInTableView(tableView:UITableView) -> Int {
        return 1
    }
    
    override func tableView(_:UITableView, numberOfRowsInSection section:Int) -> Int {
        return self.services.count
    }
    
    override func tableView(tableView:UITableView, cellForRowAtIndexPath indexPath:NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(MainStoryboard.peripheralManagerAddAdverstisedServiceCell, forIndexPath:indexPath) as NameUUIDCell
        if let peripheral = self.peripheral {
            let service = self.services[indexPath.row]
            cell.nameLabel.text = service.name
            cell.uuidLabel.text = service.uuid.UUIDString
        } else {
            cell.nameLabel.text = "Unknown"
            cell.uuidLabel.text = "Unknown"
        }
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let peripheral = self.peripheral {
            let service = self.services[indexPath.row]
            PeripheralStore.addAdvertisedPeripheralService(peripheral, service:service.uuid)
        }
        self.navigationController?.popViewControllerAnimated(true)
    }
}
