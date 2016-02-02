//
//  ViewController.swift
//  Beacon
//
//  Created by Troy Stribling on 4/13/15.
//  Copyright (c) 2015 Troy Stribling. The MIT License (MIT).
//

import UIKit
import CoreBluetooth
import BlueCapKit

public enum CentralExampleError : Int {
    case DataCharactertisticNotFound        = 1
    case EnabledCharactertisticNotFound     = 2
    case ServiceNotFound                    = 3
    case CharacteristicNotFound             = 4
    case PeripheralNotConnected             = 5
}

public struct CenteralError {
    public static let domain = "Central Example"
    public static let dataCharacteristicNotFound = NSError(domain:domain, code:CentralExampleError.DataCharactertisticNotFound.rawValue, userInfo:[NSLocalizedDescriptionKey:"Accelerometer Data Chacateristic Not Found"])
    public static let enabledCharacteristicNotFound = NSError(domain:domain, code:CentralExampleError.EnabledCharactertisticNotFound.rawValue, userInfo:[NSLocalizedDescriptionKey:"Accelerometer Enabled Chacateristic Not Found"])
    public static let serviceNotFound = NSError(domain:domain, code:CentralExampleError.ServiceNotFound.rawValue, userInfo:[NSLocalizedDescriptionKey:"Accelerometer Service Not Found"])
    public static let characteristicNotFound = NSError(domain:domain, code:CentralExampleError.CharacteristicNotFound.rawValue, userInfo:[NSLocalizedDescriptionKey:"Accelerometer Characteristic Not Found"])
    public static let peripheralNotConnected = NSError(domain:domain, code:CentralExampleError.CharacteristicNotFound.rawValue, userInfo:[NSLocalizedDescriptionKey:"Peripheral not connected"])
}

class ViewController: UITableViewController {
    
    struct MainStoryboard {
        static let updatePeriodValueSegue = "UpdatePeriodValue"
        static let updatePeriodRawValueSegue = "UpdatePeriodRawValue"
    }

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
    
