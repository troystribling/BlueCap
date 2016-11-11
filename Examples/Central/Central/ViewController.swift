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
    case updateCharactertisticNotFound
    case serviceNotFound
    case disconnected
    case connectionFailed
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
        let dataUpdateFuture = self.manager.whenStateChanges().flatMap { [unowned self] state -> FutureStream<Peripheral> in
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
        }.flatMap { [unowned self] (peripheral, connectionEvent) -> Future<Peripheral> in
            switch connectionEvent {
            case .connect:
                return peripheral.discoverServices([serviceUUID])
            case .timeout:
                throw AppError.disconnected
            case .disconnect:
                throw AppError.disconnected
            case .forceDisconnect:
                self.updateUIStatus()
                throw AppError.connectionFailed
            case .giveUp:
                throw AppError.connectionFailed
            }
        }.flatMap { peripheral -> Future<Service> in
            guard let service = peripheral.service(serviceUUID) else {
                throw AppError.serviceNotFound
            }
            return service.discover(characteristics: [dataUUID, enabledUUID, updatePeriodUUID])
        }.flatMap { [unowned self] service -> Future<Characteristic> in
            guard let dataCharacteristic = service.characteristic(dataUUID) else {
                throw AppError.dataCharactertisticNotFound
            }
            guard let enabledCharacteristic = service.characteristic(enabledUUID) else {
                throw AppError.enabledCharactertisticNotFound
            }
            guard let updatePeriodCharacteristic = service.characteristic(updatePeriodUUID) else {
                throw AppError.updateCharactertisticNotFound
            }
            self.accelerometerDataCharacteristic = dataCharacteristic
            self.accelerometerEnabledCharacteristic = enabledCharacteristic
            self.accelerometerUpdatePeriodCharacteristic = updatePeriodCharacteristic
            return enabledCharacteristic.write(TISensorTag.AccelerometerService.Enabled.yes)
        }.flatMap { [unowned self] _ -> Future<Characteristic> in
            guard let accelerometerEnabledCharacteristic = self.accelerometerEnabledCharacteristic else {
                throw AppError.enabledCharactertisticNotFound
            }
            return accelerometerEnabledCharacteristic.read(timeout: 10.0)
        }.flatMap { [unowned self] _ -> Future<Characteristic> in
            guard let accelerometerUpdatePeriodCharacteristic = self.accelerometerUpdatePeriodCharacteristic else {
                throw AppError.updateCharactertisticNotFound
            }
            return accelerometerUpdatePeriodCharacteristic.read(timeout: 10.0)
        }.flatMap { [unowned self] _ -> Future<Characteristic> in
            guard let accelerometerDataCharacteristic = self.accelerometerDataCharacteristic else {
                throw AppError.dataCharactertisticNotFound
            }
            return accelerometerDataCharacteristic.startNotifying()
        }.flatMap { characteristic -> FutureStream<(characteristic: Characteristic, data: Data?)> in
            return characteristic.receiveNotificationUpdates(capacity: 10)
        }

        dataUpdateFuture.onFailure { [unowned self] error in
            guard let appError = error as? AppError else {
                self.present(UIAlertController.alertOnError(error: error), animated:true, completion:nil)
                return
            }
            switch appError {
            case .dataCharactertisticNotFound:
                fallthrough
            case .enabledCharactertisticNotFound:
                fallthrough
            case .updateCharactertisticNotFound:
                fallthrough
            case .serviceNotFound:
                self.present(UIAlertController.alertOnError(error: error), animated:true, completion:nil)
            case .disconnected:
                self.updateUIStatus()
                self.peripheral?.reconnect()
            case .connectionFailed:
                self.peripheral?.terminate()
                self.updateUIStatus()
                self.present(UIAlertController.alertWithMessage(message: "Connection failed"), animated:true, completion:nil)
            case .invalidState:
                self.present(UIAlertController.alertWithMessage(message: "Invalid state"), animated:true, completion:nil)
            case .resetting:
                self.manager.reset()
                self.present(UIAlertController.alertWithMessage(message: "Bluetooth service resetting"), animated:true, completion:nil)
            case .poweredOff:
                self.manager.reset()
                self.present(UIAlertController.alertWithMessage(message: "Bluetooth powered off"), animated:true, completion:nil)
            }
            self.peripheral = nil
            self.updateUIStatus()
        }


        dataUpdateFuture.onSuccess { (_, data) in
            self.updateData(data)
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
        guard let accelerometerUpdatePeriodCharacteristic = self.accelerometerUpdatePeriodCharacteristic else {
            return
        }
        let readFuture = accelerometerUpdatePeriodCharacteristic.read(timeout: 10.0)

        readFuture.onSuccess {characteristic in
            self.updatePeriod(characteristic)
        }
        readFuture.onFailure{ error in
            self.present(UIAlertController.alertOnError(error: error), animated:true, completion:nil)
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
            let value = TISensorTag.AccelerometerService.Enabled(boolValue: enabledSwitch.isOn)
            let writeFuture = accelerometerEnabledCharacteristic.write(value, timeout:10.0)
            writeFuture.onSuccess { [unowned self] _ in
                self.present(UIAlertController.alertWithMessage(message: "Accelerometer is " + (self.enabledSwitch.isOn ? "on" : "off")), animated:true, completion:nil)
            }
            writeFuture.onFailure { error in
                self.present(UIAlertController.alertOnError(error: error), animated:true, completion:nil)
            }
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
