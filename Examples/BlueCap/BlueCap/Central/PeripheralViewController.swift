//
//  PeripheralViewController.swift
//  BlueCap
//
//  Created by Troy Stribling on 6/16/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import UIKit
import CoreBluetooth
import BlueCapKit


class PeripheralViewController : UITableViewController {

    weak var peripheral: Peripheral?
    var peripheralAdvertisements: PeripheralAdvertisements?
    
    let progressView  = ProgressView()

    var peripheralDiscovered = false
    var shouldReconnect = true

    let dateFormatter = DateFormatter()

    @IBOutlet var uuidLabel: UILabel!
    @IBOutlet var rssiLabel: UILabel!
    @IBOutlet var stateLabel: UILabel!
    @IBOutlet var serviceLabel: UILabel!
    @IBOutlet var serviceCount: UILabel!

    @IBOutlet var discoveredAtLabel: UILabel!
    @IBOutlet var connectedAtLabel: UILabel!
    @IBOutlet var connectionsLabel: UILabel!
    @IBOutlet var disconnectionsLabel: UILabel!
    @IBOutlet var timeoutsLabel: UILabel!
    @IBOutlet var secondsConnectedLabel: UILabel!
    @IBOutlet var avgSecondsConnected: UILabel!
    
    struct MainStoryBoard {
        static let peripheralServicesSegue  = "PeripheralServices"
        static let peripehralAdvertisementsSegue = "PeripheralAdvertisements"
    }
    
