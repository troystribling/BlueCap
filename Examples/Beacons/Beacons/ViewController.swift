//
//  ViewController.swift
//  Beacons
//
//  Created by Troy Stribling on 4/5/15.
//  Copyright (c) 2015 Troy Stribling. The MIT License (MIT).
//

import UIKit
import CoreLocation
import BlueCapKit

class ViewController: UITableViewController,  UITextFieldDelegate {

    @IBOutlet var stateLabel: UILabel!
    @IBOutlet var uuidTextField: UITextField!
    @IBOutlet var beaconsLabel: UILabel!
    @IBOutlet var startMonitoringSwitch: UISwitch!
    @IBOutlet var startMonitoringLabel: UILabel!
    
    var beaconRegion: BeaconRegion
    var beaconRangingFuture: FutureStream<[Beacon]>?

    var progressView = ProgressView()
    var isRanging = false
    
    let beaconManager = BeaconManager()
    let defaultUUID = UUID(uuidString: "500E475A-ECEA-4837-83E3-6153A5029769")!
    
    required init?(coder aDecoder: NSCoder) {
        if let uuid = BeaconStore.getBeacon() {
            beaconRegion = BeaconRegion(proximityUUID: uuid, identifier: "Example Beacon")
        } else {
            beaconRegion = BeaconRegion(proximityUUID: defaultUUID, identifier: "Example Beacon")
            BeaconStore.setBeacon(defaultUUID)
        }
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let uuid = BeaconStore.getBeacon() {
            uuidTextField.text = uuid.uuidString
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !beaconManager.isRangingAvailable() else {
            return
        }
        startMonitoringSwitch.isEnabled = false
        uuidTextField.isEnabled = false
        startMonitoringLabel.textColor = UIColor.lightGray
        present(UIAlertController.alertOnErrorWithMessage("Beacon ranging not available"), animated: true, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any!) {
        guard let beaconsViewController = segue.destination as? BeaconsViewController else {
            return
        }
        beaconsViewController.beaconRegion = beaconRegion
        beaconsViewController.beaconRangingFuture = beaconRangingFuture
    }

    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return self.beaconRegion.beacons.count > 0
    }

    @IBAction func toggleMonitoring(_ sender: AnyObject) {
        guard beaconManager.isMonitoring else {
            startMonitoring()
            return
        }
        beaconManager.stopRangingAllBeacons()
        beaconManager.stopMonitoringAllRegions()
        uuidTextField.isEnabled = true
        isRanging = false
        setNotMonitoring()
    }
    
    func startMonitoring() {
        self.progressView.show()
        self.uuidTextField.isEnabled = false
        beaconRangingFuture = beaconManager.startMonitoring(for: beaconRegion, authorization: .authorizedAlways).flatMap{ [unowned self] state -> FutureStream<[Beacon]> in
            self.progressView.remove()
            switch state {
            case .start:
                self.setStartedMonitoring()
                self.isRanging = false
                throw AppError.started
            case .inside:
                self.setInsideRegion()
                self.isRanging = true
                return self.beaconManager.startRangingBeacons(in: self.beaconRegion, authorization: .authorizedAlways)
            case .outside:
                self.setOutsideRegion()
                self.beaconManager.stopRangingBeacons(in: self.beaconRegion)
                throw AppError.outside
            case .unknown:
                throw AppError.unknownState
            }
        }
        beaconRangingFuture?.onSuccess { [unowned self] beacons in
            guard self.isRanging else {
                return
            }
            if UIApplication.shared.applicationState == .active && beacons.count > 0 {
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: AppNotification.didUpdateBeacon), object: self.beaconRegion)
            }
            self.beaconsLabel.text = "\(beacons.count)"
        }
        beaconRangingFuture?.onFailure { [unowned self]  error in
            if error is AppError {
                return
            }
            Notify.withMessage("Error: '\(error.localizedDescription)'")
            self.startMonitoringSwitch.isOn = false
        }
    }
    
    // UITextFieldDelegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard let newValue = self.uuidTextField.text, let uuid = UUID(uuidString: newValue) else {
            self.present(UIAlertController.alertOnErrorWithMessage("UUID is Invalid"), animated: true, completion: nil)
            return false
        }
        self.beaconRegion = BeaconRegion(proximityUUID: uuid, identifier: "Example Beacon")
        BeaconStore.setBeacon(uuid)
        self.uuidTextField.resignFirstResponder()
        return true
    }

    func setNotMonitoring() {
        stateLabel.text = "Not Monitoring"
        stateLabel.textColor = UIColor(red: 0.6, green: 0.0, blue: 0.0, alpha: 1.0)
        Notify.withMessage("Not Monitoring '\(self.beaconRegion.identifier)'")
        beaconsLabel.text = "0"
    }
    
    func setStartedMonitoring() {
        stateLabel.text = "Started Monitoring"
        stateLabel.textColor = UIColor(red: 0.6, green: 0.4, blue: 0.6, alpha: 1.0)
        Notify.withMessage("Started monitoring region '\(self.beaconRegion.identifier)'. Started ranging beacons.")
    }
    
    func setInsideRegion() {
        stateLabel.text = "Inside Region"
        stateLabel.textColor = UIColor(red: 0.0, green: 0.6, blue: 0.0, alpha: 1.0)
        Notify.withMessage("Entered region '\(self.beaconRegion.identifier)'. Started ranging beacons.")
    }
    
    func setOutsideRegion() {
        stateLabel.text = "Outside Region"
        stateLabel.textColor = UIColor(red: 0.6, green: 0.6, blue: 0.0, alpha: 1.0)
        Notify.withMessage("Exited region '\(self.beaconRegion.identifier). Stopped ranging beacons.'")
    }
}

