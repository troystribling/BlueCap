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
    case unsupported
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
    
    let manager = PeripheralManager(options: [CBPeripheralManagerOptionRestoreIdentifierKey : "us.gnos.BlueCap.peripheral-manager-example" as NSString])
    let accelerometer = Accelerometer()

    let accelerometerService = MutableService(uuid: TiSensorTag.AccelerometerService.uuid)

    let accelerometerDataCharacteristic = MutableCharacteristic(profile: RawArrayCharacteristicProfile<TiSensorTag.AccelerometerService.Data>())
    let accelerometerEnabledCharacteristic = MutableCharacteristic(profile: RawCharacteristicProfile<TiSensorTag.AccelerometerService.Enabled>())
    let accelerometerUpdatePeriodCharacteristic = MutableCharacteristic(profile: RawCharacteristicProfile<TiSensorTag.AccelerometerService.UpdatePeriod>())

    required init?(coder aDecoder:NSCoder) {
        super.init(coder: aDecoder)
        accelerometerService.characteristics = [accelerometerDataCharacteristic, accelerometerEnabledCharacteristic, accelerometerUpdatePeriodCharacteristic]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if self.accelerometer.accelerometerAvailable {
            startAdvertisingSwitch.isEnabled = true
            startAdvertisingLabel.textColor = UIColor.black
            enabledSwitch.isEnabled = true
            enableLabel.textColor = UIColor.black
            updatePeriod()
        } else {
            startAdvertisingSwitch.isEnabled = false
            startAdvertisingSwitch.isOn = false
            startAdvertisingLabel.textColor = UIColor.lightGray
            enabledSwitch.isEnabled = false
            enabledSwitch.isOn = false
            enableLabel.textColor = UIColor.lightGray
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    @IBAction func toggleEnabled(_ sender: AnyObject) {
        if accelerometer.accelerometerActive {
            accelerometer.stopAccelerometerUpdates()
        } else {
            let accelrometerDataFuture = accelerometer.startAcceleromterUpdates()
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
            _ = manager.stopAdvertising()
        } else {
            startAdvertising()
        }
    }
    
    func startAdvertising() {
        let uuid = CBUUID(string: TiSensorTag.AccelerometerService.uuid)

        let startAdvertiseFuture = manager.whenStateChanges().flatMap { [unowned self] state -> Future<Void> in
            switch state {
            case .poweredOn:
                self.manager.removeAllServices()
                return self.manager.add(self.accelerometerService)
            case .poweredOff:
                throw AppError.poweredOff
            case .unauthorized, .unknown:
                throw AppError.invalidState
            case .unsupported:
                throw AppError.unsupported
            case .resetting:
                throw AppError.resetting
            }
        }.flatMap { [unowned self] _ -> Future<Void> in
            self.manager.startAdvertising(TiSensorTag.AccelerometerService.name, uuids: [uuid])
        }

        startAdvertiseFuture.onSuccess { [unowned self] in
            self.enableAdvertising()
            self.accelerometerEnabledCharacteristic.value = SerDe.serialize(TiSensorTag.AccelerometerService.Enabled(boolValue: self.enabledSwitch.isOn))
            self.present(UIAlertController.alertWithMessage("poweredOn and started advertising"), animated: true, completion: nil)
        }

        startAdvertiseFuture.onFailure { [unowned self] error in
            switch error {
            case AppError.poweredOff:
                self.present(UIAlertController.alertWithMessage("PeripheralManager powered off") { _ in
                    self.manager.reset()
                    self.disableAdvertising()
                }, animated: true)
            case AppError.resetting:
                let message = "PeripheralManager state \"\(self.manager.state)\". The connection with the system bluetooth service was momentarily lost.\n Restart advertising."
                self.present(UIAlertController.alertWithMessage(message) { _ in
                    self.manager.reset()
                }, animated: true)
            case AppError.unsupported:
                self.present(UIAlertController.alertWithMessage("Bluetooth not supported") { _ in
                    self.disableAdvertising()
                }, animated: true)
            default:
                self.present(UIAlertController.alertOnError(error) { _ in
                    self.manager.reset()
                }, animated: true, completion: nil)
            }
            _ = self.manager.stopAdvertising()
            if self.accelerometer.accelerometerActive {
                self.accelerometer.stopAccelerometerUpdates()
                self.enabledSwitch.isOn = false
            }
        }

        let accelerometerUpdatePeriodFuture = startAdvertiseFuture.flatMap { [unowned self] in
            self.accelerometerUpdatePeriodCharacteristic.startRespondingToWriteRequests(capacity: 2)
        }
        accelerometerUpdatePeriodFuture.onSuccess { [unowned self] (request, _) in
            guard let value = request.value, value.count > 0 && value.count <= 8 else {
                self.accelerometerUpdatePeriodCharacteristic.respondToRequest(request, withResult:CBATTError.invalidAttributeValueLength)
                return
            }
            self.accelerometerUpdatePeriodCharacteristic.value = value
            self.accelerometerUpdatePeriodCharacteristic.respondToRequest(request, withResult:CBATTError.success)
            self.updatePeriod()
        }

        let accelerometerEnabledFuture = startAdvertiseFuture.flatMap { [unowned self] in
            self.accelerometerEnabledCharacteristic.startRespondingToWriteRequests(capacity: 2)
        }
        accelerometerEnabledFuture.onSuccess { [unowned self] (request, _) in
            guard let value = request.value, value.count == 1 else {
                self.accelerometerEnabledCharacteristic.respondToRequest(request, withResult:CBATTError.invalidAttributeValueLength)
                return
            }
            self.accelerometerEnabledCharacteristic.value = request.value
            self.accelerometerEnabledCharacteristic.respondToRequest(request, withResult:CBATTError.success)
            self.updateEnabled()
        }
    }

    func updateAccelerometerData(_ data: CMAcceleration) {
        xAccelerationLabel.text = NSString(format: "%.2f", data.x) as String
        yAccelerationLabel.text = NSString(format: "%.2f", data.y) as String
        zAccelerationLabel.text = NSString(format: "%.2f", data.z) as String
        guard let xRaw = Int8(doubleValue: (-64.0*data.x)),
              let yRaw = Int8(doubleValue: (-64.0*data.y)),
              let zRaw = Int8(doubleValue: (64.0*data.z)) else {
            return
        }
        xRawAccelerationLabel.text = "\(xRaw)"
        yRawAccelerationLabel.text = "\(yRaw)"
        zRawAccelerationLabel.text = "\(zRaw)"
        guard let data = TiSensorTag.AccelerometerService.Data(rawValue: [xRaw, yRaw, zRaw]) else {
            return
        }
        if accelerometerDataCharacteristic.isUpdating {
            do {
                try accelerometerDataCharacteristic.update(withString: data.stringValue)
            } catch let error {
                Logger.debug("update failed for \(data.stringValue), \(error)")
            }
        } else {
            accelerometerDataCharacteristic.value = SerDe.serialize(data)
        }
    }
    
    func updatePeriod() {
        if let value = self.accelerometerUpdatePeriodCharacteristic.value {
            if let period: TiSensorTag.AccelerometerService.UpdatePeriod = SerDe.deserialize(value) {
                accelerometer.updatePeriod = Double(period.period)/1000.0
                updatePeriodLabel.text =  NSString(format: "%d", period.period) as String
                rawUpdatePeriodlabel.text = NSString(format: "%d", period.periodRaw) as String
            }
        } else {
            let updatePeriod = UInt8(accelerometer.updatePeriod * 100)
            if let period = TiSensorTag.AccelerometerService.UpdatePeriod(rawValue: updatePeriod)  {
                updatePeriodLabel.text =  NSString(format: "%d", period.period) as String
                rawUpdatePeriodlabel.text = NSString(format: "%d", period.periodRaw) as String
            }
        }
    }
    
    func updateEnabled() {
        guard let value = accelerometerEnabledCharacteristic.value, let enabled: TiSensorTag.AccelerometerService.Enabled = SerDe.deserialize(value), enabledSwitch.isOn != enabled.boolValue else {
            return
        }
        enabledSwitch.isOn = enabled.boolValue
        toggleEnabled(self)
    }

    func enableAdvertising() {
        startAdvertisingSwitch.isOn = true
        startAdvertisingSwitch.isEnabled = true
        startAdvertisingLabel.textColor = UIColor.black
    }

    func disableAdvertising() {
        startAdvertisingSwitch.isOn = false
    }
}
