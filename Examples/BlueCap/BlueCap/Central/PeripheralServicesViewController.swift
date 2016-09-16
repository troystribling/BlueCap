//
//  PeripheralServicesViewController.swift
//  BlueCap
//
//  Created by Troy Stribling on 6/22/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import UIKit
import BlueCapKit
import CoreBluetooth


class PeripheralServicesViewController : UITableViewController {

    fileprivate static var BCPeripheralStateKVOContext = UInt8()

    weak var peripheral: Peripheral!
    weak var connectionFuture: FutureStream<(peripheral: Peripheral, connectionEvent: ConnectionEvent)>!

    var peripheralViewController: PeripheralViewController!
    var progressView  = ProgressView()
    
    struct MainStoryboard {
        static let peripheralServiceCell = "PeripheralServiceCell"
        static let peripheralServicesCharacteritics = "PeripheralServicesCharacteritics"
    }
    
    required init?(coder aDecoder:NSCoder) {
        super.init(coder:aDecoder)
    }
    
    override func viewDidLoad()  {
        super.viewDidLoad()
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.updateWhenActive()
        let options = NSKeyValueObservingOptions([.new])
        // TODO: Use Future Callback
        self.peripheral?.addObserver(self, forKeyPath: "state", options: options, context: &PeripheralServicesViewController.BCPeripheralStateKVOContext)
        NotificationCenter.default.addObserver(self, selector: #selector(PeripheralServicesViewController.didEnterBackground), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.peripheral?.removeObserver(self, forKeyPath: "state", context: &PeripheralServicesViewController.BCPeripheralStateKVOContext)
        NotificationCenter.default.removeObserver(self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any!) {
        if segue.identifier == MainStoryboard.peripheralServicesCharacteritics {
            if let peripheral = self.peripheral {
                if let selectedIndex = self.tableView.indexPath(for: sender as! UITableViewCell) {
                    let viewController = segue.destination as! PeripheralServiceCharacteristicsViewController
                    viewController.service = peripheral.services[selectedIndex.row]
                    viewController.peripheralViewController = self.peripheralViewController

                }
            }
        }
    }
    
    override func shouldPerformSegue(withIdentifier identifier:String?, sender:Any?) -> Bool {
        return true
    }
    
    func peripheralDisconnected() {
        Logger.debug()
        if self.peripheralViewController.peripheralConnected {
            self.present(UIAlertController.alertWithMessage("Peripheral disconnected"), animated:true, completion:nil)
            self.peripheralViewController.peripheralConnected = false
            self.updateWhenActive()
        }
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        guard keyPath != nil else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }
        switch (keyPath!, context) {
        case("state", PeripheralServicesViewController.BCPeripheralStateKVOContext):
            if let change = change, let newValue = change[NSKeyValueChangeKey.newKey], let newRawState = newValue as? Int, let newState = CBPeripheralState(rawValue: newRawState) {
                if newState == .disconnected {
                    DispatchQueue.main.async { self.peripheralDisconnected() }
                }
            }
        default:
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }

    func didEnterBackground() {
        Logger.debug()
        self.navigationController?.popToRootViewController(animated: false)
    }
    
    // UITableViewDataSource
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let peripheral = self.peripheral {
            return peripheral.services.count
        } else {
            return 0;
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: MainStoryboard.peripheralServiceCell, for: indexPath) as! NameUUIDCell
        let service = peripheral.services[indexPath.row]
        cell.nameLabel.text = service.name
        cell.uuidLabel.text = service.UUID.UUIDString
        if let peripheralViewController = self.peripheralViewController {
            if peripheralViewController.peripheralConnected {
                cell.nameLabel.textColor = UIColor.black
            } else {
                cell.nameLabel.textColor = UIColor.lightGray
            }
        } else {
            cell.nameLabel.textColor = UIColor.black
        }
        return cell
    }
    
    
    // UITableViewDelegate
    
}
