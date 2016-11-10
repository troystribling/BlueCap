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

public enum AppError : Error {
    case dataCharactertisticNotFound
    case enabledCharactertisticNotFound
    case serviceNotFound
    case characteristicNotFound
    case peripheralNotC
    case invalidState
    case resetting
    case poweredOff
}

public struct CentralError {
    public static let domain = "Central Example"
}

class ViewController: UITableViewController {
    
    struct MainStoryboard {
        static let updatePeriodValueSegue = "UpdatePeriodValue"
        static let updatePeriodRawValueSegue = "UpdatePeriodRawValue"
    }

    @IBOutlet var xAccelerationLabel: UILabel!
    @IBOutlet var yAccelerationLabel: UILabel!
    @IBOutlet var zAccelerationLabel: UILabel!
    @IBOutlet var xRawAccelerationLabel: UILabel!
    @IBOutlet var yRawAccelerationLabel: UILabel!
    @IBOutlet var zRawAccelerationLabel: UILabel!
    
    @IBOutlet var rawUpdatePeriodlabel: UILabel!
    @IBOutlet var updatePeriodLabel: UILabel!
    
    @IBOutlet var activateSwitch: UISwitch!
    @IBOutlet var enabledSwitch: UISwitch!
    @IBOutlet var enabledLabel: UILabel!
    @IBOutlet var statusLabel: UILabel!
    
    var peripheral: Peripheral?
    var accelerometerDataCharacteristic: Characteristic?
    var accelerometerEnabledCharacteristic: Characteristic?
    var accelerometerUpdatePeriodCharacteristic: Characteristic?

