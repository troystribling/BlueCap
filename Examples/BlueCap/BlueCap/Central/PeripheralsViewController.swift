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

    var scanStatus = false
    var shouldUpdatePeripheralConnectionStatus = false
    var peripheralConnectionStatus = [NSUUID : Bool]()

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

    var peripherals: [BCPeripheral] {
        if ConfigStore.getPeripheralSortOrder() == .DiscoveryDate {
            return Singletons.centralManager.peripherals
        } else {
            return self.peripheralsSortedByRSSI
        }

    }

    struct MainStoryboard {
        static let peripheralCell = "PeripheralCell"
        static let peripheralSegue = "Peripheral"
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
        self.stopScanBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Stop, target: self, action: #selector(PeripheralsViewController.toggleScan(_:)))
        self.startScanBarButtonItem = UIBarButtonItem(title: "Scan", style: UIBarButtonItemStyle.Plain, target: self, action: #selector(PeripheralsViewController.toggleScan(_:)))
        self.styleUIBarButton(self.startScanBarButtonItem)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.styleNavigationBar()
        self.setScanButton()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.shouldUpdatePeripheralConnectionStatus = true
        self.updatePeripheralConnectionsIfNeeded()
        self.startPolllingRSSIForPeripherals()
        NSNotificationCenter.defaultCenter().addObserver(self, selector:#selector(PeripheralsViewController.didBecomeActive), name: UIApplicationDidBecomeActiveNotification, object:nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector:#selector(PeripheralsViewController.didEnterBackground), name: UIApplicationDidEnterBackgroundNotification, object:nil)
        self.setScanButton()
    }

    override func viewDidDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.shouldUpdatePeripheralConnectionStatus = false
        self.stopPollingRSSIForPeripherals()
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        if segue.identifier == MainStoryboard.peripheralSegue {
            if let selectedIndex = self.tableView.indexPathForCell(sender as! UITableViewCell) {
                let viewController = segue.destinationViewController as! PeripheralViewController
                viewController.peripheral = self.peripherals[selectedIndex.row]
            }
        }
    }
    
    // actions
    func toggleScan(sender: AnyObject) {
        if !Singletons.beaconManager.isMonitoring {
            if self.scanStatus {
                BCLogger.debug("Scan toggled off")
                self.stopScanning()
            } else {
                BCLogger.debug("Scan toggled on")
                Singletons.centralManager.whenPowerOn().onSuccess {
                    self.startScan()
                    self.setScanButton()
                    self.updatePeripheralConnectionsIfNeeded()
                }
            }
        } else {
            self.presentViewController(UIAlertController.alertWithMessage("iBeacon monitoring is active. Cannot scan and monitor iBeacons simutaneously. Stop iBeacon monitoring to start scan"), animated:true, completion:nil)
        }
    }

    func stopScanning() {
        if Singletons.centralManager.isScanning || Singletons.timedScannerator.isScanning {
            if  ConfigStore.getScanTimeoutEnabled() {
                Singletons.timedScannerator.stopScanning()
            } else {
                Singletons.centralManager.stopScanning()
            }
        }
        self.scanStatus = false
        self.stopPollingRSSIForPeripherals()
        Singletons.centralManager.disconnectAllPeripherals()
        Singletons.centralManager.removeAllPeripherals()
        self.peripheralConnectionStatus.removeAll()
        self.setScanButton()
        self.updateWhenActive()
    }

    // utils
    func didBecomeActive() {
        BCLogger.debug()
        self.tableView.reloadData()
        self.setScanButton()
    }

    func didEnterBackground() {
        BCLogger.debug()
        self.stopScanning()
        self.peripheralConnectionStatus.removeAll()
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
                    if !connectionStatus && peripheral.state == .Disconnected {
                        BCLogger.debug("Connecting peripheral: '\(peripheral.name)', \(peripheral.identifier.UUIDString)")
                        self.connect(peripheral)
                    }
                } else {
                    if connectionStatus {
                        BCLogger.debug("Disconnecting peripheral: '\(peripheral.name)', \(peripheral.identifier.UUIDString)")
                        peripheral.disconnect()
                    }
                }
            }
        }
    }

    func updatePeripheralConnectionsIfNeeded() {
        guard self.shouldUpdatePeripheralConnectionStatus && self.scanStatus else {
            return
        }
        Queue.main.delay(Params.updateConnectionsInterval) { [unowned self] in
            BCLogger.debug("update connections triggered")
            self.updatePeripheralConnections()
            self.updateWhenActive()
            self.updatePeripheralConnectionsIfNeeded()
        }
    }

    func startPollingRSSIForPeripheral(peripheral: BCPeripheral) {
        guard self.shouldUpdatePeripheralConnectionStatus else {
            return
        }
        peripheral.startPollingRSSI(Params.peripheralsViewRSSIPollingInterval, capacity: Params.peripheralRSSIFutureCapacity)
    }

    func startPolllingRSSIForPeripherals() {
        for peripheral in Singletons.centralManager.peripherals {
            if let connectionStatus = self.peripheralConnectionStatus[peripheral.identifier] where connectionStatus {
                self.startPollingRSSIForPeripheral(peripheral)
            }
        }
    }

    func stopPollingRSSIForPeripherals() {
        for peripheral in Singletons.centralManager.peripherals {
            peripheral.stopPollingRSSI()
        }
    }

    func connect(peripheral: BCPeripheral) {
        BCLogger.debug("Connect peripheral: '\(peripheral.name)'', \(peripheral.identifier.UUIDString)")
        let maxTimeouts = ConfigStore.getMaximumTimeouts()
        let maxDisconnections = ConfigStore.getMaximumDisconnections()
        let future = peripheral.connect(10, timeoutRetries: maxTimeouts == 0 ? nil : maxTimeouts, disconnectRetries: maxDisconnections == 0 ? nil : maxDisconnections, connectionTimeout: Double(ConfigStore.getPeripheralConnectionTimeout()))
        future.onSuccess { (peripheral, connectionEvent) in
            switch connectionEvent {
            case .Connect:
                BCLogger.debug("Connected peripheral: '\(peripheral.name)', \(peripheral.identifier.UUIDString)")
                Notify.withMessage("Connected peripheral: '\(peripheral.name)', \(peripheral.identifier.UUIDString)")
                self.startPollingRSSIForPeripheral(peripheral)
                self.peripheralConnectionStatus[peripheral.identifier] = true
                self.updateWhenActive()
            case .Timeout:
                BCLogger.debug("Timeout: '\(peripheral.name)', \(peripheral.identifier.UUIDString)")
                peripheral.stopPollingRSSI()
                self.reconnectIfNecessary(peripheral)
                self.updateWhenActive()
            case .Disconnect:
                BCLogger.debug("Disconnected peripheral: '\(peripheral.name)', \(peripheral.identifier.UUIDString)")
                Notify.withMessage("Disconnected peripheral: '\(peripheral.name)'")
                peripheral.stopPollingRSSI()
                self.reconnectIfNecessary(peripheral)
                self.updateWhenActive()
            case .ForceDisconnect:
                BCLogger.debug("Force disconnection of: '\(peripheral.name)', \(peripheral.identifier.UUIDString)")
                Notify.withMessage("Force disconnection of: '\(peripheral.name), \(peripheral.identifier.UUIDString)'")
                self.reconnectIfNecessary(peripheral)
                self.updateWhenActive()
            case .GiveUp:
                BCLogger.debug("GiveUp: '\(peripheral.name)', \(peripheral.identifier.UUIDString)")
                peripheral.stopPollingRSSI()
                self.peripheralConnectionStatus.removeValueForKey(peripheral.identifier)
                peripheral.terminate()
                self.startScan()
                self.updateWhenActive()
            }
        }
        future.onFailure { error in
            peripheral.stopPollingRSSI()
            self.reconnectIfNecessary(peripheral)
            self.updateWhenActive()
        }
    }

    func reconnectIfNecessary(peripheral: BCPeripheral) {
        if let status = self.peripheralConnectionStatus[peripheral.identifier] where status {
            peripheral.reconnect()
        }
    }
    
    func startScan() {
        self.scanStatus = true
        let scanMode = ConfigStore.getScanMode()
        let afterPeripheralDiscovered = { (peripheral: BCPeripheral) -> Void in
            if Singletons.centralManager.peripherals.contains(peripheral) {
                BCLogger.debug("Discovered peripheral: '\(peripheral.name)', \(peripheral.identifier.UUIDString)")
                Notify.withMessage("Discovered peripheral '\(peripheral.name)'")
                self.updateWhenActive()
                self.peripheralConnectionStatus[peripheral.identifier] = false
                if self.reachedDiscoveryLimit {
                    Singletons.centralManager.stopScanning()
                }
                self.updatePeripheralConnections()
            }
        }
        let afterTimeout = { (error: NSError) -> Void in
            if error.domain == BCError.domain && error.code == BCError.centralPeripheralScanTimeout.code {
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
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Singletons.centralManager.peripherals.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(MainStoryboard.peripheralCell, forIndexPath: indexPath) as! PeripheralCell
        let peripheral = self.peripherals[indexPath.row]
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
        return cell
    }
}