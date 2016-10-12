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
    let cancelToken = CancelToken()

    var peripheralConnected = true

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

        peripheralConnected = (self.peripheral.state == .connected)
        setConnectionStateLabel()
        toggleRSSIUpdates()
        updatePeripheralProperties()

        NotificationCenter.default.addObserver(self, selector: #selector(PeripheralViewController.willResignActive), name: NSNotification.Name.UIApplicationWillResignActive, object :nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        self.peripheral.stopPollingRSSI()
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

    func willResignActive() {
        _ = self.navigationController?.popToRootViewController(animated: false)
    }

    func updatePeripheralProperties() {
        if let connectedAt = self.peripheral.connectedAt {
            self.connectedAtLabel.text = dateFormatter.string(from: connectedAt)
        }
        self.rssiLabel.text = "\(self.peripheral.RSSI)"
        self.connectionsLabel.text = "\(self.peripheral.connectionCount)"
        self.secondsConnectedLabel.text = "\(Int(self.peripheral.cumlativeSecondsConnected))"
        if self.peripheral.connectionCount > 0 {
            self.avgSecondsConnected.text = "\(Int(self.peripheral.cumlativeSecondsConnected) / self.peripheral.connectionCount)"
        } else {
            self.avgSecondsConnected.text = "0"
        }
        self.disconnectionsLabel.text = "\(self.peripheral.disconnectionCount)"
        self.timeoutsLabel.text = "\(self.peripheral.timeoutCount)"
    }

    func toggleRSSIUpdates() {
        if self.peripheralConnected {
            let rssiFuture = self.peripheral.startPollingRSSI(Params.peripheralViewRSSIPollingInterval, capacity: Params.peripheralRSSIFutureCapacity)
            rssiFuture.onSuccess { [unowned self] _ in
                self.updatePeripheralProperties()
            }
        } else {
            self.peripheral.stopPollingRSSI()
        }

    }

    func setConnectionStateLabel() {
        if self.peripheralConnected {
            self.stateLabel.text = "Connected"
            self.stateLabel.textColor = UIColor(red: 0.1, green: 0.7, blue: 0.1, alpha: 1.0)
        } else {
            self.stateLabel.text = "Disconnected"
            self.stateLabel.textColor = UIColor(red: 0.7, green: 0.1, blue: 0.1, alpha: 1.0)
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
                    break
                case .disconnect:
                    break
                case .forceDisconnect:
                    break
                case .giveUp:
                    break
                }
            }
            self?.toggleRSSIUpdates()
        }

        connectionFuture.onFailure { [weak self] error in
            self?.toggleRSSIUpdates()
        }
    }

}
