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
    @IBOutlet var servicesLabel: UILabel!
    @IBOutlet var scanTimeoutLabel: UILabel!
    @IBOutlet var scanTimeoutEnabledLabel: UILabel!
    @IBOutlet var peripheralMaxDisconnectionsLabel: UILabel!
    @IBOutlet var peripheralMaxTimeoutsLabel: UILabel!
    @IBOutlet var peripheralConnectionTimeout: UILabel!
    @IBOutlet var characteristicReadWriteTimeout: UILabel!
    @IBOutlet var maximumPeripheralsConnected: UILabel!
    @IBOutlet var maximumPeripheralsDiscovered: UILabel!
    @IBOutlet var peripheralSortOrder: UILabel!

    @IBOutlet var scanTimeoutSwitch: UISwitch!
    @IBOutlet var notifySwitch: UISwitch!

    struct MainStroryboard {
        static let configureScanServicesSegue = "ConfigureScanServices"
        static let configureScanModeSegue = "ConfigureScanMode"
        static let configureScanTimeoutSegue = "ConfigureScanTimeout"
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
        self.peripheralMaxDisconnectionsLabel.text = "\(ConfigStore.getMaximumDisconnections())"
        self.peripheralMaxTimeoutsLabel.text = "\(ConfigStore.getMaximumTimeouts())"
        self.peripheralConnectionTimeout.text = "\(ConfigStore.getPeripheralConnectionTimeout())s"
        self.characteristicReadWriteTimeout.text = "\(ConfigStore.getCharacteristicReadWriteTimeout())s"
        self.maximumPeripheralsConnected.text = "\(ConfigStore.getMaximumPeripheralsConnected())"
        self.maximumPeripheralsDiscovered.text = "\(ConfigStore.getMaximumPeripheralsDiscovered())"
        self.peripheralSortOrder.text = ConfigStore.getPeripheralSortOrder().stringValue
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
        if let identifier = identifier {
            switch(identifier) {
            case MainStroryboard.configureScanModeSegue:
                return true
            case MainStroryboard.configureScanServicesSegue:
                return true
            default:
                return true
            }
        } else {
            return false
        }
    }
        
    @IBAction func toggleScanTimeout(sender:AnyObject) {
        ConfigStore.setScanTimeoutEnabled(!ConfigStore.getScanTimeoutEnabled())
    }
    
    @IBAction func toggelNotification(sender:AnyObject) {
        Notify.setEnable(self.notifySwitch.on)
    }
 
    func configUI() {
        if  Singletons.centralManager.isScanning {
            self.scanTimeoutSwitch.enabled = false
            self.scanTimeoutEnabledLabel.textColor = UIColor.lightGrayColor()
        } else {
            self.scanTimeoutSwitch.enabled = true
            self.scanTimeoutEnabledLabel.textColor = UIColor.blackColor()
        }
        self.scanTimeoutSwitch.on = ConfigStore.getScanTimeoutEnabled()
    }

}
