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
    var peripheralConnectionStatus = [UUID : Bool]()
    var connectionFuture: FutureStream<(peripheral: Peripheral, connectionEvent: ConnectionEvent)>!

    var reachedDiscoveryLimit: Bool {
        return Singletons.centralManager.peripherals.count >= ConfigStore.getMaximumPeripheralsDiscovered()
    }

    var peripheralsSortedByRSSI: [Peripheral] {
        return Singletons.centralManager.peripherals.sorted() { (p1, p2) -> Bool in
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

    var peripherals: [Peripheral] {
        if ConfigStore.getPeripheralSortOrder() == .discoveryDate {
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
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        self.stopScanBarButtonItem = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(PeripheralsViewController.toggleScan(_:)))
        self.startScanBarButtonItem = UIBarButtonItem(title: "Scan", style: UIBarButtonItemStyle.plain, target: self, action: #selector(PeripheralsViewController.toggleScan(_:)))
        self.styleUIBarButton(self.startScanBarButtonItem)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.styleNavigationBar()
        self.setScanButton()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.shouldUpdatePeripheralConnectionStatus = true
        self.updatePeripheralConnectionsIfNeeded()
        self.startPolllingRSSIForPeripherals()
        NotificationCenter.default.addObserver(self, selector:#selector(PeripheralsViewController.didBecomeActive), name: NSNotification.Name.UIApplicationDidBecomeActive, object:nil)
        NotificationCenter.default.addObserver(self, selector:#selector(PeripheralsViewController.didEnterBackground), name: NSNotification.Name.UIApplicationDidEnterBackground, object:nil)
        self.setScanButton()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.shouldUpdatePeripheralConnectionStatus = false
        self.stopPollingRSSIForPeripherals()
        NotificationCenter.default.removeObserver(self)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any!) {
        if segue.identifier == MainStoryboard.peripheralSegue {
            if let selectedIndex = self.tableView.indexPath(for: sender as! UITableViewCell) {
                let viewController = segue.destination as! PeripheralViewController
                viewController.peripheral = self.peripherals[selectedIndex.row]
            }
        }
    }
    
    // actions
    func toggleScan(_ sender: AnyObject) {
        if !Singletons.beaconManager.isMonitoring {
            if self.scanStatus {
                Logger.debug("Scan toggled off")
                self.stopScanning()
            } else {
                Logger.debug("Scan toggled on")
                Singletons.centralManager.whenStateChanges().onSuccess { state in
                    switch state {
                    case .poweredOn:
                        self.startScan()
                        self.setScanButton()
                        self.updatePeripheralConnectionsIfNeeded()
                    case .poweredOff:
                        break
                    case .resetting:
                        break
                    case .unauthorized:
                        break
                    case .unknown:
                        break
                    case .unsupported:
                        break
                    }
                }
            }
        } else {
            self.present(UIAlertController.alertWithMessage("iBeacon monitoring is active. Cannot scan and monitor iBeacons simutaneously. Stop iBeacon monitoring to start scan"), animated:true, completion:nil)
        }
    }

    func stopScanning() {
        if Singletons.centralManager.isScanning {
            Singletons.centralManager.stopScanning()
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
        Logger.debug()
        self.tableView.reloadData()
        self.setScanButton()
    }

    func didEnterBackground() {
        Logger.debug()
        self.stopScanning()
        self.peripheralConnectionStatus.removeAll()
    }

    func setScanButton() {
        if self.scanStatus {
            self.navigationItem.setLeftBarButton(self.stopScanBarButtonItem, animated:false)
        } else {
            self.navigationItem.setLeftBarButton(self.startScanBarButtonItem, animated:false)
        }
    }

    func updatePeripheralConnections() {
        let peripherals = self.peripheralsSortedByRSSI
        let maxConnections = ConfigStore.getMaximumPeripheralsConnected()
        for i in 0..<peripherals.count {
            let peripheral = peripherals[i]
            if let connectionStatus = self.peripheralConnectionStatus[peripheral.identifier] {
                if i < maxConnections {
                    if !connectionStatus && peripheral.state == .disconnected {
                        Logger.debug("Connecting peripheral: '\(peripheral.name)', \(peripheral.identifier.uuidString)")
                        self.connect(peripheral)
                    }
                } else {
                    if connectionStatus {
                        Logger.debug("Disconnecting peripheral: '\(peripheral.name)', \(peripheral.identifier.uuidString)")
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
            Logger.debug("update connections triggered")
            self.updatePeripheralConnections()
            self.updateWhenActive()
            self.updatePeripheralConnectionsIfNeeded()
        }
    }

    func startPollingRSSIForPeripheral(_ peripheral: Peripheral) {
        guard self.shouldUpdatePeripheralConnectionStatus else {
            return
        }
        _ = peripheral.startPollingRSSI(Params.peripheralsViewRSSIPollingInterval, capacity: Params.peripheralRSSIFutureCapacity)
    }

    func startPolllingRSSIForPeripherals() {
        for peripheral in Singletons.centralManager.peripherals {
            guard let connectionStatus = self.peripheralConnectionStatus[peripheral.identifier] , connectionStatus else {
                continue
            }
            self.startPollingRSSIForPeripheral(peripheral)
        }
    }

    func stopPollingRSSIForPeripherals() {
        for peripheral in Singletons.centralManager.peripherals {
            peripheral.stopPollingRSSI()
        }
    }

    func connect(_ peripheral: Peripheral) {
        Logger.debug("Connect peripheral: '\(peripheral.name)'', \(peripheral.identifier.uuidString)")
        let maxTimeouts = ConfigStore.getPeripheralMaximumTimeoutsEnabled() ? ConfigStore.getPeripheralMaximumTimeouts() : UInt.max
        let maxDisconnections = ConfigStore.getPeripheralMaximumDisconnectionsEnabled() ? ConfigStore.getPeripheralMaximumDisconnections() : UInt.max
        let connectionTimeout = ConfigStore.getPeripheralConnectionTimeoutEnabled() ? Double(ConfigStore.getPeripheralConnectionTimeout()) : Double.infinity
        connectionFuture = peripheral.connect(timeoutRetries: maxTimeouts, disconnectRetries: maxDisconnections, connectionTimeout: connectionTimeout, capacity: 10)
        connectionFuture.onSuccess { (peripheral, connectionEvent) in
            switch connectionEvent {
            case .connect:
                Logger.debug("Connected peripheral: '\(peripheral.name)', \(peripheral.identifier.uuidString)")
                Notification.send("Connected peripheral: '\(peripheral.name)', \(peripheral.identifier.uuidString)")
                self.startPollingRSSIForPeripheral(peripheral)
                self.peripheralConnectionStatus[peripheral.identifier] = true
                self.updateWhenActive()
            case .timeout:
                Logger.debug("Timeout: '\(peripheral.name)', \(peripheral.identifier.uuidString)")
                peripheral.stopPollingRSSI()
                self.reconnectIfNecessary(peripheral)
                self.updateWhenActive()
            case .disconnect:
                Logger.debug("Disconnected peripheral: '\(peripheral.name)', \(peripheral.identifier.uuidString)")
                Notification.send("Disconnected peripheral: '\(peripheral.name)'")
                peripheral.stopPollingRSSI()
                self.reconnectIfNecessary(peripheral)
                self.updateWhenActive()
            case .forceDisconnect:
                Logger.debug("Force disconnection of: '\(peripheral.name)', \(peripheral.identifier.uuidString)")
                Notification.send("Force disconnection of: '\(peripheral.name), \(peripheral.identifier.uuidString)'")
                self.reconnectIfNecessary(peripheral)
                self.updateWhenActive()
            case .giveUp:
                Logger.debug("GiveUp: '\(peripheral.name)', \(peripheral.identifier.uuidString)")
                peripheral.stopPollingRSSI()
                self.peripheralConnectionStatus.removeValue(forKey: peripheral.identifier)
                peripheral.terminate()
                self.startScan()
                self.updateWhenActive()
            }
        }
        connectionFuture.onFailure { error in
            peripheral.stopPollingRSSI()
            self.reconnectIfNecessary(peripheral)
            self.updateWhenActive()
        }
    }

    func reconnectIfNecessary(_ peripheral: Peripheral) {
        if let status = self.peripheralConnectionStatus[peripheral.identifier] , status {
            peripheral.reconnect(withDelay: 1.0)
        }
    }
    
    func startScan() {
        guard self.reachedDiscoveryLimit == false else {
            return
        }
        self.scanStatus = true
        let scanMode = ConfigStore.getScanMode()
        let afterPeripheralDiscovered = { (peripheral: Peripheral) -> Void in
            if Singletons.centralManager.peripherals.contains(peripheral) {
                Logger.debug("Discovered peripheral: '\(peripheral.name)', \(peripheral.identifier.uuidString)")
                Notification.send("Discovered peripheral '\(peripheral.name)'")
                self.updateWhenActive()
                self.peripheralConnectionStatus[peripheral.identifier] = false
                if self.reachedDiscoveryLimit {
                    Singletons.centralManager.stopScanning()
                }
                self.updatePeripheralConnections()
            }
        }
        let afterTimeout = { (error: Swift.Error) -> Void in
            guard let error = error as? CentralManagerError else {
                return
            }
            if error == CentralManagerError.peripheralScanTimeout {
                Logger.debug("timeoutScan: timing out")
                Singletons.centralManager.stopScanning()
                self.setScanButton()
            }
        }

        // Promiscuous Scan Enabled
        var future: FutureStream<Peripheral>
        let scanTimeout = ConfigStore.getScanTimeoutEnabled() ? Double(ConfigStore.getScanTimeout()) : Double.infinity
        switch scanMode {
        case .promiscuous:
            // Promiscuous Scan with Timeout Enabled
            future = Singletons.centralManager.startScanning(capacity:10, timeout: scanTimeout)
            future.onSuccess(completion: afterPeripheralDiscovered)
            future.onFailure(completion: afterTimeout)
        case .service:
            let scannedServices = ConfigStore.getScannedServiceUUIDs()
            if scannedServices.isEmpty {
                self.present(UIAlertController.alertWithMessage("No scan services configured"), animated: true, completion: nil)
            } else {
                future = Singletons.centralManager.startScanning(forServiceUUIDs:scannedServices, capacity: 10, timeout: scanTimeout)
                future.onSuccess(completion: afterPeripheralDiscovered)
                future.onFailure(completion: afterTimeout)
            }
        }
    }

    // UITableViewDataSource
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Singletons.centralManager.peripherals.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: MainStoryboard.peripheralCell, for: indexPath) as! PeripheralCell
        let peripheral = self.peripherals[indexPath.row]
        cell.nameLabel.text = peripheral.name
        cell.accessoryType = .none
        if peripheral.state == .connected {
            cell.nameLabel.textColor = UIColor.black
            cell.stateLabel.text = "Connected"
            cell.stateLabel.textColor = UIColor(red:0.1, green:0.7, blue:0.1, alpha:0.5)
        } else {
            cell.nameLabel.textColor = UIColor.lightGray
            cell.stateLabel.text = "Disconnected"
            cell.stateLabel.textColor = UIColor.lightGray
        }
        cell.rssiLabel.text = "\(peripheral.RSSI)"
        return cell
    }
}