    required init?(coder aDecoder:NSCoder) {
        super.init(coder:aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.updateUIStatus()
        self.readUpdatePeriod()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == MainStoryboard.updatePeriodValueSegue {
            let viewController = segue.destinationViewController as! SetUpdatePeriodViewController
            viewController.characteristic = self.accelerometerUpdatePeriodCharacteristic
            viewController.isRaw = false
        } else if segue.identifier == MainStoryboard.updatePeriodRawValueSegue {
            let viewController = segue.destinationViewController as! SetUpdatePeriodViewController
            viewController.characteristic = self.accelerometerUpdatePeriodCharacteristic
            viewController.isRaw = true
        }

    }
    
    @IBAction func toggleEnabled(sender:AnyObject) {
        if let peripheral = self.peripheral where peripheral.state == .Connected {
            self.writeEnabled()
        }
    }
    
    @IBAction func toggleActivate(sender:AnyObject) {
        if self.activateSwitch.on  {
            self.activate()
        } else {
            self.deactivate()
        }
    }
    
    @IBAction func disconnect(sender:AnyObject) {
        if let peripheral = self.peripheral where peripheral.state != .Disconnected {
            peripheral.disconnect()
        }
    }
    
    func activate() {
        let serviceUUID = CBUUID(string:TISensorTag.AccelerometerService.uuid)
        let dataUUID = CBUUID(string:TISensorTag.AccelerometerService.Data.uuid)
        let enabledUUID = CBUUID(string:TISensorTag.AccelerometerService.Enabled.uuid)
        let updatePeriodUUID = CBUUID(string:TISensorTag.AccelerometerService.UpdatePeriod.uuid)
                
        let manager = CentralManager.sharedInstance
            
        // on power, start scanning. when peripoheral is discovered connect and stop scanning
        let peripheraConnectFuture = manager.powerOn().flatmap {_ -> FutureStream<Peripheral> in
            manager.startScanningForServiceUUIDs([serviceUUID], capacity:10)
        }.flatmap {peripheral -> FutureStream<(Peripheral, ConnectionEvent)> in
            manager.stopScanning()
            self.peripheral = peripheral
            return peripheral.connect(10, timeoutRetries:5, disconnectRetries:5)
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
            
        // discover sevices and characteristics and enable acclerometer
        let peripheralDiscoveredFuture = peripheraConnectFuture.flatmap {(peripheral, connectionEvent) -> Future<Peripheral> in
            if peripheral.state == .Connected {
                return peripheral.discoverPeripheralServices([serviceUUID])
            } else {
                let promise = Promise<Peripheral>()
                promise.success(peripheral)
                return promise.future
            }
        }
        peripheralDiscoveredFuture.onSuccess {peripheral in
            if let service = peripheral.service(serviceUUID) {
                self.accelerometerDataCharacteristic = service.characteristic(dataUUID)
                self.accelerometerEnabledCharacteristic = service.characteristic(enabledUUID)
                self.accelerometerUpdatePeriodCharacteristic = service.characteristic(updatePeriodUUID)
            }
        }

        // get enabled value
        let readEnabledFuture = peripheralDiscoveredFuture.flatmap {_ -> Future<Characteristic> in
            if let accelerometerEnabledCharacteristic = self.accelerometerEnabledCharacteristic {
                return accelerometerEnabledCharacteristic.read(10.0)
            } else {
                let promise = Promise<Characteristic>()
                promise.failure(CenteralError.characteristicNotFound)
                return promise.future
            }
        }
        readEnabledFuture.onSuccess {characteristic in
            self.updateEnabled(characteristic)
        }
        
        // get update period value
        let readUpdatePeriodFuture = readEnabledFuture.flatmap {_ -> Future<Characteristic> in
            if let accelerometerUpdatePeriodCharacteristic = self.accelerometerUpdatePeriodCharacteristic {
                return accelerometerUpdatePeriodCharacteristic.read(10.0)
            } else {
                let promise = Promise<Characteristic>()
                promise.failure(CenteralError.characteristicNotFound)
                return promise.future
            }
        }
        readUpdatePeriodFuture.onSuccess {characteristic in
            self.updatePeriod(characteristic)
        }

        // subscribe to acceleration data updates
        let dataSubscriptionFuture = readUpdatePeriodFuture.flatmap {_ -> Future<Characteristic> in
            if let accelerometerDataCharacteristic = self.accelerometerDataCharacteristic {
                return accelerometerDataCharacteristic.startNotifying()
            } else {
                let promise = Promise<Characteristic>()
                promise.failure(CenteralError.characteristicNotFound)
                return promise.future
            }
        }
        dataSubscriptionFuture.onFailure {error in
            if error.domain != CenteralError.domain || error.code == CentralExampleError.PeripheralNotConnected.rawValue {
                self.presentViewController(UIAlertController.alertOnError(error), animated:true, completion:nil)
            }
        }

        dataSubscriptionFuture.flatmap {characteristic -> FutureStream<Characteristic> in
            return characteristic.receiveNotificationUpdates(10)
        }.onSuccess {characteristic in
            self.updateData(characteristic)
        }
            
        // handle bluetooth power off
        let powerOffFuture = manager.powerOff()
        powerOffFuture.onSuccess {
            self.deactivate()
        }
        powerOffFuture.onFailure {error in
            Logger.debug("powerOffFuture failure")
        }
        // enable controls when bluetooth is powered on again after stop advertising is successul
        let powerOffFutureSuccessFuture = powerOffFuture.flatmap {_ -> Future<Void> in
            manager.powerOn()
        }
        powerOffFutureSuccessFuture.onSuccess {
            self.presentViewController(UIAlertController.alertWithMessage("restart application"), animated:true, completion:nil)
        }
        // enable controls when bluetooth is powered on again after stop advertising fails
        let powerOffFutureFailedFuture = powerOffFuture.recoverWith {_  -> Future<Void> in
            manager.powerOn()
        }
        powerOffFutureFailedFuture.onSuccess {
            if CentralManager.sharedInstance.poweredOn {
                self.presentViewController(UIAlertController.alertWithMessage("restart application"), animated:true, completion:nil)
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
                self.statusLabel.textColor = UIColor(red:0.9, green:0.7, blue:0.0, alpha:1.0)
            case .Disconnected:
                self.statusLabel.text = "Disconnected"
                self.statusLabel.textColor = UIColor.lightGrayColor()
            case .Disconnecting:
                self.statusLabel.text = "Disconnecting"
                self.statusLabel.textColor = UIColor.lightGrayColor()
            }
            if peripheral.state == .Connected {
                self.enabledLabel.textColor = UIColor.blackColor()
                self.enabledSwitch.enabled = true
            } else {
                self.enabledLabel.textColor = UIColor.lightGrayColor()
                self.enabledSwitch.enabled = false
                self.enabledSwitch.on = false
            }
        } else {
            self.statusLabel.text = "Disconnected"
            self.statusLabel.textColor = UIColor.lightGrayColor()
            self.enabledLabel.textColor = UIColor.lightGrayColor()
            self.enabledSwitch.on = false
            self.enabledSwitch.enabled = false
            self.activateSwitch.on = false
        }
    }
    
    func updateEnabled(characteristic:Characteristic) {
        if let data = characteristic.stringValue, value = data.values.first {
            self.enabledSwitch.on = value == "Yes"
        }
    }

    func updatePeriod(characteristic:Characteristic) {
        if let data = characteristic.stringValue, period = data["period"], rawPeriod = data["periodRaw"] {
            self.updatePeriodLabel.text = period
            self.rawUpdatePeriodlabel.text = rawPeriod
        }
    }

    func readUpdatePeriod() {
        let readFuture = self.accelerometerUpdatePeriodCharacteristic?.read(10.0)
        readFuture?.onSuccess {characteristic in
            self.updatePeriod(characteristic)
        }
        readFuture?.onFailure{error in
            self.presentViewController(UIAlertController.alertOnError(error), animated:true, completion:nil)
        }
    }

    func updateData(characteristic:Characteristic) {
            if let data = characteristic.stringValue,
                x = data["x"], y = data["y"], z = data["z"],
                xRaw = data["xRaw"], yRaw = data["yRaw"], zRaw = data["zRaw"] {
            self.xAccelerationLabel.text = x
            self.yAccelerationLabel.text = y
            self.zAccelerationLabel.text = z
            self.xRawAccelerationLabel.text = xRaw
            self.yRawAccelerationLabel.text = yRaw
            self.zRawAccelerationLabel.text = zRaw
        }
    }

    func writeEnabled() {
        if let accelerometerEnabledCharacteristic = self.accelerometerEnabledCharacteristic {
            let value = TISensorTag.AccelerometerService.Enabled(boolValue:self.enabledSwitch.on)
            accelerometerEnabledCharacteristic.write(value, timeout:10.0)
        }
    }
    
    func deactivate() {
        let manager = CentralManager.sharedInstance
        if manager.isScanning {
            CentralManager.sharedInstance.stopScanning()
        }
        if let peripheral = self.peripheral {
            peripheral.terminate()
        }
        self.peripheral = nil
        self.updateUIStatus()
    }
}
