//
//  PeripheralServicesViewController.swift
//  BlueCap
//
//  Created by Troy Stribling on 6/22/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import UIKit
import BlueCapKit
import CoreBluetooth


class PeripheralServicesViewController : UITableViewController {

    private static var BCPeripheralStateKVOContext = UInt8()

    weak var peripheral: BCPeripheral!
    var peripheralViewController: PeripheralViewController!
    var progressView  = ProgressView()
    
    struct MainStoryboard {
        static let peripheralServiceCell = "PeripheralServiceCell"
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
        let options = NSKeyValueObservingOptions([.New])
        self.peripheral?.addObserver(self, forKeyPath: "state", options: options, context: &PeripheralServicesViewController.BCPeripheralStateKVOContext)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(PeripheralServicesViewController.didEnterBackground), name: UIApplicationDidEnterBackgroundNotification, object: nil)
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        self.peripheral?.removeObserver(self, forKeyPath: "state", context: &PeripheralServicesViewController.BCPeripheralStateKVOContext)
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
        if self.peripheralViewController.peripheralConnected {
            self.presentViewController(UIAlertController.alertWithMessage("Peripheral disconnected"), animated:true, completion:nil)
            self.peripheralViewController.peripheralConnected = false
            self.updateWhenActive()
        }
    }

    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String: AnyObject]?, context: UnsafeMutablePointer<Void>) {
        guard keyPath != nil else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
            return
        }
        switch (keyPath!, context) {
        case("state", &PeripheralServicesViewController.BCPeripheralStateKVOContext):
            if let change = change, newValue = change[NSKeyValueChangeNewKey], newRawState = newValue as? Int, newState = CBPeripheralState(rawValue: newRawState) {
                if newState == .Disconnected {
                    dispatch_async(dispatch_get_main_queue()) { self.peripheralDisconnected() }
                }
            }
        default:
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
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
        cell.uuidLabel.text = service.UUID.UUIDString
        if let peripheralViewController = self.peripheralViewController {
            if peripheralViewController.peripheralConnected {
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
