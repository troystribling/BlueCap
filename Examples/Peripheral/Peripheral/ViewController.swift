//
//  ViewController.swift
//  Beacon
//
//  Created by Troy Stribling on 4/13/15.
//  Copyright (c) 2015 Troy Stribling. The MIT License (MIT).
//

import UIKit
import CoreBluetooth
import CoreMotion
import BlueCapKit

enum AppError: Error {
    case invalidState
    case resetting
    case poweredOff
}

class ViewController: UITableViewController {
    
    @IBOutlet var xAccelerationLabel: UILabel!
    @IBOutlet var yAccelerationLabel: UILabel!
    @IBOutlet var zAccelerationLabel: UILabel!
    @IBOutlet var xRawAccelerationLabel: UILabel!
    @IBOutlet var yRawAccelerationLabel: UILabel!
    @IBOutlet var zRawAccelerationLabel: UILabel!
    
    @IBOutlet var rawUpdatePeriodlabel: UILabel!
    @IBOutlet var updatePeriodLabel: UILabel!
    
    @IBOutlet var startAdvertisingSwitch: UISwitch!
    @IBOutlet var startAdvertisingLabel: UILabel!
    @IBOutlet var enableLabel: UILabel!
    @IBOutlet var enabledSwitch: UISwitch!
    
    let manager = PeripheralManager(options: [CBPeripheralManagerOptionRestoreIdentifierKey : "us.gnos.BlueCap.peripheral-manager.example" as NSString])
    let accelerometer = Accelerometer()

    let accelerometerService = MutableService(UUID: TISensorTag.AccelerometerService.UUID)

    let accelerometerDataCharacteristic = MutableCharacteristic(UUID: TISensorTag.AccelerometerService.Data.UUID,
                                                                properties: [.read, .notify],
                                                                permissions: [.readable, .writeable],
                                                                value: SerDe.serialize(TISensorTag.AccelerometerService.Data(x: 1.0, y: 0.5, z: -1.5)!))
    let accelerometerEnabledCharacteristic = MutableCharacteristic(UUID:TISensorTag.AccelerometerService.Enabled.UUID,
                                                                   properties: [.read, .write],
                                                                   permissions: [.readable, .writeable],
                                                                   value: SerDe.serialize(TISensorTag.AccelerometerService.Enabled.no.rawValue))
    let accelerometerUpdatePeriodCharacteristic = MutableCharacteristic(UUID: TISensorTag.AccelerometerService.UpdatePeriod.UUID,
                                                                        properties: [.read, .write],
                                                                        permissions: [.readable, .writeable],
                                                                        value: SerDe.serialize(UInt8(100)))
    
