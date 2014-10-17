//
//  PeripheralManagerServicesViewController.swift
//  BlueCap
//
//  Created by Troy Stribling on 8/12/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import UIKit
import CoreBluetooth
import BlueCapKit

class PeripheralManagerServicesViewController : UITableViewController {
    
    var peripheral                      : String?
    var peripheralManagerViewController : PeripheralManagerViewController?
    
    struct MainStoryboard {
        static let peripheralManagerServiceCell                 = "PeripheralManagerServiceCell"
        static let peripheralManagerServiceProfilesSegue        = "PeripheralManagerServiceProfiles"
        static let peripheralManagerServiceCharacteristicsSegue = "PeripheralManagerServiceCharacteristics"
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder:aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated:Bool) {
        super.viewWillAppear(animated)
        self.navigationItem.title = "Services"
        if PeripheralManager.sharedInstance().isAdvertising {
            self.navigationItem.rightBarButtonItem!.enabled = false
        } else {
            self.navigationItem.rightBarButtonItem!.enabled = true
        }
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"didBecomeActive", name:BlueCapNotification.didBecomeActive, object:nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"didResignActive", name:BlueCapNotification.didResignActive, object:nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        self.navigationItem.title = ""
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func prepareForSegue(segue:UIStoryboardSegue, sender:AnyObject!) {
        if segue.identifier == MainStoryboard.peripheralManagerServiceProfilesSegue {
            let viewController = segue.destinationViewController as PeripheralManagerServiceProfilesViewController
            viewController.peripheral = self.peripheral
            if let peripheralManagerViewController = self.peripheralManagerViewController {
                viewController.peripheralManagerViewController = peripheralManagerViewController
            }
        } else if segue.identifier == MainStoryboard.peripheralManagerServiceCharacteristicsSegue {
            if let selectedIndexPath = self.tableView.indexPathForCell(sender as UITableViewCell) {
                let viewController = segue.destinationViewController as PeripheralManagerServiceCharacteristicsViewController
                viewController.service = PeripheralManager.sharedInstance().services[selectedIndexPath.row]
                if let peripheralManagerViewController = self.peripheralManagerViewController {
                    viewController.peripheralManagerViewController = peripheralManagerViewController
                }
            }
        }
    }
    
    func didResignActive() {
        Logger.debug("PeripheralManagerServicesViewController#didResignActive")
        if let peripheralManagerViewController = self.peripheralManagerViewController {
            self.navigationController?.popToViewController(peripheralManagerViewController, animated:false)
        }
    }
    
    func didBecomeActive() {
        Logger.debug("PeripheralManagerServicesViewController#didBecomeActive")
    }

    // UITableViewDataSource
    override func numberOfSectionsInTableView(tableView:UITableView) -> Int {
        return 1
    }
    
    override func tableView(_:UITableView, numberOfRowsInSection section:Int) -> Int {
        return PeripheralManager.sharedInstance().services.count
    }
    
    override func tableView(tableView:UITableView, cellForRowAtIndexPath indexPath:NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(MainStoryboard.peripheralManagerServiceCell, forIndexPath:indexPath) as NameUUIDCell
        let service = PeripheralManager.sharedInstance().services[indexPath.row]
        cell.nameLabel.text = service.name
        cell.uuidLabel.text = service.uuid.UUIDString
        return cell
    }
    
    override func tableView(tableView:UITableView, canEditRowAtIndexPath indexPath:NSIndexPath) -> Bool {
        return !PeripheralManager.sharedInstance().isAdvertising
    }
    
    override func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        return UITableViewCellEditingStyle.Delete
    }
    
    override func tableView(tableView:UITableView, commitEditingStyle editingStyle:UITableViewCellEditingStyle, forRowAtIndexPath indexPath:NSIndexPath) {
        if editingStyle == UITableViewCellEditingStyle.Delete {
            if let peripheral = self.peripheral {
                let manager = PeripheralManager.sharedInstance()
                let service = manager.services[indexPath.row]
                manager.removeService(service) {
                    PeripheralStore.removeAdvertisedPeripheralService(peripheral, service:service.uuid)
                    PeripheralStore.removePeripheralService(peripheral, service:service.uuid)
                    self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation:UITableViewRowAnimation.Fade)
                }
            }
        }
    }

    // UITableViewDelegate

}
