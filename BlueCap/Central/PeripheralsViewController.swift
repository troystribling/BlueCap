//
//  PeripheralsViewController.swift
//  BlueCapUI
//
//  Created by Troy Stribling on 6/5/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import UIKit
import CoreBluetooth
import BlueCapKit

class PeripheralsViewController : UITableViewController {
    
    var stopScanBarButtonItem: UIBarButtonItem!
    var startScanBarButtonItem: UIBarButtonItem!

    struct MainStoryboard {
        static let peripheralCell   = "PeripheralCell"
        static let peripheralSegue  = "Peripheral"
    }
    
    required init?(coder aDecoder:NSCoder) {
        super.init(coder:aDecoder)
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.Plain, target:nil, action:nil)
        self.stopScanBarButtonItem = UIBarButtonItem(barButtonSystemItem:.Stop, target:self, action:"toggleScan:")
        self.startScanBarButtonItem = UIBarButtonItem(title:"Scan", style:UIBarButtonItemStyle.Plain, target:self, action:"toggleScan:")
        self.styleUIBarButton(self.startScanBarButtonItem)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.styleNavigationBar()
        self.setScanButton()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"didBecomeActive", name:BlueCapNotification.didBecomeActive, object:nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"didResignActive", name:BlueCapNotification.didResignActive, object:nil)
        self.setScanButton()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func prepareForSegue(segue:UIStoryboardSegue, sender:AnyObject!) {
        if segue.identifier == MainStoryboard.peripheralSegue {
            if let selectedIndex = self.tableView.indexPathForCell(sender as! UITableViewCell) {
                let viewController = segue.destinationViewController as! PeripheralViewController
                viewController.peripheral = Singletons.centralManager.peripherals[selectedIndex.row]
            }
        }
    }
    
    override func shouldPerformSegueWithIdentifier(identifier:String?, sender:AnyObject?) -> Bool {
        var perform = false
        if let identifier = identifier {
            if identifier == MainStoryboard.peripheralSegue {
                if let selectedIndex = self.tableView.indexPathForCell(sender as! UITableViewCell) {
                    let peripheral = Singletons.centralManager.peripherals[selectedIndex.row]
                    perform = (peripheral.state == .Connected)
                }
            }
        }
        return perform
    }
    
    // actions
    func toggleScan(sender:AnyObject) {
        if Singletons.beaconManager.isMonitoring == false {
            BCLogger.debug("isScanning: \(Singletons.centralManager.isScanning)")
            if Singletons.centralManager.isScanning {
                if  ConfigStore.getScanTimeoutEnabled() {
                    Singletons.timedScannerator.stopScanning()
                } else {
                    Singletons.centralManager.stopScanning()
                }
                Singletons.centralManager.disconnectAllPeripherals()
                Singletons.centralManager.removeAllPeripherals()
                self.setScanButton()
                self.updateWhenActive()
            } else {
                Singletons.centralManager.disconnectAllPeripherals()
                Singletons.centralManager.removeAllPeripherals()
                self.powerOn()
            }
        } else {
            self.presentViewController(UIAlertController.alertWithMessage("iBeacon monitoring is active. Cannot scan and monitor iBeacons simutaneously. Stop iBeacon monitoring to start scan"), animated:true, completion:nil)
        }
    }
    
    // utils
    func didResignActive() {
        BCLogger.debug()
    }
    
    func didBecomeActive() {
        BCLogger.debug()
        self.tableView.reloadData()
        self.setScanButton()
    }
    
    func setScanButton() {
        if Singletons.centralManager.isScanning || Singletons.timedScannerator.isScanning {
            self.navigationItem.setLeftBarButtonItem(self.stopScanBarButtonItem, animated:false)
        } else {
            self.navigationItem.setLeftBarButtonItem(self.startScanBarButtonItem, animated:false)
        }
    }
    
    func powerOn() {
        Singletons.centralManager.whenPowerOn().onSuccess {
            BCLogger.debug()
            self.startScan()
            self.setScanButton()
        }
    }
    
    func connect(peripheral: BCPeripheral) {
        let future = peripheral.connect(10, timeoutRetries:ConfigStore.getMaximumReconnections(), connectionTimeout: Double(ConfigStore.getPeripheralConnectionTimeout()))
        future.onSuccess {(peripheral, connectionEvent) in
            switch connectionEvent {
            case .Connect:
                BCLogger.debug("Connected")
                Notify.withMessage("Connected peripheral: '\(peripheral.name)'")
                self.updateWhenActive()
            case .Timeout:
                BCLogger.debug("Timeout: '\(peripheral.name)'")
                NSNotificationCenter.defaultCenter().postNotificationName(BlueCapNotification.peripheralDisconnected, object:peripheral)
                peripheral.reconnect()
                self.updateWhenActive()
            case .Disconnect:
                BCLogger.debug("Disconnect")
                Notify.withMessage("Disconnected peripheral: '\(peripheral.name)'")
                peripheral.reconnect()
                NSNotificationCenter.defaultCenter().postNotificationName(BlueCapNotification.peripheralDisconnected, object:peripheral)
                self.updateWhenActive()
            case .ForceDisconnect:
                BCLogger.debug("ForcedDisconnect")
                Notify.withMessage("Force disconnection of: '\(peripheral.name)'")
                NSNotificationCenter.defaultCenter().postNotificationName(BlueCapNotification.peripheralDisconnected, object:peripheral)
                self.updateWhenActive()
            case .Failed:
                BCLogger.debug("Failed")
                Notify.withMessage("Connection failed peripheral: '\(peripheral.name)'")
            case .GiveUp:
                BCLogger.debug("GiveUp: '\(peripheral.name)'")
                peripheral.terminate()
                self.updateWhenActive()
            }
        }
        future.onFailure {error in
            self.updateWhenActive()
        }
    }
    
    func startScan() {
        let scanMode = ConfigStore.getScanMode()
        let afterPeripheralDiscovered = { (peripheral: BCPeripheral) -> Void in
            Notify.withMessage("Discovered peripheral '\(peripheral.name)'")
            self.connect(peripheral)
            self.updateWhenActive()
        }
        let afterTimeout = { (error:NSError) -> Void in
            if error.domain == BCError.domain && error.code == BCPeripheralErrorCode.DiscoveryTimeout.rawValue {
                BCLogger.debug("timeoutScan: timing out")
                Singletons.timedScannerator.stopScanning()
                self.setScanButton()
            }
        }
        // Promiscuous Scan Enabled
        var future: FutureStream<BCPeripheral>
        switch scanMode {
        case "Promiscuous" :
            // Promiscuous Scan with Timeout Enabled
            if ConfigStore.getScanTimeoutEnabled() {
                future = Singletons.timedScannerator.startScanning(Double(ConfigStore.getScanTimeout()), capacity: 10)
                
            } else {
                future = Singletons.centralManager.startScanning(10)
            }
            future.onSuccess(afterPeripheralDiscovered)
            future.onFailure(afterTimeout)
        case "Service" :
            let scannedServices = ConfigStore.getScannedServiceUUIDs()
            if scannedServices.isEmpty {
                self.presentViewController(UIAlertController.alertWithMessage("No scan services configured"), animated: true, completion: nil)
            } else {
                // Service Scan with Timeout Enabled
                if ConfigStore.getScanTimeoutEnabled() {
                    future = Singletons.timedScannerator.startScanningForServiceUUIDs(Double(ConfigStore.getScanTimeout()), uuids: scannedServices, capacity: 10)
                } else {
                    future = Singletons.centralManager.startScanningForServiceUUIDs(scannedServices, capacity: 10)
                }
                future.onSuccess(afterPeripheralDiscovered)
                future.onFailure(afterTimeout)
            }
        default:
            BCLogger.debug("Scan Mode :'\(scanMode)' invalid")
        }
    }
        
    // UITableViewDataSource
    override func numberOfSectionsInTableView(tableView:UITableView) -> Int {
        return 1
    }
    
    override func tableView(_:UITableView, numberOfRowsInSection section:Int) -> Int {
        return Singletons.centralManager.peripherals.count
    }
    
    override func tableView(tableView:UITableView, cellForRowAtIndexPath indexPath:NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(MainStoryboard.peripheralCell, forIndexPath: indexPath) as! PeripheralCell
        let peripheral = Singletons.centralManager.peripherals[indexPath.row]
        cell.nameLabel.text = peripheral.name
        cell.accessoryType = .None
        if peripheral.state == .Connected {
            cell.nameLabel.textColor = UIColor.blackColor()
            cell.rssiLabel.text = "\(peripheral.rssi)"
            cell.stateLabel.text = "Connected"
            cell.stateLabel.textColor = UIColor(red:0.1, green:0.7, blue:0.1, alpha:0.5)
        } else {
            cell.nameLabel.textColor = UIColor.lightGrayColor()
            cell.rssiLabel.text = "NA"
            cell.stateLabel.text = "Disconnected"
            cell.stateLabel.textColor = UIColor.lightGrayColor()
        }
        return cell
    }
    

}