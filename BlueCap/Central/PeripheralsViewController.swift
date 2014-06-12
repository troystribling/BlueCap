//
//  PeripheralsViewController.swift
//  BlueCapUI
//
//  Created by Troy Stribling on 6/5/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation
import UIKit
import BlueCapKit

let MAX_FAILED_RECONNECTS = 0

class PeripheralsViewController : UITableViewController {
    
    var stopScanBarButtonItem : UIBarButtonItem!
    var startScanBarButtonItem : UIBarButtonItem!
    var connectionSequence : Dictionary<Peripheral, Int> = [:]
    
    init(coder aDecoder:NSCoder!) {
        super.init(coder:aDecoder)
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.Bordered, target:nil, action:nil)
        self.stopScanBarButtonItem = UIBarButtonItem(barButtonSystemItem:.Stop, target:self, action:"toggleScan:")
        self.startScanBarButtonItem = UIBarButtonItem(barButtonSystemItem:.Refresh, target:self, action:"toggleScan:")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setScanButton()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // actions
    @IBAction func toggleScan(sender:AnyObject) {
        Logger.debug("toggleScan")
        let central = CentralManager.sharedinstance()
        if (central.isScanning) {
            central.stopScanning()
            self.setScanButton()
        } else {
            central.powerOn(){
                Logger.debug("powerOn Callback")
                central.startScanning(){(peripheral:Peripheral!, rssi:Int) -> () in
                    self.connect(peripheral)
                }
            }
        }
    }
    
    // UI
    func setScanButton() {
        if (CentralManager.sharedinstance().isScanning) {
            self.navigationItem.setRightBarButtonItem(self.stopScanBarButtonItem, animated:false)
        } else {
            self.navigationItem.setRightBarButtonItem(self.startScanBarButtonItem, animated:false)
        }
    }
    
    // connection
    func connect(peripheral:Peripheral) {
    }
    
    func reconnect(peripheral:Peripheral) {
    }
    
    func updateConnectionSequence(peripheral:Peripheral) {
        var count = self.connectionSequence[peripheral]
        if (count) {
            count = count! + 1
        } else {
            count = 0
        }
        self.connectionSequence[peripheral] = count
    }
    
    func resetConnectionSequence(peripheral:Peripheral) {
        self.connectionSequence[peripheral] = 0
    }
    
    func canReconnect(peripheral:Peripheral) -> Bool {
        var count = self.connectionSequence[peripheral]
        return count < MAX_FAILED_RECONNECTS
    }

}