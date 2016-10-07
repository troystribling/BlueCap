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

    var isScanning = false
    var shouldUpdateTable = false
    var connectedPeripherals = Set<UUID>()
    var connectionFutures =  [UUID : FutureStream<(peripheral: Peripheral, connectionEvent: ConnectionEvent)>]()

    var cachedPeripheralIdentifiers = DiscoveredPeripheralStore.popAll()

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
        Singletons.centralManager.whenStateChanges().onSuccess { [weak self] state in
            self.forEach { strongSelf in
                Logger.debug("CentralManager state changed: \(state.stringValue)")
                switch state {
                case .poweredOn:
                    break
                case .poweredOff, .unsupported, .unauthorized:
                    strongSelf.stopScanning()
                    strongSelf.present(UIAlertController.alertWithMessage("CentralManager state \"\(state.stringValue)\""), animated:true, completion:nil)
                case .resetting, .unknown:
                    strongSelf.present(UIAlertController.alertWithMessage("CentralManager state \"\(state.stringValue)\""), animated:true, completion:nil)
                }
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.styleNavigationBar()
        self.setScanButton()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.shouldUpdateTable = true
        self.pollConnectionStatusAndUpdateIfNeeded()
        self.startPolllingRSSIForPeripherals()
        NotificationCenter.default.addObserver(self, selector:#selector(PeripheralsViewController.didBecomeActive), name: NSNotification.Name.UIApplicationDidBecomeActive, object:nil)
        NotificationCenter.default.addObserver(self, selector:#selector(PeripheralsViewController.didEnterBackground), name: NSNotification.Name.UIApplicationDidEnterBackground, object:nil)
        self.setScanButton()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.shouldUpdateTable = false
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
                let peripheral = self.peripherals[selectedIndex.row]
                viewController.peripheral = peripheral
                viewController.connectionFuture = connectionFutures[peripheral.identifier]
            }
        }
    }
    
    // actions
    func toggleScan(_ sender: AnyObject) {
        guard !Singletons.beaconManager.isMonitoring else {
            self.present(UIAlertController.alertWithMessage("iBeacon monitoring is active. Cannot scan and monitor iBeacons simutaneously. Stop iBeacon monitoring to start scan"), animated:true, completion:nil)
            return
        }
        guard Singletons.centralManager.poweredOn else {
            self.present(UIAlertController.alertWithMessage("Bluetooth is not enabled. Enable Bluetooth in settings."), animated:true, completion:nil)
            return
        }
        if self.isScanning {
            Logger.debug("Scan toggled off")
            self.stopScanning()
        } else {
            Logger.debug("Scan toggled on")
            self.startScan()
            self.setScanButton()
            self.pollConnectionStatusAndUpdateIfNeeded()
        }
    }

    func stopScanning() {
        if Singletons.centralManager.isScanning {
            Singletons.centralManager.stopScanning()
        }
        self.isScanning = false
        self.stopPollingRSSIForPeripherals()
        Singletons.centralManager.disconnectAllPeripherals()
        Singletons.centralManager.removeAllPeripherals()
        connectedPeripherals.removeAll()
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
    }

    func setScanButton() {
        if self.isScanning {
            self.navigationItem.setLeftBarButton(self.stopScanBarButtonItem, animated:false)
        } else {
            self.navigationItem.setLeftBarButton(self.startScanBarButtonItem, animated:false)
        }
    }

    func disconnectPeripheralsIfNecessary() {
        let maxConnections = ConfigStore.getMaximumPeripheralsConnected()
        let peripherals = self.peripheralsSortedByRSSI
        guard maxConnections <= peripherals.count else {
            return
        }
        for i in maxConnections..<peripherals.count {
            let peripheral = peripherals[i]
            if connectedPeripherals.contains(peripheral.identifier) {
                Logger.debug("Disconnecting peripheral: '\(peripheral.name)', \(peripheral.identifier.uuidString)")
                connectedPeripherals.remove(peripheral.identifier)
                peripheral.disconnect()
            }
        }
    }

    func connectPeripheralsIfNeccessay() {
        let peripherals = self.peripheralsSortedByRSSI
        let maxConnections = ConfigStore.getMaximumPeripheralsConnected()
        let connectionCount = maxConnections <= peripherals.count ? maxConnections : peripherals.count
        for i in 0..<connectionCount {
            let peripheral = peripherals[i]
            if !connectedPeripherals.contains(peripheral.identifier) {
                Logger.debug("Connecting peripheral: '\(peripheral.name)', \(peripheral.identifier.uuidString)")
                connectedPeripherals.insert(peripheral.identifier)
                if connectionFutures[peripheral.identifier] == nil {
                    connect(peripheral)
                } else {
                    reconnectIfNecessary(peripheral)
                }
            }
        }
    }

    func pollConnectionStatusAndUpdateIfNeeded() {
        guard self.shouldUpdateTable && self.isScanning else {
            return
        }
        Queue.main.delay(Params.updateConnectionsInterval) { [weak self] in
            Logger.debug("update table triggered")
            self.forEach { strongSelf in
                strongSelf.updateWhenActive()
                strongSelf.connectPeripheralsIfNeccessay()
                strongSelf.pollConnectionStatusAndUpdateIfNeeded()
            }
        }
    }

    func startPollingRSSIForPeripheral(_ peripheral: Peripheral) {
        guard self.shouldUpdateTable else {
            return
        }
        _ = peripheral.startPollingRSSI(Params.peripheralsViewRSSIPollingInterval, capacity: Params.peripheralRSSIFutureCapacity)
    }

    func startPolllingRSSIForPeripherals() {
        for peripheral in Singletons.centralManager.peripherals where connectedPeripherals.contains(peripheral.identifier) {
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
        let connectionFuture = peripheral.connect(timeoutRetries: maxTimeouts, disconnectRetries: maxDisconnections, connectionTimeout: connectionTimeout, capacity: 10)
        connectionFuture.onSuccess { [weak self] (peripheral, connectionEvent) in
            self.forEach { strongSelf in
                switch connectionEvent {
                case .connect:
                    Logger.debug("Connected peripheral: '\(peripheral.name)', \(peripheral.identifier.uuidString)")
                    Notification.send("Connected peripheral: '\(peripheral.name)', \(peripheral.identifier.uuidString)")
                    strongSelf.startPollingRSSIForPeripheral(peripheral)
                    strongSelf.updateWhenActive()
                case .timeout:
                    Logger.debug("Timeout: '\(peripheral.name)', \(peripheral.identifier.uuidString)")
                    peripheral.stopPollingRSSI()
                    strongSelf.reconnectIfNecessary(peripheral)
                    strongSelf.updateWhenActive()
                case .disconnect:
                    Logger.debug("Disconnected peripheral: '\(peripheral.name)', \(peripheral.identifier.uuidString)")
                    Notification.send("Disconnected peripheral: '\(peripheral.name)'")
                    peripheral.stopPollingRSSI()
                    strongSelf.reconnectIfNecessary(peripheral)
                    strongSelf.updateWhenActive()
                case .forceDisconnect:
                    Logger.debug("Force disconnection of: '\(peripheral.name)', \(peripheral.identifier.uuidString)")
                    Notification.send("Force disconnection of: '\(peripheral.name), \(peripheral.identifier.uuidString)'")
                    strongSelf.reconnectIfNecessary(peripheral)
                    strongSelf.updateWhenActive()
                case .giveUp:
                    Logger.debug("GiveUp: '\(peripheral.name)', \(peripheral.identifier.uuidString)")
                    peripheral.stopPollingRSSI()
                    strongSelf.connectedPeripherals.remove(peripheral.identifier)
                    peripheral.terminate()
                    strongSelf.startScan()
                    strongSelf.updateWhenActive()
                }
            }
        }
        connectionFuture.onFailure { [weak self] error in
            peripheral.stopPollingRSSI()
            self?.reconnectIfNecessary(peripheral)
            self?.updateWhenActive()
        }
        connectionFutures[peripheral.identifier] = connectionFuture
    }

    func reconnectIfNecessary(_ peripheral: Peripheral) {
        guard peripheral.state != .connected && connectedPeripherals.contains(peripheral.identifier) else {
            return
        }
        peripheral.reconnect(withDelay: 1.0)
    }
    
    func startScan() {
        guard reachedDiscoveryLimit == false && isScanning == false else {
            return
        }
        self.isScanning = true
        let scanMode = ConfigStore.getScanMode()
        var future: FutureStream<Peripheral>
        let scanTimeout = ConfigStore.getScanTimeoutEnabled() ? Double(ConfigStore.getScanTimeout()) : Double.infinity
        switch scanMode {
        case .promiscuous:
            future = Singletons.centralManager.startScanning(capacity:10, timeout: scanTimeout)
            future.onSuccess { [weak self] peripheral in
                self?.afterPeripheralDiscovered(peripheral)
                self?.stopScanIfNeccessay()
            }
            future.onFailure(completion: afterTimeout)
        case .service:
            let scannedServices = ConfigStore.getScannedServiceUUIDs()
            guard scannedServices.isEmpty == false else {
                self.present(UIAlertController.alertWithMessage("No scan services configured"), animated: true, completion: nil)
                return
            }
            future = Singletons.centralManager.startScanning(forServiceUUIDs:scannedServices, capacity: 10, timeout: scanTimeout)
            future.onSuccess(completion: afterPeripheralDiscovered)
            future.onFailure(completion: afterTimeout)
        }
    }

    func afterTimeout(error: Swift.Error) -> Void {
        guard let error = error as? CentralManagerError else {
            return
        }
        if error == CentralManagerError.peripheralScanTimeout {
            Logger.debug("timeoutScan: timing out")
            Singletons.centralManager.stopScanning()
            self.setScanButton()
        }
    }

    func afterPeripheralDiscovered(_ peripheral: Peripheral) -> Void {
        guard  Singletons.centralManager.peripherals.contains(peripheral) else {
            return
        }
        Logger.debug("Discovered peripheral: '\(peripheral.name)', \(peripheral.identifier.uuidString)")
        Notification.send("Discovered peripheral '\(peripheral.name)'")
        DiscoveredPeripheralStore.addPeripheralIdentifier(peripheral.identifier)
        updateWhenActive()
        connectPeripheralsIfNeccessay()
    }

    func stopScanIfNeccessay() {
        if reachedDiscoveryLimit {
            Singletons.centralManager.stopScanning()
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