    let manager = CentralManager()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.updateUIStatus()
        self.readUpdatePeriod()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == MainStoryboard.updatePeriodValueSegue {
            let viewController = segue.destination as! SetUpdatePeriodViewController
            viewController.characteristic = self.accelerometerUpdatePeriodCharacteristic
            viewController.isRaw = false
        } else if segue.identifier == MainStoryboard.updatePeriodRawValueSegue {
            let viewController = segue.destination as! SetUpdatePeriodViewController
            viewController.characteristic = self.accelerometerUpdatePeriodCharacteristic
            viewController.isRaw = true
        }

    }
    
    @IBAction func toggleEnabled(_ sender: AnyObject) {
        if let peripheral = self.peripheral, peripheral.state == .connected {
            self.writeEnabled()
        }
    }
    
    @IBAction func toggleActivate(_ sender: AnyObject) {
        if self.activateSwitch.isOn  {
            self.activate()
        } else {
            self.deactivate()
        }
    }
    
    @IBAction func disconnect(_ sender: AnyObject) {
        if let peripheral = self.peripheral, peripheral.state != .disconnected {
            peripheral.disconnect()
        }
    }
    
    func activate() {
        let serviceUUID = CBUUID(string: TISensorTag.AccelerometerService.UUID)
        let dataUUID = CBUUID(string: TISensorTag.AccelerometerService.Data.UUID)
        let enabledUUID = CBUUID(string: TISensorTag.AccelerometerService.Enabled.UUID)
        let updatePeriodUUID = CBUUID(string: TISensorTag.AccelerometerService.UpdatePeriod.UUID)

            
        // on power, start scanning. when peripheral is discovered connect and stop scanning
        let peripheralConnectFuture = self.manager.whenStateChanges().flatMap { [unowned self] state -> FutureStream<Peripheral> in
                switch state {
                case .poweredOn:
                    return self.manager.startScanning(forServiceUUIDs: [serviceUUID], capacity: 10)
                case .poweredOff:
                    throw AppError.poweredOff
                case .unauthorized, .unknown, .unsupported:
                    throw AppError.invalidState
                case .resetting:
                    throw AppError.resetting
                }
        }.flatMap { [unowned self] peripheral -> FutureStream<(peripheral: Peripheral, connectionEvent: ConnectionEvent)> in
            self.manager.stopScanning()
            self.peripheral = peripheral
            return peripheral.connect(timeoutRetries:5, disconnectRetries:5, connectionTimeout: 10.0)
        }.flatMap { [unowned self] (peripheral, connectionEvent) in
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
            case .GiveUp:
                peripheral.terminate()
                self.updateUIStatus()
                self.presentViewController(UIAlertController.alertWithMessage("Giving up"), animated:true, completion:nil)
            }
        }

        peripheralConnectFuture.onFailure { error in
            self.peripheral = nil
            self.presentViewController(UIAlertController.alertOnError(error), animated:true, completion:nil)
            self.updateUIStatus()
        }

        // discover services and characteristics and enable accelerometer
        let peripheralDiscoveredFuture = peripheralConnectFuture.flatmap { (peripheral, connectionEvent) -> Future<Peripheral> in
            if peripheral.state == .Connected {
                return peripheral.discoverPeripheralServices([serviceUUID])
            } else {
                let promise = Promise<Peripheral>()
                promise.failure(CentralError.peripheralNotConnected)
                return promise.future
            }
        }.flatmap { peripheral -> Future<Characteristic> in
            if let service = peripheral.service(serviceUUID) {
                self.accelerometerDataCharacteristic = service.characteristic(dataUUID)
                self.accelerometerEnabledCharacteristic = service.characteristic(enabledUUID)
                self.accelerometerUpdatePeriodCharacteristic = service.characteristic(updatePeriodUUID)
                if let accelerometerEnabledCharacteristic = self.accelerometerEnabledCharacteristic {
                    return accelerometerEnabledCharacteristic.write(TISensorTag.AccelerometerService.Enabled.Yes)
                } else {
                    let promise = Promise<Characteristic>()
                    promise.failure(CentralError.enabledCharacteristicNotFound)
                    return promise.future
                }
            } else {
                let promise = Promise<Characteristic>()
                promise.failure(CentralError.serviceNotFound)
                return promise.future
            }
        }

        // get enabled value
        let readEnabledFuture = peripheralDiscoveredFuture.flatmap { _ -> Future<Characteristic> in
            if let accelerometerEnabledCharacteristic = self.accelerometerEnabledCharacteristic {
                return accelerometerEnabledCharacteristic.read(10.0)
            } else {
                let promise = Promise<Characteristic>()
                promise.failure(CentralError.characteristicNotFound)
                return promise.future
            }
        }
        readEnabledFuture.onSuccess {characteristic in
            self.updateEnabled(characteristic)
        }
        
        // get update period value
        let readUpdatePeriodFuture = readEnabledFuture.flatmap { _ -> Future<Characteristic> in
            if let accelerometerUpdatePeriodCharacteristic = self.accelerometerUpdatePeriodCharacteristic {
                return accelerometerUpdatePeriodCharacteristic.read(10.0)
            } else {
                let promise = Promise<Characteristic>()
                promise.failure(CentralError.characteristicNotFound)
                return promise.future
            }
        }
        readUpdatePeriodFuture.onSuccess { characteristic in
            self.updatePeriod(characteristic)
        }

        // subscribe to acceleration data updates
        let dataSubscriptionFuture = readUpdatePeriodFuture.flatmap { _ -> Future<Characteristic> in
            if let accelerometerDataCharacteristic = self.accelerometerDataCharacteristic {
                return accelerometerDataCharacteristic.startNotifying()
            } else {
                let promise = Promise<Characteristic>()
                promise.failure(CentralError.characteristicNotFound)
                return promise.future
            }
        }

        dataSubscriptionFuture.flatmap { characteristic in
            return characteristic.receiveNotificationUpdates(10)
        }.onSuccess { (_, data) in
            self.updateData(data)
        }
            
        // handle bluetooth power off
        let powerOffFuture = manager.whenPowerOff()
        powerOffFuture.onSuccess {
            self.deactivate()
        }
        powerOffFuture.onFailure {error in
        }
        // enable controls when bluetooth is powered on again after stop advertising is successul
        let powerOffFutureSuccessFuture = powerOffFuture.flatmap { _ in
            self.manager.whenPowerOn()
        }
        powerOffFutureSuccessFuture.onSuccess {
            self.presentViewController(UIAlertController.alertWithMessage("restart application"), animated:true, completion:nil)
        }
        // enable controls when bluetooth is powered on again after stop advertising fails
        let powerOffFutureFailedFuture = powerOffFuture.recoverWith { _ in
            self.manager.whenPowerOn()
        }
        powerOffFutureFailedFuture.onSuccess {
            if self.manager.poweredOn {
                self.presentViewController(UIAlertController.alertWithMessage("restart application"), animated:true, completion:nil)
            }
        }
    }
    
    func updateUIStatus() {
        if let peripheral = self.peripheral {
            switch peripheral.state {
            case .connected:
                self.statusLabel.text = "Connected"
                self.statusLabel.textColor = UIColor(red:0.2, green:0.7, blue:0.2, alpha:1.0)
            case .connecting:
                self.statusLabel.text = "Connecting"
                self.statusLabel.textColor = UIColor(red:0.9, green:0.7, blue:0.0, alpha:1.0)
            case .disconnected:
                self.statusLabel.text = "Disconnected"
                self.statusLabel.textColor = UIColor.lightGray
            case .disconnecting:
                self.statusLabel.text = "Disconnecting"
                self.statusLabel.textColor = UIColor.lightGray
            }
            if peripheral.state == .connected {
                self.enabledLabel.textColor = UIColor.black
                self.enabledSwitch.isEnabled = true
            } else {
                self.enabledLabel.textColor = UIColor.lightGray
                self.enabledSwitch.isEnabled = false
                self.enabledSwitch.isOn = false
            }
        } else {
            self.statusLabel.text = "Disconnected"
            self.statusLabel.textColor = UIColor.lightGray
            self.enabledLabel.textColor = UIColor.lightGray
            self.enabledSwitch.isOn = false
            self.enabledSwitch.isEnabled = false
            self.activateSwitch.isOn = false
        }
    }
    
    func updateEnabled(_ characteristic: Characteristic) {
        if let value : TISensorTag.AccelerometerService.Enabled = characteristic.value() {
            self.enabledSwitch.isOn = value.boolValue
        }
    }

    func updatePeriod(_ characteristic: Characteristic) {
        if let value : TISensorTag.AccelerometerService.UpdatePeriod = characteristic.value() {
            self.updatePeriodLabel.text = "\(value.period)"
            self.rawUpdatePeriodlabel.text = "\(value.rawValue)"
        }
    }

    func readUpdatePeriod() {
        let readFuture = self.accelerometerUpdatePeriodCharacteristic?.read(timeout: 10.0)
        readFuture?.onSuccess {characteristic in
            self.updatePeriod(characteristic)
        }
        readFuture?.onFailure{ error in
            self.present(UIAlertController.alertOnError(error), animated:true, completion:nil)
        }
    }

    func updateData(_ data:Data?) {
        if let data = data, let accelerometerData: TISensorTag.AccelerometerService.Data = SerDe.deserialize(data) {
            self.xAccelerationLabel.text = NSString(format: "%.2f", accelerometerData.x) as String
            self.yAccelerationLabel.text = NSString(format: "%.2f", accelerometerData.y) as String
            self.zAccelerationLabel.text = NSString(format: "%.2f", accelerometerData.z) as String
            let rawValue = accelerometerData.rawValue
            self.xRawAccelerationLabel.text = "\(rawValue[0])"
            self.yRawAccelerationLabel.text = "\(rawValue[1])"
            self.zRawAccelerationLabel.text = "\(rawValue[2])"
        }
    }

    func writeEnabled() {
        if let accelerometerEnabledCharacteristic = self.accelerometerEnabledCharacteristic {
            let value = TISensorTag.AccelerometerService.Enabled(boolValue:self.enabledSwitch.isOn)
            accelerometerEnabledCharacteristic.write(value, timeout:10.0)
        }
    }
    
    func deactivate() {
        if manager.isScanning {
            self.manager.stopScanning()
        }
        if let peripheral = self.peripheral {
            peripheral.terminate()
        }
        self.peripheral = nil
        self.updateUIStatus()
    }
}
