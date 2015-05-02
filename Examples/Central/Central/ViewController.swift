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
    case CharacteristicNotFound             = 4
}

public struct CenteralError {
    public static let domain = "Central Example"
    public static let dataCharacteristicNotFound = NSError(domain:domain, code:CentralExampleError.DataCharactertisticNotFound.rawValue, userInfo:[NSLocalizedDescriptionKey:"Accelerometer Data Chacateristic Not Found"])
    public static let enabledCharacteristicNotFound = NSError(domain:domain, code:CentralExampleError.EnabledCharactertisticNotFound.rawValue, userInfo:[NSLocalizedDescriptionKey:"Accelerometer Enabled Chacateristic Not Found"])
    public static let serviceNotFound = NSError(domain:domain, code:CentralExampleError.ServiceNotFound.rawValue, userInfo:[NSLocalizedDescriptionKey:"Accelerometer Service Not Found"])
    public static let characteristicNotFound = NSError(domain:domain, code:CentralExampleError.CharacteristicNotFound.rawValue, userInfo:[NSLocalizedDescriptionKey:"Accelerometer Characteristic Not Found"])
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
    
    @IBOutlet var activateSwitch            : UISwitch!
    @IBOutlet var enabledSwitch             : UISwitch!
    @IBOutlet var enabledLabel              : UILabel!
    @IBOutlet var statusLabel               : UILabel!
    
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
        self.updateUIStatus()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    @IBAction func toggleEnabled(sender:AnyObject) {
        if let peripheral = self.peripheral {
        }
    }
    
    @IBAction func toggleActivate(sender:AnyObject) {
        if self.activateSwitch.on  {
            self.startScanning()
        } else {
            CentralManager.sharedInstance.stopScanning()
            self.peripheral?.terminate()
            self.updateUIStatus()
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
                
            // on power, start scanning. when peripoheral is discovered connect and stop scanning
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
                    self.updateUIStatus()
                case .Timeout:
                    self.updateUIStatus()
                    peripheral.reconnect()
                case .Disconnect:
                    peripheral.reconnect()
                    self.updateUIStatus()
                case .ForceDisconnect:
                    self.presentViewController(UIAlertController.alertWithMessage("Disconnected"), animated:true, completion:nil)
                    self.updateUIStatus()
                case .Failed:
                    self.updateUIStatus()
                    self.presentViewController(UIAlertController.alertWithMessage("Connection Failed"), animated:true, completion:nil)
                case .GiveUp:
                    peripheral.terminate()
                    self.updateUIStatus()
                    self.presentViewController(UIAlertController.alertWithMessage("Giving up"), animated:true, completion:nil)
                }
            }
            peripheraConnectFuture.onFailure {error in
                self.presentViewController(UIAlertController.alertOnError(error), animated:true, completion:nil)
            }
                
            // discover sevices and characteristics and enable acclerometer
            let peripheralDiscoveredFuture = peripheraConnectFuture.flatmap {(peripheral, connectionEvent) -> Future<Peripheral> in
                peripheral.discoverPeripheralServices([serviceUUID])
            }.flatmap {peripheral -> Future<Characteristic> in
                if let service = peripheral.service(serviceUUID) {
                    self.accelerometerDataCharacteristic = service.characteristic(dataUUID)
                    self.accelerometerEnabledCharacteristic = service.characteristic(enabledUUID)
                    self.accelerometerUpdatePeriodCharacteristic = service.characteristic(updatePeriodUUID)
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
            }
            
            // subscribe to acceleration data updates
            let dataSubscriptionFuture = peripheralDiscoveredFuture.flatmap {_ -> Future<Characteristic> in
                if let accelerometerDataCharacteristic = self.accelerometerDataCharacteristic {
                    return accelerometerDataCharacteristic.startNotifying()
                } else {
                    let promise = Promise<Characteristic>()
                    promise.failure(CenteralError.characteristicNotFound)
                    return promise.future
                }
            }.flatmap {characteristic -> FutureStream<Characteristic> in
                return characteristic.recieveNotificationUpdates(capacity:10)
            }
            dataSubscriptionFuture.onSuccess {characteristic in
                self.updateData(characteristic)
            }
            dataSubscriptionFuture.onFailure {error in
                self.presentViewController(UIAlertController.alertOnError(error), animated:true, completion:nil)
            }
                
            // get enabled value
            let readEnabledFuture = peripheralDiscoveredFuture.flatmap {_ -> Future<Characteristic> in
                if let accelerometerEnabledCharacteristic = self.accelerometerEnabledCharacteristic {
                    return accelerometerEnabledCharacteristic.read(timeout:10.0)
                } else {
                    let promise = Promise<Characteristic>()
                    promise.failure(CenteralError.characteristicNotFound)
                    return promise.future
                }
            }
            readEnabledFuture.onSuccess {characteristic in
                self.updateEnabled(characteristic)
            }
            readEnabledFuture.onFailure {error in
                self.presentViewController(UIAlertController.alertOnError(error), animated:true, completion:nil)
            }
            
            // get update period value
            let readUpdatePeriod = peripheralDiscoveredFuture.flatmap {_ -> Future<Characteristic> in
                if let accelerometerUpdatePeriodCharacteristic = self.accelerometerUpdatePeriodCharacteristic {
                    return accelerometerUpdatePeriodCharacteristic.read(timeout:10.0)
                } else {
                    let promise = Promise<Characteristic>()
                    promise.failure(CenteralError.characteristicNotFound)
                    return promise.future
                }
            }
            readUpdatePeriod.onSuccess {characteristic in
                self.updatePeriod(characteristic)
            }
            readUpdatePeriod.onFailure {error in
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
    
    func updateUIStatus() {
        if let peripheral = self.peripheral {
            switch peripheral.state {
            case .Connected:
                self.statusLabel.text = "Connected"
                self.statusLabel.textColor = UIColor(red:0.2, green:0.7, blue:0.2, alpha:1.0)
            case .Connecting:
                self.statusLabel.text = "Connecting"
                self.statusLabel.textColor = UIColor(red:0.2, green:0.7, blue:0.7, alpha:1.0)
            case .Disconnected:
                self.statusLabel.text = "Disconnected"
                self.statusLabel.textColor = UIColor.lightGrayColor()
            }
        } else {
            self.statusLabel.text = "Disconnected"
            self.statusLabel.textColor = UIColor.lightGrayColor()
        }
    }
    
    func updateEnabled(characteristic:Characteristic) {
        if let value : TISensorTag.AccelerometerService.Enabled = characteristic.value() {
            self.enabledSwitch.on = value.boolValue
        }
    }

    func updatePeriod(characteristic:Characteristic) {
        if let value : TISensorTag.AccelerometerService.UpdatePeriod = characteristic.value() {
            self.updatePeriodLabel.text = "\(value.period)"
            self.rawUpdatePeriodlabel.text = "\(value.rawValue)"
        }
    }
    
    func updateData(characteristic:Characteristic) {
        if let data : TISensorTag.AccelerometerService.Data = characteristic.value() {
            self.xAccelerationLabel.text = NSString(format: "%.2f", data.x) as String
            self.yAccelerationLabel.text = NSString(format: "%.2f", data.y) as String
            self.zAccelerationLabel.text = NSString(format: "%.2f", data.z) as String
            let rawValue = data.rawValue
            self.xRawAccelerationLabel.text = "\(rawValue[0])"
            self.yRawAccelerationLabel.text = "\(rawValue[1])"
            self.zRawAccelerationLabel.text = "\(rawValue[2])"
        }
    }

}
