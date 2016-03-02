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

    static let updateConnectionsFrequency = 5.0

    var stopScanBarButtonItem: UIBarButtonItem!
    var startScanBarButtonItem: UIBarButtonItem!

    var scanStatus = false
    var updatePeripheralConnectionsSwitch = false
    var rssiPollingFutures = [NSUUID: (future: FutureStream<Int>, cellUpdate: Bool)]()
    var peripheralConnectionStatus = [NSUUID: Bool]()

    var reachedDiscoveryLimit: Bool {
        return self.peripheralConnectionStatus.count >= ConfigStore.getMaximumPeripheralsDiscovered()
    }

    var peripheralsSortedByRSSI: [BCPeripheral] {
        return Singletons.centralManager.peripherals.sort() { (p1, p2) -> Bool in
            if p1.RSSI == 127 && p2.RSSI != 127 {
                return false
            }  else if p1.RSSI != 127 && p2.RSSI == 127 {
                return true
            } else if p1.RSSI == 127 && p2.RSSI == 127 {
                return true
            } else {
                return p1.RSSI >= p2.RSSI
            }
        }
    }

    struct MainStoryboard {
        static let peripheralCell = "PeripheralCell"
        static let peripheralSegue = "Peripheral"
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
        self.stopScanBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Stop, target: self, action: "toggleScan:")
        self.startScanBarButtonItem = UIBarButtonItem(title: "Scan", style: UIBarButtonItemStyle.Plain, target: self, action: "toggleScan:")
        self.styleUIBarButton(self.startScanBarButtonItem)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.styleNavigationBar()
        self.setScanButton()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.updatePeripheralConnectionsSwitch = true
        self.stopPollingRSSIForPeripherals()
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"didBecomeActive", name: UIApplicationDidBecomeActiveNotification, object:nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"didResignActive", name: UIApplicationDidEnterBackgroundNotification, object:nil)
        self.setScanButton()
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.stopPollingRSSIForPeripherals()
    }

    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        self.updatePeripheralConnectionsSwitch = false
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

    func stopPollingRSSIForPeripherals() {
        for peripheral in Singletons.centralManager.peripherals {
            if self.rssiPollingFutures[peripheral.identifier] != nil {
                 peripheral.stopPollingRSSI()
            }
        }
        self.rssiPollingFutures.removeAll()
    }

    // actions
    func toggleScan(sender:AnyObject) {
        if Singletons.beaconManager.isMonitoring == false {
            self.scanStatus = !self.scanStatus
            if self.scanStatus == false {
                if Singletons.centralManager.isScanning || Singletons.timedScannerator.isScanning {
                    if  ConfigStore.getScanTimeoutEnabled() {
                        Singletons.timedScannerator.stopScanning()
                    } else {
                        Singletons.centralManager.stopScanning()
                    }
                }
                self.stopPollingRSSIForPeripherals()
                Singletons.centralManager.disconnectAllPeripherals()
                Singletons.centralManager.removeAllPeripherals()
                self.peripheralConnectionStatus.removeAll()
                self.setScanButton()
                self.updateWhenActive()
            } else {
                Singletons.centralManager.whenPowerOn().onSuccess {
                    BCLogger.debug()
                    self.startScan()
                    self.setScanButton()
                    self.updatePeripheralConnectionsIfNeeded()
                }
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
        if self.scanStatus {
            self.navigationItem.setLeftBarButtonItem(self.stopScanBarButtonItem, animated:false)
        } else {
            self.navigationItem.setLeftBarButtonItem(self.startScanBarButtonItem, animated:false)
        }
    }

    func updatePeripheralConnections() {
        let peripherals = self.peripheralsSortedByRSSI
        let maxConnections = ConfigStore.getMaximumPeripheralsConnected()
        for i in 0..<peripherals.count {
            let peripheral = peripherals[i]
            if let connectionStatus = self.peripheralConnectionStatus[peripheral.identifier] {
                if i < maxConnections {
                    if connectionStatus == false {
                        self.peripheralConnectionStatus[peripheral.identifier] = true
                        self.connect(peripheral)
                    }
                } else {
                    if connectionStatus {
                        self.peripheralConnectionStatus[peripheral.identifier] = false
                        peripheral.disconnect()
                    }
                }
            }
        }
    }

    func updatePeripheralConnectionsIfNeeded() {
        guard self.updatePeripheralConnectionsSwitch && self.scanStatus else {
            return
        }
        Queue.main.delay(PeripheralsViewController.updateConnectionsFrequency) { [unowned self] in
            self.updatePeripheralConnections()
            self.updateWhenActive()
            self.updatePeripheralConnectionsIfNeeded()
        }
    }

    func connect(peripheral: BCPeripheral) {
        BCLogger.debug("Connect peripheral: '\(peripheral.name)'")
        let future = peripheral.connect(10, timeoutRetries: ConfigStore.getMaximumReconnections(), connectionTimeout: Double(ConfigStore.getPeripheralConnectionTimeout()))
        future.onSuccess { (peripheral, connectionEvent) in
            switch connectionEvent {
            case .Connect:
                BCLogger.debug("Connected peripheral: '\(peripheral.name)'")
                Notify.withMessage("Connected peripheral: '\(peripheral.name)'")
                self.updateWhenActive()
            case .Timeout:
                BCLogger.debug("Timeout: '\(peripheral.name)'")
                NSNotificationCenter.defaultCenter().postNotificationName(BlueCapNotification.peripheralDisconnected, object:peripheral)
                peripheral.reconnect()
                self.updateWhenActive()
            case .Disconnect:
                BCLogger.debug("Disconnected peripheral: '\(peripheral.name)'")
                Notify.withMessage("Disconnected peripheral: '\(peripheral.name)'")
                peripheral.reconnect()
                NSNotificationCenter.defaultCenter().postNotificationName(BlueCapNotification.peripheralDisconnected, object:peripheral)
                self.updateWhenActive()
            case .ForceDisconnect:
                BCLogger.debug("Force disconnection of: '\(peripheral.name)'")
                Notify.withMessage("Force disconnection of: '\(peripheral.name)'")
                NSNotificationCenter.defaultCenter().postNotificationName(BlueCapNotification.peripheralDisconnected, object:peripheral)
                self.updateWhenActive()
            case .Failed:
                BCLogger.debug("Connection failed peripheral: '\(peripheral.name)'")
                Notify.withMessage("Connection failed peripheral: '\(peripheral.name)'")
            case .GiveUp:
                BCLogger.debug("GiveUp: '\(peripheral.name)'")
                peripheral.stopPollingRSSI()
                self.rssiPollingFutures.removeValueForKey(peripheral.identifier)
                self.peripheralConnectionStatus.removeValueForKey(peripheral.identifier)
                peripheral.terminate()
                self.startScan()
                self.updateWhenActive()
            }
        }
        future.onFailure { error in
            self.updateWhenActive()
        }
    }
    
    func startScan() {
        let scanMode = ConfigStore.getScanMode()
        let afterPeripheralDiscovered = { (peripheral: BCPeripheral) -> Void in
            Notify.withMessage("Discovered peripheral '\(peripheral.name)'")
            self.updateWhenActive()
            self.rssiPollingFutures[peripheral.identifier] =
                (peripheral.startPollingRSSI(Params.peripheralRSSIPollingInterval, capacity: Params.peripheralRSSIFutureCapacity), false)
            self.peripheralConnectionStatus[peripheral.identifier] = false
            if self.reachedDiscoveryLimit {
                Singletons.centralManager.stopScanning()
            }
            self.updatePeripheralConnections()
        }
        let afterTimeout = { (error: NSError) -> Void in
            if error.domain == BCError.domain && error.code == BCPeripheralErrorCode.DiscoveryTimeout.rawValue {
                BCLogger.debug("timeoutScan: timing out")
                Singletons.timedScannerator.stopScanning()
                self.setScanButton()
            }
        }

        // Promiscuous Scan Enabled
        var future: FutureStream<BCPeripheral>
        switch scanMode {
        case .Promiscuous:
            // Promiscuous Scan with Timeout Enabled
            if ConfigStore.getScanTimeoutEnabled() {
                future = Singletons.timedScannerator.startScanning(Double(ConfigStore.getScanTimeout()), capacity: 10)
                
            } else {
                future = Singletons.centralManager.startScanning(10)
            }
            future.onSuccess(afterPeripheralDiscovered)
            future.onFailure(afterTimeout)
        case .Service:
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
        let peripheral: BCPeripheral
        if ConfigStore.getPeripheralSortOrder() == .DiscoveryDate {
             peripheral = Singletons.centralManager.peripherals[indexPath.row]
        } else {
            peripheral = self.peripheralsSortedByRSSI[indexPath.row]
        }
        cell.nameLabel.text = peripheral.name
        cell.accessoryType = .None
        if peripheral.state == .Connected {
            cell.nameLabel.textColor = UIColor.blackColor()
            cell.stateLabel.text = "Connected"
            cell.stateLabel.textColor = UIColor(red:0.1, green:0.7, blue:0.1, alpha:0.5)
        } else {
            cell.nameLabel.textColor = UIColor.lightGrayColor()
            cell.stateLabel.text = "Disconnected"
            cell.stateLabel.textColor = UIColor.lightGrayColor()
        }
        cell.rssiLabel.text = "\(peripheral.RSSI)"
        if let (future, cellUpdate) = self.rssiPollingFutures[peripheral.identifier] where cellUpdate == false {
            self.rssiPollingFutures[peripheral.identifier] = (future, true)
            future.onSuccess { [weak cell] rssi in
                cell?.rssiLabel.text = "\(rssi)"
            }
        }
        return cell
    }
}