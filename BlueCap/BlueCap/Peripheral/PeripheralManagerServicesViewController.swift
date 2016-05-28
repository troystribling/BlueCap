//
//  PeripheralManagerServicesViewController.swift
//  BlueCap
//
//  Created by Troy Stribling on 8/12/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
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
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder:aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated:Bool) {
        super.viewWillAppear(animated)
        self.navigationItem.title = "Services"
        self.tableView.reloadData()
        if Singletons.peripheralManager.isAdvertising {
            self.navigationItem.rightBarButtonItem!.enabled = false
        } else {
            self.navigationItem.rightBarButtonItem!.enabled = true
        }
        NSNotificationCenter.defaultCenter().addObserver(self, selector:#selector(PeripheralManagerServicesViewController.didEnterBackground), name: UIApplicationDidEnterBackgroundNotification, object:nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        self.navigationItem.title = ""
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func prepareForSegue(segue:UIStoryboardSegue, sender:AnyObject!) {
        if segue.identifier == MainStoryboard.peripheralManagerServiceProfilesSegue {
            let viewController = segue.destinationViewController as! PeripheralManagerServiceProfilesViewController
            viewController.peripheral = self.peripheral
            if let peripheralManagerViewController = self.peripheralManagerViewController {
                viewController.peripheralManagerViewController = peripheralManagerViewController
            }
        } else if segue.identifier == MainStoryboard.peripheralManagerServiceCharacteristicsSegue {
            if let selectedIndexPath = self.tableView.indexPathForCell(sender as! UITableViewCell) {
                let viewController = segue.destinationViewController as! PeripheralManagerServiceCharacteristicsViewController
                viewController.service = Singletons.peripheralManager.services[selectedIndexPath.row]
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
    
    // UITableViewDataSource
    override func numberOfSectionsInTableView(tableView:UITableView) -> Int {
        return 1
    }
    
    override func tableView(_:UITableView, numberOfRowsInSection section:Int) -> Int {
        return Singletons.peripheralManager.services.count
    }
    
    override func tableView(tableView:UITableView, cellForRowAtIndexPath indexPath:NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(MainStoryboard.peripheralManagerServiceCell, forIndexPath:indexPath) as! NameUUIDCell
        let service = Singletons.peripheralManager.services[indexPath.row]
        cell.nameLabel.text = service.name
        cell.uuidLabel.text = service.UUID.UUIDString
        return cell
    }
    
    override func tableView(tableView:UITableView, canEditRowAtIndexPath indexPath:NSIndexPath) -> Bool {
        return !Singletons.peripheralManager.isAdvertising
    }
    
    override func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        return UITableViewCellEditingStyle.Delete
    }
    
    override func tableView(tableView:UITableView, commitEditingStyle editingStyle:UITableViewCellEditingStyle, forRowAtIndexPath indexPath:NSIndexPath) {
        if editingStyle == UITableViewCellEditingStyle.Delete {
            if let peripheral = self.peripheral {
                let service = Singletons.peripheralManager.services[indexPath.row]
                Singletons.peripheralManager.removeService(service)
                PeripheralStore.removeAdvertisedPeripheralService(peripheral, service: service.UUID)
                PeripheralStore.removePeripheralService(peripheral, service: service.UUID)
                self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Fade)
            }
        }
    }

    // UITableViewDelegate

}
