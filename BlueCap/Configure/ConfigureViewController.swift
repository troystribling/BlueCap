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
    
    @IBOutlet var scanModeLabel                     : UILabel!
    @IBOutlet var servicesLabel                     : UILabel!
    @IBOutlet var scanTimeoutLabel                  : UILabel!
    @IBOutlet var scanTimeoutEnabledLabel           : UILabel!
    @IBOutlet var peripheralReconnectionsLabel      : UILabel!
    @IBOutlet var peripheralConnectionTimeout       : UILabel!
    @IBOutlet var characteristicReadWriteTimeout    : UILabel!
    @IBOutlet var scanTimeoutSwitch                 : UISwitch!
    @IBOutlet var notifySwitch                      : UISwitch!
    
    var scanMode = "None"
    
    struct MainStroryboard {
        static let configureScanServicesSegue   = "ConfigureScanServices"
        static let configureScanModeSegue       = "ConfigureScanMode"
        static let configureScanTimeoutSegue    = "ConfigureScanTimeout"
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
        self.scanMode = ConfigStore.getScanMode()
        self.scanModeLabel.text = self.scanMode
        self.scanTimeoutLabel.text = "\(ConfigStore.getScanTimeout())s"
        self.peripheralReconnectionsLabel.text = "\(ConfigStore.getMaximumReconnections())"
        self.peripheralConnectionTimeout.text = "\(ConfigStore.getPeripheralConnectionTimeout())s"
        self.characteristicReadWriteTimeout.text = "\(ConfigStore.getCharacteristicReadWriteTimeout())s"
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
        if  CentralManager.sharedInstance.isScanning {
            self.scanTimeoutSwitch.enabled = false
            self.scanTimeoutEnabledLabel.textColor = UIColor.lightGrayColor()
        } else {
            self.scanTimeoutSwitch.enabled = true
            self.scanTimeoutEnabledLabel.textColor = UIColor.blackColor()
        }
        self.scanTimeoutSwitch.on = ConfigStore.getScanTimeoutEnabled()
    }

}
