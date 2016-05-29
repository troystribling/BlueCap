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

    weak var peripheral: BCPeripheral?

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
            if let localName = peripheral.advertisements?.localName {
                self.localNameValueLabel.text = localName
                self.localNameLabel.textColor = UIColor.blackColor()
            }
            if let txPower = peripheral.advertisements?.txPower {
                self.txPowerValueLabel.text = txPower.stringValue
                self.txPowerLabel.textColor = UIColor.blackColor()
            }
            if let isConnectable = peripheral.advertisements?.isConnectable {
                self.isConnectableValueLabel.text = isConnectable.stringValue
                self.isConnectableLabel.textColor = UIColor.blackColor()
            }
            if let mfgData = peripheral.advertisements?.manufactuereData {
                self.manufacturerDataValueLabel.text = mfgData.hexStringValue()
                self.manufacturerDataLabel.textColor = UIColor.blackColor()
            }
            if let services = peripheral.advertisements?.serviceUUIDs {
                self.servicesLabel.textColor = UIColor.blackColor()
                self.servicesCountLabel.text = "\(services.count)"
            }
            if let servicesData = peripheral.advertisements?.serviceData {
                self.servicesDataLabel.textColor = UIColor.blackColor()
                self.servicesDataCountLabel.text = "\(servicesData.count)"
            }
            if let overflowServices = peripheral.advertisements?.overflowServiceUUIDs {
                self.overflowServicesLabel.textColor = UIColor.blackColor()
                self.overflowServicesCountLabel.text = "\(overflowServices.count)"
            }
            if let solicitedServices = peripheral.advertisements?.solicitedServiceUUIDs {
                self.solicitedServicesLabel.textColor = UIColor.blackColor()
                self.solicitedServicesCountLabel.text = "\(solicitedServices.count)"
            }
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        NSNotificationCenter.defaultCenter().addObserver(self, selector:#selector(PeripheralAdvertisementsViewController.didEnterBackground), name: UIApplicationDidEnterBackgroundNotification, object:nil)
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    func didEnterBackground() {
        self.navigationController?.popToRootViewControllerAnimated(false)
        BCLogger.debug()
    }
    
    override func prepareForSegue(segue:UIStoryboardSegue, sender:AnyObject?) {
        if segue.identifier == MainStoryboard.peripheralAdvertisementsServicesSegue {
            let controller = segue.destinationViewController as! PeripheralAdvertisementsServicesViewController
            controller.peripheral = self.peripheral
        } else if segue.identifier == MainStoryboard.peripheralAdvertisementsServicesDataSegue {
            let controller = segue.destinationViewController as! PeripheralAdvertisementsServiceDataViewController
            controller.peripheral = self.peripheral
        } else if segue.identifier == MainStoryboard.peripheralAdvertisementsOverflowServicesSegue {
            let controller = segue.destinationViewController as! PeripheralAdvertisementsOverflowServicesViewController
            controller.peripheral = self.peripheral
        } else if segue.identifier == MainStoryboard.peripheralAdvertisementsSolicitedServicesSegue {
            let controller = segue.destinationViewController as! PeripheralAdvertisementsSolicitedServicesViewController
            controller.peripheral = self.peripheral
        }
    }
    
    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
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
