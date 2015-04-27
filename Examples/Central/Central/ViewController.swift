//
//  ViewController.swift
//  Beacon
//
//  Created by Troy Stribling on 4/13/15.
//  Copyright (c) 2015 gnos.us. All rights reserved.
//

import UIKit
import CoreBluetooth
import BlueCapKit

class ViewController: UITableViewController {
    
    @IBOutlet var xAccelerationLabel        : UILabel!
    @IBOutlet var yAccelerationLabel        : UILabel!
    @IBOutlet var zAccelerationLabel        : UILabel!
    @IBOutlet var xRawAccelerationLabel     : UILabel!
    @IBOutlet var yRawAccelerationLabel     : UILabel!
    @IBOutlet var zRawAccelerationLabel     : UILabel!
    
    @IBOutlet var rawUpdatePeriodlabel      : UILabel!
    @IBOutlet var updatePeriodLabel         : UILabel!
    
    @IBOutlet var scanLabel                 : UILabel!
    @IBOutlet var scanSwitch                : UISwitch!
    @IBOutlet var enabledSwitch             : UISwitch!
    @IBOutlet var enabledLabel              : UILabel!
    @IBOutlet var disconnectButton          : UIButton!
    
    var peripheral : Peripheral?
    
    required init(coder aDecoder:NSCoder) {
        super.init(coder:aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if let peripheral = self.peripheral {
            
        } else {
            
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    @IBAction func toggleEnabled(sender:AnyObject) {
        if let peripheral = self.peripheral {
        }
    }
    
    @IBAction func toggleScan(sender:AnyObject) {
        if let peripheral = self.peripheral {
        }
    }
    
    @IBAction func disconnect(sender:AnyObject) {
        if let peripheral = self.peripheral {
        }
    }
    
    func startScanning() {
        if let uuid = CBUUID(string:TISensorTag.AccelerometerService.uuid) {
            let manager = CentralManager.sharedInstance
            // on power, start scanning and when peripoheral is discovered stop scanning
            let peripheraConnectFuture = manager.powerOn().flatmap {_ -> FutureStream<Peripheral> in
                manager.startScanningForServiceUUIDs([uuid], capacity:10)
            }.flatmap {peripheral -> FutureStream<Void> in
                if self.peripheral == nil {
                    let connectorator = Connectorator(capacity:10)
                    self.peripheral = peripheral
                    connectorator.onConnect()
                    manager.stopScanning()
                }
            }
            peripheraConnectFuture.onSuccess {
            }
            peripheraConnectFuture.onFailure {error in
                if error.domain == BCError.domain {
                    if let connectoratorError = ConnectoratorError(rawValue:error.code) {
                        switch connectoratorError {
                        case .Timeout:
                            Logger.debug(message:"Timeout: '\(peripheral.name)'")
                            peripheral.reconnect()
                        case .Disconnect:
                            Logger.debug(message:"Disconnect")
                            Notify.withMessage("Disconnected peripheral: '\(peripheral.name)'")
                            peripheral.reconnect()
                        case .ForceDisconnect:
                            Logger.debug(message:"ForcedDisconnect")
                        case .Failed:
                            Logger.debug(message:"Failed")
                            self.presentViewController(UIAlertController.alertOnError(error), animated:true, completion:nil)
                        case .GiveUp:
                            Logger.debug(message:"GiveUp: '\(peripheral.name)'")
                            peripheral.terminate()
                        }
                    } else {
                        self.presentViewController(UIAlertController.alertOnError(error), animated:true, completion:nil)
                    }
            }
//            // stop advertising and updating accelerometer on bluetooth power off
//            let powerOffFuture = manager.powerOff().flatmap { _ -> Future<Void> in
//            }
//            powerOffFuture?.onSuccess {
//            }
//            powerOffFuture?.onFailure {error in
//            }
//            // enable controls when bluetooth is powered on again after stop advertising is successul
//            let powerOffFutureSuccessFuture = powerOffFuture.flatmap {_ -> Future<Void> in
//            }
//            powerOffFutureSuccessFuture.onSuccess {
//            }
//            // enable controls when bluetooth is powered on again after stop advertising fails
//            let powerOffFutureFailedFuture = powerOffFuture.recoverWith {_  -> Future<Void> in
//            }
//            powerOffFutureFailedFuture.onSuccess {
//            }
        }
    }
    
}
