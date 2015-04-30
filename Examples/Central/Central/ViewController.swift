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

public enum CentralExampleError : Int {
    case DataCharactertisticNotFound        = 1
    case EnabledCharactertisticNotFound     = 2
    case ServiceNotFound                    = 3
}

public struct CenteralError {
    public static let domain = "Central Example"
    public static let dataCharacteristicNotFound = NSError(domain:domain, code:CentralExampleError.DataCharactertisticNotFound.rawValue, userInfo:[NSLocalizedDescriptionKey:"Accelerometer Data Chacateristic Not Found"])
    public static let enabledCharacteristicNotFound = NSError(domain:domain, code:CentralExampleError.EnabledCharactertisticNotFound.rawValue, userInfo:[NSLocalizedDescriptionKey:"Accelerometer Enabled Chacateristic Not Found"])
    public static let serviceNotFound = NSError(domain:domain, code:CentralExampleError.ServiceNotFound.rawValue, userInfo:[NSLocalizedDescriptionKey:"Accelerometer Service Not Found"])
}

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
    
    var peripheral                                  : Peripheral?
    var accelerometerDataCharacteristic             : Characteristic?
    var accelerometerEnabledCharacteristic          : Characteristic?
    var accelerometerUpdatePeriodCharacteristic     : Characteristic?
    
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
        let manager = CentralManager.sharedInstance
        if manager.isScanning {
            manager.stopScanning()
        } else {
            self.startScanning()
        }
    }
    
    @IBAction func disconnect(sender:AnyObject) {
        if let peripheral = self.peripheral where peripheral.state != .Disconnected {
            peripheral.disconnect()
        }
    }
    
    func startScanning() {
        if let serviceUUID = CBUUID(string:TISensorTag.AccelerometerService.uuid),
               dataUUID = CBUUID(string:TISensorTag.AccelerometerService.Data.uuid),
               enabledUUID = CBUUID(string:TISensorTag.AccelerometerService.Enabled.uuid),
               updatePeriodUUID = CBUUID(string:TISensorTag.AccelerometerService.UpdatePeriod.uuid) {
                
            let manager = CentralManager.sharedInstance
                
            // on power, start scanning and when peripoheral is discovered connect and stop scanning
            let peripheraConnectFuture = manager.powerOn().flatmap {_ -> FutureStream<Peripheral> in
                manager.startScanningForServiceUUIDs([serviceUUID], capacity:10)
            }.flatmap {peripheral -> FutureStream<(Peripheral, ConnectionEvent)> in
                manager.stopScanning()
                self.peripheral = peripheral
                return peripheral.connect()
            }
            peripheraConnectFuture.onSuccess{(peripheral, connectionEvent) in
                switch connectionEvent {
                case .Connect:
                    self.enableDisconnectButton(true)
                    self.presentViewController(UIAlertController.alertWithMessage("Connected"), animated:true, completion:nil)
                case .Timeout:
                    peripheral.reconnect()
                case .Disconnect:
                    peripheral.reconnect()
                    self.enableDisconnectButton(false)
                case .ForceDisconnect:
                    self.presentViewController(UIAlertController.alertWithMessage("Disconnected"), animated:true, completion:nil)
                    self.enableDisconnectButton(false)
                case .Failed:
                    self.enableDisconnectButton(false)
                    self.presentViewController(UIAlertController.alertWithMessage("Connection Failed"), animated:true, completion:nil)
                case .GiveUp:
                    peripheral.terminate()
                    self.enableDisconnectButton(false)
                    self.presentViewController(UIAlertController.alertWithMessage("Giving up"), animated:true, completion:nil)
                }
            }
            peripheraConnectFuture.onFailure {error in
                self.presentViewController(UIAlertController.alertOnError(error), animated:true, completion:nil)
            }
            
            // discover sevices and characteristics enable acclerometer and subscribe to acceleration data updates
            let dataCharacteristicSubscribedFuture = peripheraConnectFuture.flatmap {(peripheral, connectionEvent) -> Future<Peripheral> in
                peripheral.discoverPeripheralServices([serviceUUID])
            }.flatmap {peripheral -> Future<Characteristic> in
                if let service = peripheral.service(serviceUUID) {
                    self.accelerometerDataCharacteristic = service.characteristic(dataUUID)
                    self.accelerometerEnabledCharacteristic = service.characteristic(enabledUUID)
                    if let accelerometerEnabledCharacteristic = self.accelerometerEnabledCharacteristic {
                        return accelerometerEnabledCharacteristic.write(TISensorTag.AccelerometerService.Enabled.Yes)
                    } else {
                        let promise = Promise<Characteristic>()
                        promise.failure(CenteralError.enabledCharacteristicNotFound)
                        return promise.future
                    }
                } else {
                    let promise = Promise<Characteristic>()
                    promise.failure(CenteralError.serviceNotFound)
                    return promise.future
                }
            }.flatmap {_ -> FutureStream<Characteristic> in
                if let accelerometerDataCharacteristic = self.accelerometerDataCharacteristic {
                    return accelerometerDataCharacteristic.recieveNotificationUpdates(capacity:10)
                } else {
                    let promise = StreamPromise<Characteristic>()
                    promise.failure(CenteralError.serviceNotFound)
                    return promise.future
                }
            }
            dataCharacteristicSubscribedFuture.onSuccess {_ in
                
            }
            dataCharacteristicSubscribedFuture.onFailure {error in
                self.presentViewController(UIAlertController.alertOnError(error), animated:true, completion:nil)
            }
            
            // handle bluetooth power off
            let powerOffFuture = manager.powerOff()
            powerOffFuture.onSuccess {
            }
            powerOffFuture.onFailure {error in
            }
            // enable controls when bluetooth is powered on again after stop advertising is successul
            let powerOffFutureSuccessFuture = powerOffFuture.flatmap {_ -> Future<Void> in
                manager.powerOn()
            }
            powerOffFutureSuccessFuture.onSuccess {
            }
            // enable controls when bluetooth is powered on again after stop advertising fails
            let powerOffFutureFailedFuture = powerOffFuture.recoverWith {_  -> Future<Void> in
                manager.powerOn()
            }
            powerOffFutureFailedFuture.onSuccess {
            }
        }
    }
    
    func enableDisconnectButton(enabled:Bool) {
        self.disconnectButton.enabled = enabled
        if enabled {
            self.disconnectButton.setTitleColor(UIColor.redColor(), forState:UIControlState.Normal)
            
        } else {
            self.disconnectButton.setTitleColor(UIColor.redColor(), forState:UIControlState.Normal)
        }
    }
    
}