    required init?(coder aDecoder:NSCoder) {
        super.init(coder:aDecoder)
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.plain, target:nil, action:nil)
        guard let peripheral = peripheral else {
            _ = self.navigationController?.popToRootViewController(animated: false)
            return
        }
        navigationItem.title = peripheral.name
        discoveredAtLabel.text = dateFormatter.string(from: peripheral.discoveredAt)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(PeripheralViewController.didEnterBackground), name: NSNotification.Name.UIApplicationDidEnterBackground, object :nil)
        guard peripheral != nil else {
            _ = self.navigationController?.popToRootViewController(animated: false)
            return
        }
        updateConnectionStateLabel()
        connect()
        toggleRSSIUpdatesAndPeripheralPropertiesUpdates()
        updatePeripheralProperties()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        disconnect()
        super.viewDidDisappear(animated)
    }
    
    override func prepare(for segue:UIStoryboardSegue, sender:Any!) {
        if segue.identifier == MainStoryBoard.peripheralServicesSegue {
            let viewController = segue.destination as! PeripheralServicesViewController
            viewController.peripheral = peripheral
        } else if segue.identifier == MainStoryBoard.peripehralAdvertisementsSegue {
            let viewController = segue.destination as! PeripheralAdvertisementsViewController
            viewController.peripheralAdvertisements = peripheralAdvertisements
        }
    }

    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        guard let peripheral = peripheral else {
            return false
        }
        if identifier == MainStoryBoard.peripheralServicesSegue {
            return peripheral.services.count > 0
        } else if identifier == MainStoryBoard.peripehralAdvertisementsSegue {
            return true
        } else {
            return false
        }
    }

    func didEnterBackground() {
        disconnect()
        _ = navigationController?.popToRootViewController(animated: false)
    }

    func updatePeripheralProperties() {
        guard let peripheral = peripheral else {
            return
        }
        if let connectedAt = peripheral.connectedAt {
            connectedAtLabel.text = dateFormatter.string(from: connectedAt)
        }
        rssiLabel.text = "\(peripheral.RSSI)"
        connectionsLabel.text = "\(peripheral.connectionCount)"
        secondsConnectedLabel.text = "\(Int(peripheral.cumlativeSecondsConnected))"
        if peripheral.connectionCount > 0 {
            avgSecondsConnected.text = "\(UInt(peripheral.cumlativeSecondsConnected) / peripheral.connectionCount)"
        } else {
            avgSecondsConnected.text = "0"
        }
        disconnectionsLabel.text = "\(peripheral.disconnectionCount)"
        timeoutsLabel.text = "\(peripheral.timeoutCount)"
    }

    func toggleRSSIUpdatesAndPeripheralPropertiesUpdates() {
        guard let peripheral = peripheral else {
            return
        }
        if peripheral.state == .connected {
            let rssiFuture = peripheral.startPollingRSSI(period: Params.peripheralViewRSSIPollingInterval, capacity: Params.peripheralRSSIFutureCapacity)
            rssiFuture.onSuccess { [weak self] _ in
                self?.updatePeripheralProperties()
            }
        } else {
            peripheral.stopPollingRSSI()
        }

    }

    func updateConnectionStateLabel() {
        guard let peripheral = peripheral else {
            return
        }
        switch peripheral.state {
        case .connected:
            stateLabel.text = "Connected"
            stateLabel.textColor = UIColor(red: 0.1, green: 0.7, blue: 0.1, alpha: 1.0)
        default:
            stateLabel.text = "Connecting"
            stateLabel.textColor = UIColor(red: 0.7, green: 0.1, blue: 0.1, alpha: 1.0)
        }
        serviceCount.text = "\(peripheral.services.count)"
    }

    func connect() {
        guard let peripheral = peripheral else {
            return
        }
        Logger.debug("Connect peripheral: '\(peripheral.name)'', \(peripheral.identifier.uuidString)")
        progressView.show()
        shouldReconnect = true
        let maxTimeouts = ConfigStore.getPeripheralMaximumTimeoutsEnabled() ? ConfigStore.getPeripheralMaximumTimeouts() : UInt.max
        let maxDisconnections = ConfigStore.getPeripheralMaximumDisconnectionsEnabled() ? ConfigStore.getPeripheralMaximumDisconnections() : UInt.max
        let connectionTimeout = ConfigStore.getPeripheralConnectionTimeoutEnabled() ? Double(ConfigStore.getPeripheralConnectionTimeout()) : Double.infinity
        let connectionFuture = peripheral.connect(timeoutRetries: maxTimeouts, disconnectRetries: maxDisconnections, connectionTimeout: connectionTimeout, capacity: 10)

        connectionFuture.onSuccess { [weak self] (peripheral, connectionEvent) in
            self.forEach { strongSelf in
                switch connectionEvent {
                case .connect:
                    strongSelf.updateConnectionStateLabel()
                    strongSelf.discoverPeripheralIfNeccessary()
                case .timeout:
                    strongSelf.reconnectIfNeccessay()
                case .disconnect:
                    strongSelf.reconnectIfNeccessay()
                case .forceDisconnect:
                    strongSelf.progressView.remove()
                case .giveUp:
                    strongSelf.progressView.remove()
                    strongSelf.stateLabel.text = "Disconnected"
                    strongSelf.stateLabel.textColor = UIColor.lightGray
                    strongSelf.present(UIAlertController.alert(message: "Connection to `\(peripheral.name)` failed"), animated:true, completion:nil)
                    break
                }
                strongSelf.toggleRSSIUpdatesAndPeripheralPropertiesUpdates()
            }
        }

        connectionFuture.onFailure { [weak self] error in
            self.forEach { strongSelf in
                strongSelf.stateLabel.text = "Disconnected"
                strongSelf.stateLabel.textColor = UIColor.lightGray
                strongSelf.toggleRSSIUpdatesAndPeripheralPropertiesUpdates()
                strongSelf.updateConnectionStateLabel()
                strongSelf.present(UIAlertController.alert(title: "Connection error", error: error) { _ in
                    strongSelf.progressView.remove()
                    _ = strongSelf.navigationController?.popToRootViewController(animated: true)
                }, animated: true)
            }
        }
    }

    func reconnectIfNeccessay() {
        guard let peripheral = peripheral, shouldReconnect else {
            return
        }
        peripheral.reconnect()
    }

    func disconnect() {
        guard let peripheral = peripheral, peripheral.state != .disconnected else {
            return
        }
        shouldReconnect = false
        peripheral.stopPollingRSSI()
        peripheral.disconnect()
    }

    // MARK: Peripheral discovery

    func discoverPeripheralIfNeccessary() {
        guard let peripheral = peripheral, peripheral.state == .connected && !peripheralDiscovered else {
            progressView.remove()
            return
        }
        let scanTimeout = TimeInterval(ConfigStore.getCharacteristicReadWriteTimeout())
        let peripheralDiscoveryFuture = peripheral.discoverAllServices(timeout: scanTimeout).flatMap { peripheral in
            peripheral.services.map { $0.discoverAllCharacteristics(timeout: scanTimeout) }.sequence()
        }
        peripheralDiscoveryFuture.onSuccess { [weak self] _ in
            self.forEach { strongSelf in
                strongSelf.progressView.remove()
                strongSelf.peripheralDiscovered = true
                strongSelf.updateConnectionStateLabel()
            }
        }
        peripheralDiscoveryFuture.onFailure { [weak self] (error) in
            self.forEach { strongSelf in
                strongSelf.present(UIAlertController.alert(title: "Peripheral discovery error", error: error) { _ in
                    strongSelf.progressView.remove()
                }, animated: true, completion: nil)
                Logger.debug("Service discovery failed")
            }
        }
    }

    // MARK: UITableViewDataSource
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 && indexPath.row == 0 {
            disconnect()
        }
    }

}
