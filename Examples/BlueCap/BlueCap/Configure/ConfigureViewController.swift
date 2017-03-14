//
//  ConfigureViewController.swift
//  BlueCap
//
//  Created by Troy Stribling on 8/29/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import UIKit
import BlueCapKit

class ConfigureViewController : UITableViewController {
    
    @IBOutlet var scanModeLabel: UILabel!
    @IBOutlet var scanModeTitleLabel: UILabel!

    @IBOutlet var servicesLabel: UILabel!

    @IBOutlet var scanDurationSwitch: UISwitch!
    @IBOutlet var scanDurationEnabledLabel: UILabel!
    @IBOutlet var scanDurationTitleLabel: UILabel!
    @IBOutlet var scanDurationLabel: UILabel!

    @IBOutlet var peripheralConnectionTimeoutSwitch: UISwitch!
    @IBOutlet var peripheralConnectionTimeoutEnabledLabel: UILabel!
    @IBOutlet var peripheralConnectionTimeoutTitleLabel: UILabel!
    @IBOutlet var peripheralConnectionTimeoutLabel: UILabel!

    @IBOutlet var peripheralMaxTimeoutsSwitch: UISwitch!
    @IBOutlet var peripheralMaxTimeoutsEnabledLabel: UILabel!
    @IBOutlet var peripheralMaxTimeoutsTitleLabel: UILabel!
    @IBOutlet var peripheralMaxTimeoutsLabel: UILabel!

    @IBOutlet var peripheralMaxDisconnectionsSwitch: UISwitch!
    @IBOutlet var peripheralMaxDisconnectionsEnabledLabel: UILabel!
    @IBOutlet var peripheralMaxDisconnectionsTitleLabel: UILabel!
    @IBOutlet var peripheralMaxDisconnectionsLabel: UILabel!

    @IBOutlet var characteristicReadWriteTimeoutTitleLabel: UILabel!
    @IBOutlet var characteristicReadWriteTimeoutLabel: UILabel!

    @IBOutlet var maximumPeripheralsConnectedTitleLabel: UILabel!
    @IBOutlet var maximumPeripheralsConnectedLabel: UILabel!

    @IBOutlet var maximumPeripheralsDiscoveredTitleLabel: UILabel!
    @IBOutlet var maximumPeripheralsDiscoveredLabel: UILabel!

    struct MainStroryboard {
        static let configureScanServicesSegue = "ConfigureScanServices"
        static let configureScanModeSegue = "ConfigureScanMode"
        static let configureScanTimeoutSegue = "ConfigureScanTimeout"
        static let configurePeripheralSortOrder = "ConfigurePeripheralSortOrder"
        static let characteristicReadWriteTimeout = "CharacteristicReadWriteTimeout"
        static let configurePeripheralConnectionTimeout = "ConfigurePeripheralConnectionTimeout"
        static let configurePeripheralMaxDisconnections = "ConfigurePeripheralMaxDisconnections"
        static let configurePeripheralMaxTimeouts = "ConfigurePeripheralMaxTimeouts"
        static let configureMaxPeripheralConnections = "ConfigureMaxPeripheralConnections"
        static let configuredMaxPeripheralDiscovered = "ConfiguredMaxPeripheralDiscovered"
    }
    
