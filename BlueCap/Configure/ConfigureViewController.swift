//
//  ConfigureViewController.swift
//  BlueCap
//
//  Created by Troy Stribling on 8/29/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import UIKit
import BlueCapKit

class ConfigureViewController : UITableViewController {
    
    @IBOutlet var scanModeLabel                     : UILabel!
    @IBOutlet var servicesLabel                     : UILabel!
    @IBOutlet var scanRegionsLabel                  : UILabel!
    @IBOutlet var scanRegionButton                  : UIButton!
    @IBOutlet var scanTimeoutLabel                  : UILabel!
    @IBOutlet var peripheralReconnectionsLabel      : UILabel!
    @IBOutlet var peripheralConnectionTimeout       : UILabel!
    @IBOutlet var characteristicReadWriteTimeout    : UILabel!
    @IBOutlet var scanTimeoutButton                 : UIButton!
    @IBOutlet var notifySwitch                      : UISwitch!
    
    var scanMode = "None"
    
    struct MainStroryboard {
        static let configureScanServicesSegue   = "ConfigureScanServices"
        static let configureScanRegionsSegue    = "ConfigureScanRegions"
        static let configureScanModeSegue       = "ConfigureScanMode"
        static let configureScanTimeoutSegue    = "ConfigureScanTimeout"
    }
    
    required init(coder aDecoder:NSCoder) {
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
        self.navigationItem.title = "Configure"
        self.configUI()
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
            case MainStroryboard.configureScanRegionsSegue:
                return  !RegionScannerator.sharedInstance().isScanning
            case MainStroryboard.configureScanServicesSegue:
                return !CentralManager.sharedInstance().isScanning && !RegionScannerator.sharedInstance().isScanning
            default:
                return true
            }
        } else {
            return false
        }
    }
    
    @IBAction func toggleScanRegion(sender:AnyObject) {
        ConfigStore.setRegionScanEnabled(!ConfigStore.getRegionScanEnabled())
        self.configUI()
    }
    
    @IBAction func toggleScanTimeout(sender:AnyObject) {
        ConfigStore.setScanTimeoutEnabled(!ConfigStore.getScanTimeoutEnabled())
        self.configUI()
    }
    
    @IBAction func toggelNotification(sender:AnyObject) {
        Notify.setEnable(enabled:self.notifySwitch.on)
    }
    
    func configUI() {
        if  CentralManager.sharedInstance().isScanning {
            self.servicesLabel.textColor = UIColor.lightGrayColor()
        } else {
            self.servicesLabel.textColor = UIColor.blackColor()
        }
        if  RegionScannerator.sharedInstance().isScanning {
            self.scanRegionsLabel.textColor = UIColor.lightGrayColor()
        } else {
            self.scanRegionsLabel.textColor = UIColor.blackColor()
        }
        if ConfigStore.getScanTimeoutEnabled() {
            self.scanTimeoutButton.setTitleColor(UIColor(red:0.1, green:0.7, blue:0.1, alpha:1.0), forState:UIControlState.Normal)
        } else {
            self.scanTimeoutButton.setTitleColor(UIColor(red:0.7, green:0.1, blue:0.1, alpha:1.0), forState:UIControlState.Normal)
        }
        if ConfigStore.getRegionScanEnabled() {
            self.scanRegionButton.setTitleColor(UIColor(red:0.1, green:0.7, blue:0.1, alpha:1.0), forState:UIControlState.Normal)
        } else {
            self.scanRegionButton.setTitleColor(UIColor(red:0.7, green:0.1, blue:0.1, alpha:1.0), forState:UIControlState.Normal)
        }
    }
}
