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

    var peripheralAdvertisements: PeripheralAdvertisements?

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
        static let peripheralAdvertisementsSolicitedServicesSegue = "PeripheralAdvertisementsSolicitedServices"
    }
    
    required init?(coder aDecoder:NSCoder)  {
        super.init(coder:aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let peripheralAdvertisements = peripheralAdvertisements else {
            return
        }
        if let localName = peripheralAdvertisements.localName {
            self.localNameValueLabel.text = localName
            self.localNameLabel.textColor = UIColor.black
        }
        if let txPower = peripheralAdvertisements.txPower {
            self.txPowerValueLabel.text = txPower.stringValue
            self.txPowerLabel.textColor = UIColor.black
        }
        if let isConnectable = peripheralAdvertisements.isConnectable {
            self.isConnectableValueLabel.text = isConnectable.stringValue
            self.isConnectableLabel.textColor = UIColor.black
        }
        if let mfgData = peripheralAdvertisements.manufactuereData {
            self.manufacturerDataValueLabel.text = mfgData.hexStringValue()
            self.manufacturerDataLabel.textColor = UIColor.black
        }
        if let services = peripheralAdvertisements.serviceUUIDs {
            self.servicesLabel.textColor = UIColor.black
            self.servicesCountLabel.text = "\(services.count)"
        }
        if let servicesData = peripheralAdvertisements.serviceData {
            self.servicesDataLabel.textColor = UIColor.black
            self.servicesDataCountLabel.text = "\(servicesData.count)"
        }
        if let overflowServices = peripheralAdvertisements.overflowServiceUUIDs {
            self.overflowServicesLabel.textColor = UIColor.black
            self.overflowServicesCountLabel.text = "\(overflowServices.count)"
        }
        if let solicitedServices = peripheralAdvertisements.solicitedServiceUUIDs {
            self.solicitedServicesLabel.textColor = UIColor.black
            self.solicitedServicesCountLabel.text = "\(solicitedServices.count)"
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

    @objc func didEnterBackground() {
        _ = navigationController?.popToRootViewController(animated: false)
    }
    
    override func prepare(for segue:UIStoryboardSegue, sender:Any?) {
        if segue.identifier == MainStoryboard.peripheralAdvertisementsServicesSegue {
            let viewController = segue.destination as! PeripheralAdvertisementsServicesViewController
            viewController.peripheralAdvertisements = peripheralAdvertisements
        } else if segue.identifier == MainStoryboard.peripheralAdvertisementsServicesDataSegue {
            let viewController = segue.destination as! PeripheralAdvertisementsServiceDataViewController
            viewController.peripheralAdvertisements = peripheralAdvertisements
        } else if segue.identifier == MainStoryboard.peripheralAdvertisementsOverflowServicesSegue {
            let viewController = segue.destination as! PeripheralAdvertisementsOverflowServicesViewController
            viewController.peripheralAdvertisements = peripheralAdvertisements
        } else if segue.identifier == MainStoryboard.peripheralAdvertisementsSolicitedServicesSegue {
            let viewController = segue.destination as! PeripheralAdvertisementsSolicitedServicesViewController
            viewController.peripheralAdvertisements = peripheralAdvertisements
        }
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if let peripheralAdvertisements = peripheralAdvertisements {
            if identifier == MainStoryboard.peripheralAdvertisementsServicesSegue {
                return peripheralAdvertisements.serviceUUIDs != nil
            } else if identifier == MainStoryboard.peripheralAdvertisementsServicesDataSegue {
                return peripheralAdvertisements.serviceData != nil
            } else if identifier == MainStoryboard.peripheralAdvertisementsOverflowServicesSegue {
                return peripheralAdvertisements.overflowServiceUUIDs != nil
            } else if identifier == MainStoryboard.peripheralAdvertisementsSolicitedServicesSegue {
                return peripheralAdvertisements.solicitedServiceUUIDs != nil
            }
        }
        return false
    }

}
