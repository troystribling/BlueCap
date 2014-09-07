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
    
    @IBOutlet var scanModeLabel     : UILabel!
    @IBOutlet var servicesLabel     : UILabel!
    @IBOutlet var scanRegionsLabel  : UILabel!
    @IBOutlet var scanRegionButton  : UIButton!
    
    var scanMode = "None"
    
    struct MainStroryboard {
        static let configureScanServicesSegue   = "ConfigureScanServices"
        static let configureScanRegionsSegue    = "ConfigureScanRegions"
        static let configureScanModeSegue       = "ConfigureScanMode"
    }
    
    required init(coder aDecoder:NSCoder) {
        super.init(coder:aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        self.scanMode = ConfigStore.getScanMode()
        self.scanModeLabel.text = self.scanMode
        self.scanModeLabel.text = ConfigStore.getScanMode()
        self.navigationItem.title = "Configure"
        self.configUI()
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationItem.title = ""
    }
    
    override func prepareForSegue(segue:UIStoryboardSegue!, sender:AnyObject!) {
    }
    
    override func shouldPerformSegueWithIdentifier(identifier:String!, sender:AnyObject!) -> Bool {
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
    }
    
    @IBAction func toggleScanRegion(sender:AnyObject) {
        ConfigStore.setRegionScanEnabled(!ConfigStore.getRegionScanEnabled())
        self.configUI()
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
        if ConfigStore.getRegionScanEnabled() {
            self.scanRegionButton.setTitleColor(UIColor(red:0.1, green:0.7, blue:0.1, alpha:1.0), forState:UIControlState.Normal)
        } else {
            self.scanRegionButton.setTitleColor(UIColor(red:0.7, green:0.1, blue:0.1, alpha:1.0), forState:UIControlState.Normal)
        }
    }
}
