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
    var discoveredPeripherals = Set<UUID>()

    var reachedDiscoveryLimit: Bool {
        return Singletons.centralManager.peripherals.count >= ConfigStore.getMaximumPeripheralsDiscovered()
    }

    var allPeripheralsDiscovered: Bool {
        return discoveredPeripherals.count == Singletons.centralManager.peripherals.count
    }

    var peripheralsSortedByRSSI: [Peripheral] {
        return Singletons.centralManager.peripherals.sorted() { (p1, p2) -> Bool in
            if (p1.RSSI == 127 || p1.RSSI == 0) && (p2.RSSI != 127  || p2.RSSI != 0) {
                return false
            }  else if (p1.RSSI != 127 || p1.RSSI != 0) && (p2.RSSI == 127 || p2.RSSI == 0) {
                return true
            } else if (p1.RSSI == 127 || p1.RSSI == 0) && (p2.RSSI == 127 || p2.RSSI == 0) {
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
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        stopScanBarButtonItem = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(PeripheralsViewController.toggleScan(_:)))
        startScanBarButtonItem = UIBarButtonItem(title: "Scan", style: UIBarButtonItemStyle.plain, target: self, action: #selector(PeripheralsViewController.toggleScan(_:)))
        styleUIBarButton(self.startScanBarButtonItem)
        Singletons.centralManager.whenStateChanges().onSuccess { [weak self] state in
            self.forEach { strongSelf in
                Logger.debug("CentralManager state changed: \(state.stringValue)")
                switch state {
                case .poweredOn:
                    break
                case .poweredOff, .unknown, .unauthorized:
                    strongSelf.alertAndStopScanning(message: "CentralManager state \"\(state.stringValue)\"")
                case .resetting:
                    strongSelf.alertAndStopScanning(message:
                        "CentralManager state \"\(state.stringValue)\". The connection with the system bluetooth service was momentarily lost. Restart scan.")
                case .unsupported:
                    strongSelf.alertAndStopScanning(message: "CentralManager state \"\(state.stringValue)\". Bluetooth not supported.")
                }
            }
        }
    }

    func alertAndStopScanning(message: String) {
        present(UIAlertController.alertWithMessage(message), animated:true, completion:nil)
        stopScanning()
        setScanButton()
        Singletons.centralManager.invalidate()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.styleNavigationBar()
        self.setScanButton()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        shouldUpdateTable = true
        pollConnectionsAndUpdateIfNeeded()
        startPolllingRSSIForPeripherals()
        connectPeripheralsIfNeccessay()
        NotificationCenter.default.addObserver(self, selector:#selector(PeripheralsViewController.didBecomeActive), name: NSNotification.Name.UIApplicationDidBecomeActive, object:nil)
        NotificationCenter.default.addObserver(self, selector:#selector(PeripheralsViewController.didEnterBackground), name: NSNotification.Name.UIApplicationDidEnterBackground, object:nil)
        setScanButton()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        shouldUpdateTable = false
        stopPollingRSSIForPeripherals()
        disconnectConnectedPeripherals()
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
            }
        }
    }

    func toggleScan(_ sender: AnyObject) {
        guard !Singletons.beaconManager.isMonitoring else {
            present(UIAlertController.alertWithMessage("iBeacon monitoring is active. Cannot scan and monitor iBeacons simutaneously. Stop iBeacon monitoring to start scan"), animated:true, completion:nil)
            return
        }
        guard Singletons.centralManager.poweredOn else {
            present(UIAlertController.alertWithMessage("Bluetooth is not enabled. Enable Bluetooth in settings."), animated:true, completion:nil)
            return
        }
        if self.isScanning {
            Logger.debug("Scan toggled off")
            stopScanning()
        } else {
            Logger.debug("Scan toggled on")
            startScan()
            pollConnectionsAndUpdateIfNeeded()
        }
        setScanButton()
    }

    func stopScanning() {
        if Singletons.centralManager.isScanning {
            Singletons.centralManager.stopScanning()
        }
        isScanning = false
        stopPollingRSSIForPeripherals()
        Singletons.centralManager.disconnectAllPeripherals()
        Singletons.centralManager.removeAllPeripherals()
        connectedPeripherals.removeAll()
        discoveredPeripherals.removeAll()
        updateWhenActive()
    }

    func didBecomeActive() {
        Logger.debug()
        tableView.reloadData()
        setScanButton()
    }

    func didEnterBackground() {
        Logger.debug()
        stopScanning()
    }

    func setScanButton() {
        if isScanning {
            navigationItem.setLeftBarButton(self.stopScanBarButtonItem, animated:false)
        } else {
            navigationItem.setLeftBarButton(self.startScanBarButtonItem, animated:false)
        }
    }

    // MARK: Peripheral RSSI

    func startPollingRSSIForPeripheral(_ peripheral: Peripheral) {
        guard shouldUpdateTable else {
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

    // MARK: Peripheral Connection

    func disconnectConnectedPeripherals() {
        for peripheral in Singletons.centralManager.peripherals where connectedPeripherals.contains(peripheral.identifier) {
            peripheral.disconnect()
        }
        connectedPeripherals.removeAll()
    }

    func disconnectPeripheralsIfNecessary() {
        let maxConnections = ConfigStore.getMaximumPeripheralsConnected()
        let peripherals = peripheralsSortedByRSSI
        guard maxConnections < peripherals.count else {
            return
        }

        for peripheral in peripherals {
            if connectedPeripherals.contains(peripheral.identifier) && discoveredPeripherals.contains(peripheral.identifier) {
                Logger.debug("Disconnecting peripheral: '\(peripheral.name)', \(peripheral.identifier.uuidString)")
                connectedPeripherals.remove(peripheral.identifier)
                peripheral.disconnect()
            }
        }
    }

    func connectPeripheralsIfNeccessay() {
        let maxConnections = ConfigStore.getMaximumPeripheralsConnected()
        var connectionCount = connectedPeripherals.count
        guard connectionCount < maxConnections else {
            return
        }
        let peripherals = self.peripheralsSortedByRSSI
        for peripheral in peripherals where connectionCount < maxConnections {
            if !connectedPeripherals.contains(peripheral.identifier) && !discoveredPeripherals.contains(peripheral.identifier) {
                Logger.debug("Connecting peripheral: '\(peripheral.name)', \(peripheral.identifier.uuidString)")
                connectedPeripherals.insert(peripheral.identifier)
                connect(peripheral)
                connectionCount += 1
            }
        }
    }

    func pollConnectionsAndUpdateIfNeeded() {
        guard shouldUpdateTable && isScanning else {
            return
        }
        Queue.main.delay(Params.updateConnectionsInterval) { [weak self] in
            Logger.debug("update table triggered")
            self.forEach { strongSelf in
                strongSelf.updateWhenActive()
                strongSelf.disconnectPeripheralsIfNecessary()
                strongSelf.pollConnectionsAndUpdateIfNeeded()
                if strongSelf.allPeripheralsDiscovered {
                    strongSelf.discoveredPeripherals.removeAll()
                    strongSelf.connectPeripheralsIfNeccessay()
                }
            }
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
                    strongSelf.discoverPeripheral(peripheral)
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
                    strongSelf.updateWhenActive()
                case .giveUp:
                    Logger.debug("GiveUp: '\(peripheral.name)', \(peripheral.identifier.uuidString)")
                    peripheral.stopPollingRSSI()
                    strongSelf.connectedPeripherals.remove(peripheral.identifier)
                    peripheral.terminate()
                    strongSelf.connectPeripheralsIfNeccessay()
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
    }

    func reconnectIfNecessary(_ peripheral: Peripheral) {
        guard peripheral.state != .connected && connectedPeripherals.contains(peripheral.identifier) else {
            connectPeripheralsIfNeccessay()
            return
        }
        peripheral.reconnect(withDelay: 1.0)
    }

    // MARK: Scanning

    func fetchCachedPeripheralsAndStartScan() {
        let scanMode = ConfigStore.getScanMode()
        switch scanMode {
        case .promiscuous:
            let discoveredPeripheralUUIDs = DiscoveredPeripheralStore.getPeripheralIdentifiers()
            let cachedPeripherals = Singletons.centralManager.retrievePeripherals(withIdentifiers: discoveredPeripheralUUIDs)
            DiscoveredPeripheralStore.setPeripheralIdentifiers(cachedPeripherals.map { $0.identifier })
        case .service:
            let scannedServices = ConfigStore.getScannedServiceUUIDs()
            _ = Singletons.centralManager.retrieveConnectedPeripherals(withServices: scannedServices)
        }
        updateWhenActive()
        connectPeripheralsIfNeccessay()
        startScan()
    }

    func startScan() {
        guard !reachedDiscoveryLimit else { return }
        guard !Singletons.centralManager.isScanning else { return }

        isScanning = true

        let future: FutureStream<Peripheral>
        let scanMode = ConfigStore.getScanMode()
        let scanTimeout = ConfigStore.getScanTimeoutEnabled() ? Double(ConfigStore.getScanTimeout()) : Double.infinity
        switch scanMode {
        case .promiscuous:
            future = Singletons.centralManager.startScanning(capacity:10, timeout: scanTimeout)
        case .service:
            let scannedServices = ConfigStore.getScannedServiceUUIDs()
            guard scannedServices.isEmpty == false else {
                self.present(UIAlertController.alertWithMessage("No scan services configured"), animated: true, completion: nil)
                return
            }
            future = Singletons.centralManager.startScanning(forServiceUUIDs:scannedServices, capacity: 10, timeout: scanTimeout)
        }
        future.onSuccess(completion: afterPeripheralDiscovered)
        future.onFailure(completion: afterTimeout)
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
        guard  Singletons.centralManager.peripherals.contains(peripheral) else { return }
        Logger.debug("Discovered peripheral: '\(peripheral.name)', \(peripheral.identifier.uuidString)")
        Notification.send("Discovered peripheral '\(peripheral.name)'")
        DiscoveredPeripheralStore.addPeripheralIdentifier(peripheral.identifier)
        connectPeripheralsIfNeccessay()
        updateWhenActive()
        if reachedDiscoveryLimit {
            Singletons.centralManager.stopScanning()
        }
    }

    // MARK: Peripheral discovery

    func discoverPeripheral(_ peripheral: Peripheral) {
        guard peripheral.state == .connected && !discoveredPeripherals.contains(peripheral.identifier) else {
            return
        }
        let peripheralDiscoveryFuture = peripheral.discoverAllServices().flatMap { peripheral in
            peripheral.services.map { $0.discoverAllCharacteristics() }.sequence()
        }
        peripheralDiscoveryFuture.onSuccess { [weak self] _ in
            self?.discoveredPeripherals.insert(peripheral.identifier)
        }
        peripheralDiscoveryFuture.onFailure { _ in
        }
    }

    // MARK: UITableViewDataSource

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
        if peripheral.state == .connected || peripheral.services.count > 0 {
            cell.nameLabel.textColor = UIColor.black
        } else {
            cell.nameLabel.textColor = UIColor.lightGray
        }
        if peripheral.state == .connected {
            cell.nameLabel.textColor = UIColor.black
            cell.stateLabel.text = "Connected"
            cell.stateLabel.textColor = UIColor(red:0.1, green:0.7, blue:0.1, alpha:0.5)
        } else if connectedPeripherals.contains(peripheral.identifier) {
            cell.stateLabel.text = "Connecting"
            cell.stateLabel.textColor = UIColor(red:0.7, green:0.1, blue:0.1, alpha:0.5)
        } else {
            cell.stateLabel.text = "Disconnected"
            cell.stateLabel.textColor = UIColor.lightGray
        }
//        if peripheral.RSSI == -127 || peripheral.RSSI == 0 {
//        } else {
//        }
        cell.servicesLabel.text = "\(peripheral.services.count)"
        return cell
    }
}
