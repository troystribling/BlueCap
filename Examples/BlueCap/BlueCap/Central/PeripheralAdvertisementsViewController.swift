//
//  PeripheralAdvertisements.swift
//  BlueCap
//
//  Created by Troy Stribling on 6/19/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import UIKit
import BlueCapKit

class PeripheralAdvertisementsViewController : UITableViewController {

    weak var peripheral: Peripheral?

    @IBOutlet var localNameLabel                : UILabel!
    @IBOutlet var localNameValueLabel           : UILabel!
    @IBOutlet var txPowerLabel                  : UILabel!
    @IBOutlet var txPowerValueLabel             : UILabel!
    @IBOutlet var isConnectableLabel            : UILabel!
    @IBOutlet var isConnectableValueLabel       : UILabel!
    @IBOutlet var manufacturerDataLabel         : UILabel!
    @IBOutlet var manufacturerDataValueLabel    : UILabel!
    
    @IBOutlet var servicesLabel                 : UILabel!
    @IBOutlet var servicesCountLabel            : UILabel!
    @IBOutlet var servicesDataLabel             : UILabel!
    @IBOutlet var servicesDataCountLabel        : UILabel!
    @IBOutlet var overflowServicesLabel         : UILabel!
    @IBOutlet var overflowServicesCountLabel    : UILabel!
    @IBOutlet var solicitedServicesLabel        : UILabel!
    @IBOutlet var solicitedServicesCountLabel   : UILabel!
    
    struct MainStoryboard {
        static let peripheralAdvertisementCell = "PeripheralAdvertisementCell"
        static let peripheralAdvertisementsServicesSegue = "PeripheralAdvertisementsServices"
        static let peripheralAdvertisementsServicesDataSegue = "PeripheralAdvertisementsServicesData"
        static let peripheralAdvertisementsOverflowServicesSegue = "PeripheralAdvertisementsOverflowServices"
        static let peripheralAdvertisementsSolicitedServicesSegue = "PeripheralAdvertisement   ssSolicitedServices"
    }
    
    required init?(coder aDecoder:NSCoder)  {
        super.init(coder:aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let peripheral = self.peripheral {
            if let localName = peripheral.advertisements.localName {
                self.localNameValueLabel.text = localName
                self.localNameLabel.textColor = UIColor.black
            }
            if let txPower = peripheral.advertisements.txPower {
                self.txPowerValueLabel.text = txPower.stringValue
                self.txPowerLabel.textColor = UIColor.black
            }
            if let isConnectable = peripheral.advertisements.isConnectable {
                self.isConnectableValueLabel.text = isConnectable.stringValue
                self.isConnectableLabel.textColor = UIColor.black
            }
            if let mfgData = peripheral.advertisements.manufactuereData {
                self.manufacturerDataValueLabel.text = mfgData.hexStringValue()
                self.manufacturerDataLabel.textColor = UIColor.black
            }
            if let services = peripheral.advertisements.serviceUUIDs {
                self.servicesLabel.textColor = UIColor.black
                self.servicesCountLabel.text = "\(services.count)"
            }
            if let servicesData = peripheral.advertisements.serviceData {
                self.servicesDataLabel.textColor = UIColor.black
                self.servicesDataCountLabel.text = "\(servicesData.count)"
            }
            if let overflowServices = peripheral.advertisements.overflowServiceUUIDs {
                self.overflowServicesLabel.textColor = UIColor.black
                self.overflowServicesCountLabel.text = "\(overflowServices.count)"
            }
            if let solicitedServices = peripheral.advertisements.solicitedServiceUUIDs {
                self.solicitedServicesLabel.textColor = UIColor.black
                self.solicitedServicesCountLabel.text = "\(solicitedServices.count)"
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        NotificationCenter.default.addObserver(self, selector:#selector(PeripheralAdvertisementsViewController.didEnterBackground), name: NSNotification.Name.UIApplicationDidEnterBackground, object:nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }

    func didEnterBackground() {
        _ = self.navigationController?.popToRootViewController(animated: false)
        Logger.debug()
    }
    
    override func prepare(for segue:UIStoryboardSegue, sender:Any?) {
        if segue.identifier == MainStoryboard.peripheralAdvertisementsServicesSegue {
            let controller = segue.destination as! PeripheralAdvertisementsServicesViewController
            controller.peripheral = self.peripheral
        } else if segue.identifier == MainStoryboard.peripheralAdvertisementsServicesDataSegue {
            let controller = segue.destination as! PeripheralAdvertisementsServiceDataViewController
            controller.peripheral = self.peripheral
        } else if segue.identifier == MainStoryboard.peripheralAdvertisementsOverflowServicesSegue {
            let controller = segue.destination as! PeripheralAdvertisementsOverflowServicesViewController
            controller.peripheral = self.peripheral
        } else if segue.identifier == MainStoryboard.peripheralAdvertisementsSolicitedServicesSegue {
            let controller = segue.destination as! PeripheralAdvertisementsSolicitedServicesViewController
            controller.peripheral = self.peripheral
        }
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if let advertisements = self.peripheral?.advertisements {
            if identifier == MainStoryboard.peripheralAdvertisementsServicesSegue {
                return advertisements.serviceUUIDs != nil
            } else if identifier == MainStoryboard.peripheralAdvertisementsServicesDataSegue {
                return advertisements.serviceData != nil
            } else if identifier == MainStoryboard.peripheralAdvertisementsOverflowServicesSegue {
                return advertisements.overflowServiceUUIDs != nil
            } else if identifier == MainStoryboard.peripheralAdvertisementsSolicitedServicesSegue {
                return advertisements.solicitedServiceUUIDs != nil
            }
        }
        return false
    }

}