    required init?(coder aDecoder:NSCoder) {
        super.init(coder:aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.styleNavigationBar()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.scanModeLabel.text = ConfigStore.getScanMode().stringValue
        self.scanDurationLabel.text = "\(ConfigStore.getScanDuration())s"
        self.peripheralMaxDisconnectionsLabel.text = "\(ConfigStore.getPeripheralMaximumDisconnections())"
        self.peripheralMaxTimeoutsLabel.text = "\(ConfigStore.getPeripheralMaximumTimeouts())"
        self.peripheralConnectionTimeoutLabel.text = "\(ConfigStore.getPeripheralConnectionTimeout())s"
        self.characteristicReadWriteTimeoutLabel.text = "\(ConfigStore.getCharacteristicReadWriteTimeout())s"
        self.maximumPeripheralsConnectedLabel.text = "\(ConfigStore.getMaximumPeripheralsConnected())"
        self.maximumPeripheralsDiscoveredLabel.text = "\(ConfigStore.getMaximumPeripheralsDiscovered())"
        self.configUI()
        self.navigationItem.title = "Configure"
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationItem.title = ""
    }
    
    override func prepare(for segue:UIStoryboardSegue, sender:Any!) {
    }
    
    override func shouldPerformSegue(withIdentifier identifier:String?, sender:Any?) -> Bool {
        guard identifier != nil  else {
            return false
        }
        return !Singletons.scanningManager.isScanning
    }
        
    @IBAction func toggleScanTimeout(_: AnyObject) {
        ConfigStore.setScanDurationEnabled(!ConfigStore.getScanDurationEnabled())
    }
    
    @IBAction func toggelNotification(_: AnyObject) {
    }

    @IBAction func toggelPeripheralConnectionTimeout(_: AnyObject) {
        ConfigStore.setPeripheralConnectionTimeoutEnabled(self.peripheralConnectionTimeoutSwitch.isOn)
    }

    @IBAction func togglePeripheralMaximumTimeouts(_: AnyObject) {
        ConfigStore.setPeripheralMaximumTimeoutsEnabled(self.peripheralMaxTimeoutsSwitch.isOn)
    }

    @IBAction func togglePeripheralMaximumDisconnections(_: AnyObject) {
        ConfigStore.setPeripheralMaximumDisconnectionsEnabled(self.peripheralMaxDisconnectionsSwitch.isOn)
    }

    func configUI() {
        self.scanModeTitleLabel.textColor = self.labelColorIfScanning()

        self.servicesLabel.textColor = self.labelColorIfScanning()

        self.scanDurationSwitch.isOn = ConfigStore.getScanDurationEnabled()
        self.scanDurationSwitch.isEnabled = self.enableIfNotScanning()
        self.scanDurationEnabledLabel.textColor = self.labelColorIfScanning()
        self.scanDurationTitleLabel.textColor = self.labelColorIfScanning()

        self.peripheralConnectionTimeoutSwitch.isOn = ConfigStore.getPeripheralConnectionTimeoutEnabled()
        self.peripheralConnectionTimeoutSwitch.isEnabled = self.enableIfNotScanning()
        self.peripheralConnectionTimeoutEnabledLabel.textColor = self.labelColorIfScanning()
        self.peripheralConnectionTimeoutTitleLabel.textColor = self.labelColorIfScanning()

        self.peripheralMaxTimeoutsSwitch.isOn = ConfigStore.getPeripheralMaximumTimeoutsEnabled()
        self.peripheralMaxTimeoutsSwitch.isEnabled = self.enableIfNotScanning()
        self.peripheralMaxTimeoutsEnabledLabel.textColor = self.labelColorIfScanning()
        self.peripheralMaxTimeoutsTitleLabel.textColor = self.labelColorIfScanning()

        self.peripheralMaxDisconnectionsSwitch.isOn = ConfigStore.getPeripheralMaximumDisconnectionsEnabled()
        self.peripheralMaxDisconnectionsSwitch.isEnabled = self.enableIfNotScanning()
        self.peripheralMaxDisconnectionsEnabledLabel.textColor = self.labelColorIfScanning()
        self.peripheralMaxDisconnectionsTitleLabel.textColor = self.labelColorIfScanning()

        self.characteristicReadWriteTimeoutTitleLabel.textColor = self.labelColorIfScanning()

        self.maximumPeripheralsConnectedTitleLabel.textColor = self.labelColorIfScanning()

        self.maximumPeripheralsDiscoveredTitleLabel.textColor = self.labelColorIfScanning()
    }

    func labelColorIfScanning() -> UIColor {
        if  Singletons.scanningManager.isScanning {
            return UIColor.lightGray
        } else {
            return UIColor.black
        }
    }

    func enableIfNotScanning() -> Bool {
        return !Singletons.scanningManager.isScanning
    }

}
