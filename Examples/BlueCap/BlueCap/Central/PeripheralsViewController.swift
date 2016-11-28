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
    var shouldUpdateConnections = false
    var discoveryLimitReached = false

    var connectingPeripherals = Set<UUID>()
    var connectedPeripherals = Set<UUID>()
    var discoveredPeripherals = Set<UUID>()
    var removedPeripherals = Set<UUID>()
    var peripheralAdvertisments = [UUID : PeripheralAdvertisements]()

    var atDiscoveryLimit: Bool {
        return Singletons.discoveryManager.peripherals.count >= ConfigStore.getMaximumPeripheralsDiscovered()
    }

    var allPeripheralsConnected: Bool {
        return connectedPeripherals.count == Singletons.discoveryManager.peripherals.count
    }

    var peripheralsSortedByRSSI: [Peripheral] {
        return Singletons.discoveryManager.peripherals.sorted() { (p1, p2) -> Bool in
            guard let p1RSSI = Singletons.scanningManager.discoveredPeripherals[p1.identifier],
                  let p2RSSI = Singletons.scanningManager.discoveredPeripherals[p2.identifier] else {
                    return false
            }
            if (p1RSSI.RSSI == 127 || p1RSSI.RSSI == 0) && (p2RSSI.RSSI != 127  || p2RSSI.RSSI != 0) {
                return false
            }  else if (p1RSSI.RSSI != 127 || p1RSSI.RSSI != 0) && (p2RSSI.RSSI == 127 || p2RSSI.RSSI == 0) {
                return true
            } else if (p1RSSI.RSSI == 127 || p1RSSI.RSSI == 0) && (p2RSSI.RSSI == 127 || p2RSSI.RSSI == 0) {
                return true
            } else {
                return p1RSSI.RSSI >= p2RSSI.RSSI
            }
        }
    }

    var peripherals: [Peripheral] {
        if ConfigStore.getPeripheralSortOrder() == .discoveryDate {
            return Singletons.discoveryManager.peripherals
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
        Singletons.discoveryManager.whenStateChanges().onSuccess { state in
            Logger.debug("discoveryManager state changed: \(state)")
        }
        Singletons.communicationManager.whenStateChanges().onSuccess { state in
            Logger.debug("communicationManager state changed: \(state)")
        }
        Singletons.scanningManager.whenStateChanges().onSuccess { [weak self] state in
            self.forEach { strongSelf in
                Logger.debug("scanningManager state changed: \(state)")
                switch state {
                case .poweredOn:
                    break
                case .unknown:
                    break
                case .poweredOff, .unauthorized:
                    strongSelf.alertAndStopScanning(message: "DiscoveryManager state \"\(state)\"")
                case .resetting:
                    strongSelf.alertAndStopScanning(message:
                        "DiscoveryManager state \"\(state)\". The connection with the system bluetooth service was momentarily lost.\n Restart scan.")
                case .unsupported:
                    strongSelf.alertAndStopScanning(message: "DiscoveryManager state \"\(state)\". Bluetooth not supported.")
                }
            }
        }
    }

    func alertAndStopScanning(message: String) {
        present(UIAlertController.alert(message: message), animated:true) { [weak self] _ in
            self.forEach { strongSelf in
                strongSelf.stopScanning()
                strongSelf.setScanButton()
                Singletons.discoveryManager.reset()
                Singletons.scanningManager.reset()
                Singletons.communicationManager.reset()
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
        shouldUpdateConnections = true
        pollConnectionsAndUpdateIfNeeded()
        startPolllingRSSIForPeripherals()
        connectPeripheralsIfNeccessay()
        NotificationCenter.default.addObserver(self, selector:#selector(PeripheralsViewController.didBecomeActive), name: NSNotification.Name.UIApplicationDidBecomeActive, object:nil)
        NotificationCenter.default.addObserver(self, selector:#selector(PeripheralsViewController.didEnterBackground), name: NSNotification.Name.UIApplicationDidEnterBackground, object:nil)
        setScanButton()
        updateWhenActive()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
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
                viewController.peripheralDiscovered = discoveredPeripherals.contains(peripheral.identifier)
                viewController.peripheralAdvertisements = peripheralAdvertisments[peripheral.identifier]
            }
        }
    }

    func toggleScan(_ sender: AnyObject) {
        guard !Singletons.beaconManager.isMonitoring else {
            present(UIAlertController.alert(message: "iBeacon monitoring is active. Cannot scan and monitor iBeacons simutaneously. Stop iBeacon monitoring to start scan"), animated:true, completion:nil)
            return
        }
        guard Singletons.discoveryManager.poweredOn else {
            present(UIAlertController.alert(message: "Bluetooth is not enabled. Enable Bluetooth in settings."), animated:true, completion:nil)
            return
        }
        guard Singletons.scanningManager.poweredOn else {
            present(UIAlertController.alert(message: "Bluetooth is not enabled. Enable Bluetooth in settings."), animated:true, completion:nil)
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
        guard shouldUpdateConnections else {
            return
        }
        _ = peripheral.startPollingRSSI(period: Params.peripheralsViewRSSIPollingInterval, capacity: Params.peripheralRSSIFutureCapacity)
    }

    func startPolllingRSSIForPeripherals() {
        for peripheral in Singletons.discoveryManager.peripherals where connectingPeripherals.contains(peripheral.identifier) {
            self.startPollingRSSIForPeripheral(peripheral)
        }
    }

    func stopPollingRSSIForPeripherals() {
        for peripheral in Singletons.discoveryManager.peripherals {
            peripheral.stopPollingRSSI()
        }
    }

    // MARK: Peripheral Connection

    func disconnectConnectingPeripherals() {
        for peripheral in Singletons.discoveryManager.peripherals where connectingPeripherals.contains(peripheral.identifier) {
            connectedPeripherals.remove(peripheral.identifier)
            peripheral.disconnect()
        }
    }

    func disconnectPeripheralsIfNecessary() {
        let maxConnections = ConfigStore.getMaximumPeripheralsConnected()
        let peripherals = peripheralsSortedByRSSI
        guard maxConnections < peripherals.count else {
            return
        }

        for peripheral in peripherals {
            if connectingPeripherals.contains(peripheral.identifier) && connectedPeripherals.contains(peripheral.identifier) {
                Logger.debug("Disconnecting peripheral: '\(peripheral.name)', \(peripheral.identifier.uuidString)")
                connectingPeripherals.remove(peripheral.identifier)
                peripheral.disconnect()
            }
        }
    }

    func connectPeripheralsIfNeccessay() {
        guard shouldUpdateConnections else {
            Logger.debug("connection updates disabled")
            disconnectConnectingPeripherals()
            return
        }
        let maxConnections = ConfigStore.getMaximumPeripheralsConnected()
        var connectionCount = connectingPeripherals.count
        guard connectionCount < maxConnections else {
            Logger.debug("max connections reached")
            return
        }
        let peripherals = self.peripheralsSortedByRSSI
        for peripheral in peripherals where connectionCount < maxConnections {
            if !connectingPeripherals.contains(peripheral.identifier) && !connectedPeripherals.contains(peripheral.identifier) {
                Logger.debug("Connecting peripheral: '\(peripheral.name)', \(peripheral.identifier.uuidString)")
                connectingPeripherals.insert(peripheral.identifier)
                connect(peripheral)
                connectionCount += 1
            }
        }
    }

    func pollConnectionsAndUpdateIfNeeded() {
        guard shouldUpdateConnections && isScanning else {
            Logger.debug("connection updates disabled")
            return
        }
        Queue.main.delay(Params.updateConnectionsInterval) { [weak self] in
            Logger.debug("update table triggered")
            self.forEach { strongSelf in
                strongSelf.updateWhenActive()
                strongSelf.disconnectPeripheralsIfNecessary()
                strongSelf.pollConnectionsAndUpdateIfNeeded()
                if strongSelf.allPeripheralsConnected {
                    strongSelf.connectedPeripherals.removeAll()
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
                    strongSelf.startPollingRSSIForPeripheral(peripheral)
                    strongSelf.discoverPeripheral(peripheral)
                    strongSelf.connectedPeripherals.insert(peripheral.identifier)
                    strongSelf.updateWhenActive()
                case .timeout:
                    Logger.debug("Timeout: '\(peripheral.name)', \(peripheral.identifier.uuidString)")
                    peripheral.stopPollingRSSI()
                    strongSelf.reconnectIfNecessary(peripheral)
                    strongSelf.updateWhenActive()
                case .disconnect:
                    Logger.debug("Disconnected peripheral: '\(peripheral.name)', \(peripheral.identifier.uuidString)")
                    peripheral.stopPollingRSSI()
                    strongSelf.reconnectIfNecessary(peripheral)
                    strongSelf.updateWhenActive()
                case .forceDisconnect:
                    Logger.debug("Force disconnection of: '\(peripheral.name)', \(peripheral.identifier.uuidString)")
                    strongSelf.connectingPeripherals.remove(peripheral.identifier)
                    strongSelf.reconnectIfNecessary(peripheral)
                    strongSelf.updateWhenActive()
                case .giveUp:
                    Logger.debug("GiveUp: '\(peripheral.name)', \(peripheral.identifier.uuidString)")
                    peripheral.stopPollingRSSI()
                    strongSelf.connectingPeripherals.remove(peripheral.identifier)
                    strongSelf.connectedPeripherals.remove(peripheral.identifier)
                    strongSelf.removedPeripherals.insert(peripheral.identifier)
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
        guard peripheral.state != .connected && connectingPeripherals.contains(peripheral.identifier) else {
            connectPeripheralsIfNeccessay()
            return
        }
        peripheral.reconnect(withDelay: 1.0)
    }

    // MARK: Scanning

    func startScan() {
        guard !atDiscoveryLimit else { return }
        guard !Singletons.discoveryManager.isScanning else { return }

        isScanning = true

        let scanOptions =  discoveryLimitReached ? [ String : Any]() : [CBCentralManagerScanOptionAllowDuplicatesKey : true]

        let future: FutureStream<Peripheral>
        let scanMode = ConfigStore.getScanMode()
        let scanDuration = ConfigStore.getScanDurationEnabled() ? Double(ConfigStore.getScanDuration()) : Double.infinity
        switch scanMode {
        case .promiscuous:
            future = Singletons.scanningManager.startScanning(capacity:10, timeout: scanDuration, options: scanOptions)
        case .service:
            let scannedServices = ConfigStore.getScannedServiceUUIDs()
            guard scannedServices.isEmpty == false else {
                self.present(UIAlertController.alert(message: "No scan services configured"), animated: true, completion: nil)
                return
            }
            future = Singletons.scanningManager.startScanning(forServiceUUIDs: scannedServices, capacity: 10, timeout: scanDuration, options: scanOptions)
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
            stopScanning()
            self.setScanButton()
            present(UIAlertController.alert(message: "Bluetooth scan timeout."), animated:true, completion:nil)
        }
    }

    func afterPeripheralDiscovered(_ peripheral: Peripheral) -> Void {
        updateWhenActive()
        guard Singletons.discoveryManager.discoveredPeripherals[peripheral.identifier] == nil else {
            Logger.debug("Peripheral already discovered \(peripheral.name), \(peripheral.identifier.uuidString)")
            return
        }
        guard !removedPeripherals.contains(peripheral.identifier) else {
            Logger.debug("Peripheral has been removed \(peripheral.name), \(peripheral.identifier.uuidString)")
            return
        }
        guard Singletons.discoveryManager.retrievePeripherals(withIdentifiers: [peripheral.identifier]).first != nil else {
            Logger.debug("Discovered peripheral not found")
            return
        }
        Logger.debug("Discovered peripheral: '\(peripheral.name)', \(peripheral.identifier.uuidString)")
        peripheralAdvertisments[peripheral.identifier] = peripheral.advertisements
        connectPeripheralsIfNeccessay()
        if atDiscoveryLimit {
            discoveryLimitReached = true
            Singletons.scanningManager.stopScanning()
        }
    }

    func stopScanning() {
        if Singletons.scanningManager.isScanning {
            Singletons.scanningManager.stopScanning()
        }
        isScanning = false
        stopPollingRSSIForPeripherals()
        Singletons.communicationManager.disconnectAllPeripherals()
        Singletons.discoveryManager.removeAllPeripherals()
        Singletons.scanningManager.removeAllPeripherals()
        connectedPeripherals.removeAll()
        discoveredPeripherals.removeAll()
        removedPeripherals.removeAll()
        updateWhenActive()
    }


    // MARK: Peripheral discovery

    func discoverPeripheral(_ peripheral: Peripheral) {
        guard peripheral.state == .connected && !discoveredPeripherals.contains(peripheral.identifier) else {
            return
        }
        let scanTimeout = TimeInterval(ConfigStore.getCharacteristicReadWriteTimeout())
        let peripheralDiscoveryFuture = peripheral.discoverAllServices(timeout: scanTimeout).flatMap { peripheral in
            peripheral.services.map { $0.discoverAllCharacteristics(timeout: scanTimeout) }.sequence()
        }
        peripheralDiscoveryFuture.onSuccess { [weak self] _ in
            self?.discoveredPeripherals.insert(peripheral.identifier)
        }
        peripheralDiscoveryFuture.onFailure { _ in
            Logger.debug("Service discovery failed \(peripheral.name), \(peripheral.identifier.uuidString)")
        }
    }

    // MARK: UITableViewDataSource

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        return atDiscoveryLimit ? ConfigStore.getMaximumPeripheralsDiscovered() : Singletons.discoveryManager.peripherals.count
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
        } else if connectingPeripherals.contains(peripheral.identifier) {
            cell.stateLabel.text = "Connecting"
            cell.stateLabel.textColor = UIColor(red:0.7, green:0.1, blue:0.1, alpha:0.5)
        } else {
            cell.stateLabel.text = "Disconnected"
            cell.stateLabel.textColor = UIColor.lightGray
        }
        updateRSSI(peripheral: peripheral, cell: cell)
        cell.servicesLabel.text = "\(peripheral.services.count)"
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        shouldUpdateConnections = false
        Singletons.scanningManager.stopScanning()
        stopPollingRSSIForPeripherals()
        disconnectConnectingPeripherals()
    }

    func updateRSSI(peripheral: Peripheral, cell: PeripheralCell) {
        guard let discoveredPeripheral = Singletons.scanningManager.discoveredPeripherals[peripheral.identifier] else {
            cell.rssiImage.image = #imageLiteral(resourceName: "RSSI-0")
            cell.rssiLabel.text = "NA"
            return
        }
        cell.rssiLabel.text = "\(discoveredPeripheral.RSSI)"
        let rssiImage: UIImage
        switch discoveredPeripheral.RSSI {
        case (-40)...(-1):
            rssiImage = #imageLiteral(resourceName: "RSSI-5")
        case (-55)...(-41):
            rssiImage = #imageLiteral(resourceName: "RSSI-4")
        case (-70)...(-56):
            rssiImage = #imageLiteral(resourceName: "RSSI-3")
        case (-85)...(-71):
            rssiImage = #imageLiteral(resourceName: "RSSI-2")
        case (-99)...(-86):
            rssiImage = #imageLiteral(resourceName: "RSSI-1")
        default:
            rssiImage = #imageLiteral(resourceName: "RSSI-0")
        }
        cell.rssiImage.image = rssiImage
    }
}
