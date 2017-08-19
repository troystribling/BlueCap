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
    var peripheralDiscoveryFuture: FutureStream<[Void]>?

    var peripheralAdvertisements: PeripheralAdvertisements?

    let progressView  = ProgressView()

    var isUpdatingeRSSIAndPeripheralProperties = false

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
        connect()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(PeripheralViewController.didEnterBackground), name: NSNotification.Name.UIApplicationDidEnterBackground, object :nil)
        guard peripheral != nil else {
            _ = self.navigationController?.popToRootViewController(animated: false)
            return
        }
        updateConnectionStateLabel()
        resumeRSSIUpdatesAndPeripheralPropertiesUpdates()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        pauseRSSIUpdatesAndPeripheralPropertiesUpdates()
    }

    override func didMove(toParentViewController parent: UIViewController?) {
        if parent == nil {
            disconnect()
        }
    }
    
    override func prepare(for segue:UIStoryboardSegue, sender:Any!) {
        if segue.identifier == MainStoryBoard.peripheralServicesSegue {
            let viewController = segue.destination as! PeripheralServicesViewController
            viewController.peripheral = peripheral
            viewController.peripheralDiscoveryFuture = peripheralDiscoveryFuture
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
            return peripheral.services.count > 0 && peripheral.state == .connected
        } else if identifier == MainStoryBoard.peripehralAdvertisementsSegue {
            return true
        } else {
            return false
        }
    }

    @objc func didEnterBackground() {
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

    func updateRSSIUpdatesAndPeripheralPropertiesIfConnected() {
        guard isUpdatingeRSSIAndPeripheralProperties else {
            return
        }
        guard let peripheral = peripheral else {
            return
        }
        guard peripheral.state == .connected else {
            peripheral.stopPollingRSSI()
            return
        }
        let rssiFuture = peripheral.startPollingRSSI(period: Params.peripheralViewRSSIPollingInterval, capacity: Params.peripheralRSSIFutureCapacity)
        rssiFuture.onSuccess { [weak self] _ in
            self?.updatePeripheralProperties()
        }
    }

    func pauseRSSIUpdatesAndPeripheralPropertiesUpdates() {
        guard isUpdatingeRSSIAndPeripheralProperties else {
            return
        }
        guard let peripheral = peripheral else {
            return
        }
        isUpdatingeRSSIAndPeripheralProperties = false
        peripheral.stopPollingRSSI()
    }

    func resumeRSSIUpdatesAndPeripheralPropertiesUpdates() {
        guard !isUpdatingeRSSIAndPeripheralProperties else {
            return
        }
        isUpdatingeRSSIAndPeripheralProperties = true
        updateRSSIUpdatesAndPeripheralPropertiesIfConnected()
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

        let connectionTimeout = ConfigStore.getPeripheralConnectionTimeoutEnabled() ? Double(ConfigStore.getPeripheralConnectionTimeout()) : Double.infinity
        let scanTimeout = TimeInterval(ConfigStore.getCharacteristicReadWriteTimeout())

        peripheralDiscoveryFuture = peripheral.connect(connectionTimeout: connectionTimeout, capacity: 1).flatMap { [weak self, weak peripheral] () -> Future<Void> in
            guard let peripheral = peripheral else {
                throw AppError.unlikelyFailure
            }
            self?.updateConnectionStateLabel()
            return peripheral.discoverAllServices(timeout: scanTimeout)
        }.flatMap { [weak peripheral] ()  -> Future<[Void]> in
            guard let peripheral = peripheral else {
                throw AppError.unlikelyFailure
            }
            return peripheral.services.map { $0.discoverAllCharacteristics(timeout: scanTimeout) }.sequence()
        }

        peripheralDiscoveryFuture?.onSuccess { [weak self] _ -> Void in
            self.forEach { strongSelf in
                _ = strongSelf.progressView.remove()
                strongSelf.updateConnectionStateLabel()
                strongSelf.updateRSSIUpdatesAndPeripheralPropertiesIfConnected()
            }
        }

        peripheralDiscoveryFuture?.onFailure { [weak self] (error) -> Void in
            self.forEach { strongSelf in
                let maxTimeouts = ConfigStore.getPeripheralMaximumTimeoutsEnabled() ? ConfigStore.getPeripheralMaximumTimeouts() : UInt.max
                let maxDisconnections = ConfigStore.getPeripheralMaximumDisconnectionsEnabled() ? ConfigStore.getPeripheralMaximumDisconnections() : UInt.max
                switch error {
                case PeripheralError.forcedDisconnect:
                    Logger.debug("Connection force disconnect: '\(peripheral.name)', \(peripheral.identifier.uuidString)")
                case PeripheralError.connectionTimeout:
                    if peripheral.timeoutCount < maxTimeouts {
                        Logger.debug("Connection timeout: '\(peripheral.name)', \(peripheral.identifier.uuidString)")
                        strongSelf.updateConnectionStateLabel()
                        peripheral.reconnect(withDelay: 1.0)
                        return
                    }
                case PeripheralError.serviceDiscoveryTimeout:
                    Logger.debug("Service discovery timeout: '\(peripheral.name)', \(peripheral.identifier.uuidString)")
                    peripheral.disconnect()
                    return
                case ServiceError.characteristicDiscoveryTimeout:
                    Logger.debug("Characteristic discovery timeout: '\(peripheral.name)', \(peripheral.identifier.uuidString)")
                    peripheral.disconnect()
                    return
                default:
                    if peripheral.disconnectionCount < maxDisconnections {
                        peripheral.reconnect(withDelay: 1.0)
                        strongSelf.updateConnectionStateLabel()
                        Logger.debug("Disconnected: '\(error)', '\(peripheral.name)', \(peripheral.identifier.uuidString)")
                        return
                    }
                }
                strongSelf.stateLabel.text = "Disconnected"
                strongSelf.stateLabel.textColor = UIColor.lightGray
                strongSelf.updateConnectionStateLabel()
                strongSelf.updateRSSIUpdatesAndPeripheralPropertiesIfConnected()
                let progressViewFuture = strongSelf.progressView.remove()
                progressViewFuture.onSuccess { _ in
                    strongSelf.present(UIAlertController.alert(title: "Connection error", error: error) { _ in
                        _ = strongSelf.navigationController?.popToRootViewController(animated: true)
                    }, animated: true)
                }
            }
        }
    }

    func disconnect() {
        guard let peripheral = peripheral, peripheral.state != .disconnected else {
            return
        }
        peripheral.stopPollingRSSI()
        peripheral.disconnect()
    }

    // MARK: UITableViewDataSource

}
