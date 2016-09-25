//
//  PeripheralServiceCharacteristicsViewController.swift
//  BlueCap
//
//  Created by Troy Stribling on 6/23/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import UIKit
import BlueCapKit
import CoreBluetooth

class PeripheralServiceCharacteristicsViewController : UITableViewController {

    fileprivate static var BCPeripheralStateKVOContext = UInt8()

    weak var service: Service?
    weak var connectionFuture: FutureStream<(peripheral: Peripheral, connectionEvent: ConnectionEvent)>!

    var peripheralViewController: PeripheralViewController?

    var dataValid = false

    struct MainStoryboard {
        static let peripheralServiceCharacteristicCell = "PeripheralServiceCharacteristicCell"
        static let peripheralServiceCharacteristicSegue = "PeripheralServiceCharacteristic"
    }
    
    required init?(coder aDecoder:NSCoder) {
        super.init(coder:aDecoder)
    }
 
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.updateWhenActive()
        let options = NSKeyValueObservingOptions([.new])
        // TODO: Use Future Callback
        self.service?.peripheral?.addObserver(self, forKeyPath: "state", options: options, context: &PeripheralServiceCharacteristicsViewController.BCPeripheralStateKVOContext)
        NotificationCenter.default.addObserver(self, selector: #selector(PeripheralServiceCharacteristicsViewController.didEnterBackground), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.service?.peripheral?.removeObserver(self, forKeyPath: "state", context: &PeripheralServiceCharacteristicsViewController.BCPeripheralStateKVOContext)
        NotificationCenter.default.removeObserver(self)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any!) {
        if segue.identifier == MainStoryboard.peripheralServiceCharacteristicSegue {
            if let service = self.service {
                if let selectedIndex = self.tableView.indexPath(for: sender as! UITableViewCell) {
                    let viewController = segue.destination as! PeripheralServiceCharacteristicViewController
                    viewController.characteristic = service.characteristics[selectedIndex.row]
                    viewController.peripheralViewController = self.peripheralViewController
                }
            }
        }
    }

    override func shouldPerformSegue(withIdentifier identifier: String?, sender: Any?) -> Bool {
        return true
    }
    
    func peripheralDisconnected() {
        Logger.debug()
        self.tableView.reloadData()
        if let peripheralViewController = self.peripheralViewController {
            if peripheralViewController.peripheralConnected {
                self.present(UIAlertController.alertWithMessage("Peripheral disconnected") { action in
                        peripheralViewController.peripheralConnected = false
                        self.updateWhenActive()
                    }, animated:true, completion:nil)
            }
        }
    }
    
    func didEnterBackground() {
        _ = self.navigationController?.popToRootViewController(animated: false)
        Logger.debug()
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        // TODO: Use future callback
//        guard keyPath != nil else {
//            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
//            return
//        }
//        switch (keyPath!, context) {
//        case("state", PeripheralServiceCharacteristicsViewController.BCPeripheralStateKVOContext):
//            if let change = change, let newValue = change[NSKeyValueChangeKey.newKey], let newRawState = newValue as? Int, let newState = CBPeripheralState(rawValue: newRawState) {
//                if newState == .disconnected {
//                    DispatchQueue.main.async { self.peripheralDisconnected() }
//                }
//            }
//        default:
//            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
//        }
    }

    // UITableViewDataSource
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let service = self.service {
            return service.characteristics.count
        } else {
            return 0;
        }
    }
    
    override func tableView(_ tableView:UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: MainStoryboard.peripheralServiceCharacteristicCell, for: indexPath) as! NameUUIDCell
        if let service = self.service {
            let characteristic = service.characteristics[indexPath.row]
            cell.nameLabel.text = characteristic.name
            cell.uuidLabel.text = characteristic.UUID.uuidString
            if let peripheralViewController = self.peripheralViewController {
                if peripheralViewController.peripheralConnected {
                    cell.nameLabel.textColor = UIColor.black
                } else {
                    cell.nameLabel.textColor = UIColor.lightGray
                }
            } else {
                cell.nameLabel.textColor = UIColor.black
            }
        }
        return cell
    }
    
    override func tableView(_ tableView:UITableView, didSelectRowAt indexPath: IndexPath) {
    }

    // UITableViewDelegate

}
