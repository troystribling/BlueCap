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

    @IBOutlet var scanTimeoutSwitch: UISwitch!
    @IBOutlet var scanTimeoutEnabledLabel: UILabel!
    @IBOutlet var scanTimeoutTitleLabel: UILabel!
    @IBOutlet var scanTimeoutLabel: UILabel!

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

    @IBOutlet var peripheralSortOrderTitleLabel: UILabel!
    @IBOutlet var peripheralSortOrderLabel: UILabel!

    @IBOutlet var notifySwitch: UISwitch!

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
        self.notifySwitch.on = Notify.getEnabled()
    }
    
    override func viewWillAppear(animated: Bool) {
        self.scanModeLabel.text = ConfigStore.getScanMode().stringValue
        self.scanTimeoutLabel.text = "\(ConfigStore.getScanTimeout())s"
        self.peripheralMaxDisconnectionsLabel.text = "\(ConfigStore.getPeripheralMaximumDisconnections())"
        self.peripheralMaxTimeoutsLabel.text = "\(ConfigStore.getPeripheralMaximumTimeouts())"
        self.peripheralConnectionTimeoutLabel.text = "\(ConfigStore.getPeripheralConnectionTimeout())s"
        self.characteristicReadWriteTimeoutLabel.text = "\(ConfigStore.getCharacteristicReadWriteTimeout())s"
        self.maximumPeripheralsConnectedLabel.text = "\(ConfigStore.getMaximumPeripheralsConnected())"
        self.maximumPeripheralsDiscoveredLabel.text = "\(ConfigStore.getMaximumPeripheralsDiscovered())"
        self.peripheralSortOrderLabel.text = ConfigStore.getPeripheralSortOrder().stringValue
        self.configUI()
        self.navigationItem.title = "Configure"
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationItem.title = ""
    }
    
    override func prepareForSegue(segue:UIStoryboardSegue, sender:AnyObject!) {
    }
    
    override func shouldPerformSegueWithIdentifier(identifier:String?, sender:AnyObject?) -> Bool {
        guard identifier != nil  else {
            return false
        }
        return !Singletons.centralManager.isScanning
    }
        
    @IBAction func toggleScanTimeout(_: AnyObject) {
        ConfigStore.setScanTimeoutEnabled(!ConfigStore.getScanTimeoutEnabled())
    }
    
    @IBAction func toggelNotification(_: AnyObject) {
        Notify.setEnable(self.notifySwitch.on)
    }

    @IBAction func toggelPeripheralConnectionTimeout(_: AnyObject) {
        ConfigStore.setPeripheralConnectionTimeoutEnabled(self.peripheralConnectionTimeoutSwitch.on)
    }

    @IBAction func togglePeripheralMaximumTimeouts(_: AnyObject) {
        ConfigStore.setPeripheralMaximumTimeoutsEnabled(self.peripheralMaxTimeoutsSwitch.on)
    }

    @IBAction func togglePeripheralMaximumDisconnections(_: AnyObject) {
        ConfigStore.setPeripheralMaximumDisconnectionsEnabled(self.peripheralMaxDisconnectionsSwitch.on)
    }

    func configUI() {
        self.scanModeTitleLabel.textColor = self.labelColorIfScanning()

        self.servicesLabel.textColor = self.labelColorIfScanning()

        self.scanTimeoutSwitch.on = ConfigStore.getScanTimeoutEnabled()
        self.scanTimeoutSwitch.enabled = self.enableIfScanning()
        self.scanTimeoutEnabledLabel.textColor = self.labelColorIfScanning()
        self.scanTimeoutTitleLabel.textColor = self.labelColorIfScanning()

        self.peripheralConnectionTimeoutSwitch.on = ConfigStore.getPeripheralConnectionTimeoutEnabled()
        self.peripheralConnectionTimeoutSwitch.enabled = self.enableIfScanning()
        self.peripheralConnectionTimeoutEnabledLabel.textColor = self.labelColorIfScanning()
        self.peripheralConnectionTimeoutTitleLabel.textColor = self.labelColorIfScanning()

        self.peripheralMaxTimeoutsSwitch.on = ConfigStore.getPeripheralMaximumTimeoutsEnabled()
        self.peripheralMaxTimeoutsSwitch.enabled = self.enableIfScanning()
        self.peripheralMaxTimeoutsEnabledLabel.textColor = self.labelColorIfScanning()
        self.peripheralMaxTimeoutsTitleLabel.textColor = self.labelColorIfScanning()

        self.peripheralMaxDisconnectionsSwitch.on = ConfigStore.getPeripheralMaximumDisconnectionsEnabled()
        self.peripheralMaxDisconnectionsSwitch.enabled = self.enableIfScanning()
        self.peripheralMaxDisconnectionsEnabledLabel.textColor = self.labelColorIfScanning()
        self.peripheralMaxDisconnectionsTitleLabel.textColor = self.labelColorIfScanning()

        self.characteristicReadWriteTimeoutTitleLabel.textColor = self.labelColorIfScanning()

        self.maximumPeripheralsConnectedTitleLabel.textColor = self.labelColorIfScanning()

        self.maximumPeripheralsDiscoveredTitleLabel.textColor = self.labelColorIfScanning()

        self.peripheralSortOrderTitleLabel.textColor = self.labelColorIfScanning()
    }

    func labelColorIfScanning() -> UIColor {
        if  Singletons.centralManager.isScanning {
            return UIColor.lightGrayColor()
        } else {
            return UIColor.blackColor()
        }
    }

    func enableIfScanning() -> Bool {
        return !Singletons.centralManager.isScanning
    }

}
