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

    weak var peripheral: Peripheral!

    var peripheralDiscovered = false

    let cancelToken = CancelToken()

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
        self.dateFormatter.dateStyle = .short
        self.dateFormatter.timeStyle = .short
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = self.peripheral.name
        discoveredAtLabel.text = dateFormatter.string(from: self.peripheral.discoveredAt)
        navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.plain, target:nil, action:nil)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        updateConnectionStateLabel()
        connect()
        toggleRSSIUpdatesAndPeripheralPropertiesUpdates()
        updatePeripheralProperties()

        NotificationCenter.default.addObserver(self, selector: #selector(PeripheralViewController.willResignActive), name: NSNotification.Name.UIApplicationWillResignActive, object :nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        self.peripheral.stopPollingRSSI()
        self.peripheral.disconnect()
        super.viewDidDisappear(animated)
    }
    
    override func prepare(for segue:UIStoryboardSegue, sender:Any!) {
        if segue.identifier == MainStoryBoard.peripheralServicesSegue {
            let viewController = segue.destination as! PeripheralServicesViewController
            viewController.peripheral = self.peripheral
            viewController.peripheralViewController = self
        } else if segue.identifier == MainStoryBoard.peripehralAdvertisementsSegue {
            let viewController = segue.destination as! PeripheralAdvertisementsViewController
            viewController.peripheral = self.peripheral
        }
    }

    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        guard identifier == MainStoryBoard.peripheralServicesSegue else {
            return false
        }
        return peripheral.services.count > 0
    }

    func willResignActive() {
        _ = self.navigationController?.popToRootViewController(animated: false)
    }

    func updatePeripheralProperties() {
        if let connectedAt = self.peripheral.connectedAt {
            connectedAtLabel.text = dateFormatter.string(from: connectedAt)
        }
        rssiLabel.text = "\(self.peripheral.RSSI)"
        connectionsLabel.text = "\(self.peripheral.connectionCount)"
        secondsConnectedLabel.text = "\(Int(self.peripheral.cumlativeSecondsConnected))"
        if peripheral.connectionCount > 0 {
            avgSecondsConnected.text = "\(Int(self.peripheral.cumlativeSecondsConnected) / self.peripheral.connectionCount)"
        } else {
            avgSecondsConnected.text = "0"
        }
        disconnectionsLabel.text = "\(self.peripheral.disconnectionCount)"
        timeoutsLabel.text = "\(self.peripheral.timeoutCount)"
    }

    func toggleRSSIUpdatesAndPeripheralPropertiesUpdates() {
        if peripheral.state == .connected {
            let rssiFuture = peripheral.startPollingRSSI(Params.peripheralViewRSSIPollingInterval, capacity: Params.peripheralRSSIFutureCapacity)
            rssiFuture.onSuccess { [weak self] _ in
                self?.updatePeripheralProperties()
            }
        } else {
            peripheral.stopPollingRSSI()
        }

    }

    func updateConnectionStateLabel() {
        switch peripheral.state {
        case .connected:
            stateLabel.text = "Connected"
            stateLabel.textColor = UIColor(red: 0.1, green: 0.7, blue: 0.1, alpha: 1.0)
        case .disconnected:
            stateLabel.text = "Disconnected"
            stateLabel.textColor = UIColor.lightGray
        default:
            stateLabel.text = "Connecting"
            stateLabel.textColor = UIColor(red: 0.7, green: 0.1, blue: 0.1, alpha: 1.0)
        }
        self.serviceCount.text = "\(self.peripheral.services.count)"
    }

    func connect() {
        Logger.debug("Connect peripheral: '\(peripheral.name)'', \(peripheral.identifier.uuidString)")
        let maxTimeouts = ConfigStore.getPeripheralMaximumTimeoutsEnabled() ? ConfigStore.getPeripheralMaximumTimeouts() : UInt.max
        let maxDisconnections = ConfigStore.getPeripheralMaximumDisconnectionsEnabled() ? ConfigStore.getPeripheralMaximumDisconnections() : UInt.max
        let connectionTimeout = ConfigStore.getPeripheralConnectionTimeoutEnabled() ? Double(ConfigStore.getPeripheralConnectionTimeout()) : Double.infinity
        let connectionFuture = peripheral.connect(timeoutRetries: maxTimeouts, disconnectRetries: maxDisconnections, connectionTimeout: connectionTimeout, capacity: 10)

        connectionFuture.onSuccess { [weak self] (peripheral, connectionEvent) in
            self.forEach { strongSelf in
                switch connectionEvent {
                case .connect:
                    break
                case .timeout:
                    peripheral.reconnect()
                case .disconnect:
                    peripheral.reconnect()
                case .forceDisconnect:
                    break;
                case .giveUp:
                    strongSelf.present(UIAlertController.alertWithMessage("Connection to `\(strongSelf.peripheral.name)` failed"), animated:true, completion:nil)
                    break
                }
                strongSelf.updateConnectionStateLabel()
                strongSelf.toggleRSSIUpdatesAndPeripheralPropertiesUpdates()
            }
        }

        connectionFuture.onFailure { [weak self] error in
            self.forEach { strongSelf in
                strongSelf.toggleRSSIUpdatesAndPeripheralPropertiesUpdates()
                strongSelf.updateConnectionStateLabel()
            }
        }
    }

    // MARK: Peripheral discovery

    func discoverPeripheral(_ peripheral: Peripheral) {
        guard peripheral.state == .connected && !peripheralDiscovered else {
            return
        }
        let peripheralDiscoveryFuture = peripheral.discoverAllServices().flatMap { peripheral in
            peripheral.services.map { $0.discoverAllCharacteristics() }.sequence()
        }
        peripheralDiscoveryFuture.onSuccess { [weak self] _ in
            self.forEach { strongSelf in
                strongSelf.peripheralDiscovered = true
                strongSelf.updateConnectionStateLabel()
            }
        }
        peripheralDiscoveryFuture.onFailure { _ in
            Logger.debug("Service discovery failed \(peripheral.name), \(peripheral.identifier.uuidString)")
        }
    }

}