    required init?(coder aDecoder:NSCoder) {
        super.init(coder: aDecoder)
        accelerometerService.characteristics = [accelerometerDataCharacteristic,
                                                accelerometerEnabledCharacteristic,
                                                accelerometerUpdatePeriodCharacteristic]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if self.accelerometer.accelerometerAvailable {
            self.startAdvertisingSwitch.isEnabled = true
            self.startAdvertisingLabel.textColor = UIColor.black
            self.enabledSwitch.isEnabled = true
            self.enableLabel.textColor = UIColor.black
            self.updatePeriod()
        } else {
            self.startAdvertisingSwitch.isEnabled = false
            self.startAdvertisingSwitch.isOn = false
            self.startAdvertisingLabel.textColor = UIColor.lightGray
            self.enabledSwitch.isEnabled = false
            self.enabledSwitch.isOn = false
            self.enableLabel.textColor = UIColor.lightGray
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    @IBAction func toggleEnabled(_ sender: AnyObject) {
        if accelerometer.accelerometerActive {
            accelerometer.stopAccelerometerUpdates()
        } else {
            let accelrometerDataFuture = self.accelerometer.startAcceleromterUpdates()
            accelrometerDataFuture.onSuccess { [unowned self] data in
                self.updateAccelerometerData(data)
            }
            accelrometerDataFuture.onFailure { [unowned self] error in
                self.present(UIAlertController.alertOnError(error), animated: true, completion: nil)
            }
        }
    }
    
    @IBAction func toggleAdvertise(_ sender: AnyObject) {
        if manager.isAdvertising {
            accelerometerUpdatePeriodCharacteristic.stopRespondingToWriteRequests()
            manager.stopAdvertising()
        } else {
            startAdvertising()
        }
    }
    
    func startAdvertising() {
        let uuid = CBUUID(string: TISensorTag.AccelerometerService.UUID)

        let startAdvertiseFuture = manager.whenStateChanges().flatMap { [unowned self] state -> Future<Void> in
            switch state {
            case .poweredOn:
                self.manager.removeAllServices()
                return self.manager.add(self.accelerometerService)
            case .poweredOff:
                throw AppError.poweredOff
            case .unauthorized, .unknown, .unsupported:
                throw AppError.invalidState
            case .resetting:
                throw AppError.resetting
            }
        }.flatMap { [unowned self] _ -> Future<Void> in
            self.manager.startAdvertising(TISensorTag.AccelerometerService.name, uuids:[uuid])
        }


        startAdvertiseFuture.onSuccess { [unowned self] in
            self.present(UIAlertController.alertWithMessage("poweredOn and started advertising"), animated: true, completion: nil)
        }
        startAdvertiseFuture.onFailure { [unowned self] error in
            switch error {
            case AppError.poweredOff:
                self.present(UIAlertController.alertWithMessage("Bluetooth poweredOff"), animated: true)
            case AppError.resetting:
                self.manager.reset()
                let message = "PeripheralManager state \"\(self.manager.state.stringValue)\". The connection with the system bluetooth service was momentarily lost.\n Restart advertising."
                self.present(UIAlertController.alertWithMessage(message), animated: true)
            default:
                self.present(UIAlertController.alertOnError(error), animated: true, completion: nil)
            }
            if self.accelerometer.accelerometerActive {
                self.accelerometer.stopAccelerometerUpdates()
                self.enabledSwitch.isOn = false
            }
            self.startAdvertisingSwitch.isOn = false
            self.startAdvertisingSwitch.isEnabled = false
            self.startAdvertisingLabel.textColor = UIColor.lightGray
            self.manager.stopAdvertising()
        }

        let accelerometerUpdatePeriodFuture = startAdvertiseFuture.flatMap { [unowned self] in
            self.accelerometerUpdatePeriodCharacteristic.startRespondingToWriteRequests(capacity: 2)
        }
        accelerometerUpdatePeriodFuture.onSuccess { [unowned self] (request, _) in
            if let value = request.value, value.count > 0 && value.count <= 8 {
                self.accelerometerUpdatePeriodCharacteristic.value = value
                self.accelerometerUpdatePeriodCharacteristic.respondToRequest(request, withResult:CBATTError.success)
                self.updatePeriod()
            } else {
                self.accelerometerUpdatePeriodCharacteristic.respondToRequest(request, withResult:CBATTError.invalidAttributeValueLength)
            }
        }

        let accelerometerEnabledFuture = startAdvertiseFuture.flatMap { [unowned self] in
            self.accelerometerEnabledCharacteristic.startRespondingToWriteRequests(capacity: 2)
        }
        accelerometerEnabledFuture.onSuccess { [unowned self] (request, _) in
            if let value = request.value, value.count == 1 {
                self.accelerometerEnabledCharacteristic.value = request.value
                self.accelerometerEnabledCharacteristic.respondToRequest(request, withResult:CBATTError.success)
                self.updateEnabled()
            } else {
                self.accelerometerEnabledCharacteristic.respondToRequest(request, withResult:CBATTError.invalidAttributeValueLength)
            }
        }


    }

    func updateAccelerometerData(_ data: CMAcceleration) {
        xAccelerationLabel.text = NSString(format: "%.2f", data.x) as String
        yAccelerationLabel.text = NSString(format: "%.2f", data.y) as String
        zAccelerationLabel.text = NSString(format: "%.2f", data.z) as String
        if let xRaw = Int8(doubleValue: (-64.0*data.x)), let yRaw = Int8(doubleValue: (-64.0*data.y)), let zRaw = Int8(doubleValue: (64.0*data.z)) {
            xRawAccelerationLabel.text = "\(xRaw)"
            yRawAccelerationLabel.text = "\(yRaw)"
            zRawAccelerationLabel.text = "\(zRaw)"
            if let data = TISensorTag.AccelerometerService.Data(rawValue:[xRaw, yRaw, zRaw]), self.accelerometerDataCharacteristic.isUpdating {
                if !self.accelerometerDataCharacteristic.updateValue(withString: data.stringValue) {
                    Logger.debug("update failed \(data.stringValue)")
                }
            }
        }
    }
    
    func updatePeriod() {
        if let value = self.accelerometerUpdatePeriodCharacteristic.value {
            if let period: TISensorTag.AccelerometerService.UpdatePeriod = SerDe.deserialize(value) {
                accelerometer.updatePeriod = Double(period.period)/1000.0
                updatePeriodLabel.text =  NSString(format: "%d", period.period) as String
                rawUpdatePeriodlabel.text = NSString(format: "%d", period.periodRaw) as String
            }
        } else {
            if let period: TISensorTag.AccelerometerService.UpdatePeriod = SerDe.deserialize(accelerometer.updatePeriod) {
                accelerometer.updatePeriod = Double(period.period)/1000.0
                updatePeriodLabel.text =  NSString(format: "%d", period.period) as String
                rawUpdatePeriodlabel.text = NSString(format: "%d", period.periodRaw) as String
            }
        }
    }
    
    func updateEnabled() {
        if let value = accelerometerEnabledCharacteristic.value, let enabled: TISensorTag.AccelerometerService.Enabled = SerDe.deserialize(value), enabledSwitch.isOn != enabled.boolValue {
            enabledSwitch.isOn = enabled.boolValue
            toggleEnabled(self)
        } else {

        }
    }
}
