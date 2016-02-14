//
//  PeripheralServicesViewController.swift
//  BlueCap
//
//  Created by Troy Stribling on 6/22/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import UIKit
import BlueCapKit

class PeripheralServicesViewController : UITableViewController {
    
    weak var peripheral: BCPeripheral!
    var peripheralViewController: PeripheralViewController!
    var progressView  = ProgressView()
    
    struct MainStoryboard {
        static let peripheralServiceCell            = "PeripheralServiceCell"
        static let peripheralServicesCharacteritics = "PeripheralServicesCharacteritics"
    }
    
    required init?(coder aDecoder:NSCoder) {
        super.init(coder:aDecoder)
    }
    
    override func viewDidLoad()  {
        super.viewDidLoad()
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.updateWhenActive()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "peripheralDisconnected", name: BlueCapNotification.peripheralDisconnected, object: self.peripheral!)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "didBecomeActive", name: BlueCapNotification.didBecomeActive, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "didResignActive", name: BlueCapNotification.didResignActive, object: nil)
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        if segue.identifier == MainStoryboard.peripheralServicesCharacteritics {
            if let peripheral = self.peripheral {
                if let selectedIndex = self.tableView.indexPathForCell(sender as! UITableViewCell) {
                    let viewController = segue.destinationViewController as! PeripheralServiceCharacteristicsViewController
                    viewController.service = peripheral.services[selectedIndex.row]
                    viewController.peripheralViewController = self.peripheralViewController

                }
            }
        }
    }
    
    override func shouldPerformSegueWithIdentifier(identifier:String?, sender:AnyObject?) -> Bool {
        return true
    }
    
    func peripheralDisconnected() {
        BCLogger.debug()
        if self.peripheralViewController.peripehealConnected {
            self.presentViewController(UIAlertController.alertWithMessage("Peripheral disconnected"), animated:true, completion:nil)
            self.peripheralViewController.peripehealConnected = false
            self.updateWhenActive()
        }
    }

    func didResignActive() {
        BCLogger.debug()
        self.navigationController?.popToRootViewControllerAnimated(false)
    }
    
    func didBecomeActive() {
        BCLogger.debug()
    }

    // UITableViewDataSource
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let peripheral = self.peripheral {
            return peripheral.services.count
        } else {
            return 0;
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(MainStoryboard.peripheralServiceCell, forIndexPath: indexPath) as! NameUUIDCell
        let service = peripheral.services[indexPath.row]
        cell.nameLabel.text = service.name
        cell.uuidLabel.text = service.uuid.UUIDString
        if let peripheralViewController = self.peripheralViewController {
            if peripheralViewController.peripehealConnected {
                cell.nameLabel.textColor = UIColor.blackColor()
            } else {
                cell.nameLabel.textColor = UIColor.lightGrayColor()
            }
        } else {
            cell.nameLabel.textColor = UIColor.blackColor()
        }
        return cell
    }
    
    
    // UITableViewDelegate
    
}
