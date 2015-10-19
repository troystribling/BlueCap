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

    weak var peripheral : Peripheral?

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
        static let peripheralAdvertisementCell                      = "PeripheralAdvertisementCell"
        static let peripheralAdvertisemensServicesSegue             = "PeripheralAdvertisemensServices"
        static let peripheralAdvertisemensServicesDataSegue         = "PeripheralAdvertisemensServicesData"
        static let peripheralAdvertisemensOverflowServicesSegue     = "PeripheralAdvertisemensOverflowServices"
        static let peripheralAdvertisemensSolicitedServicesSegue    = "PeripheralAdvertisemensSolicitedServices"
    }
    
    required init?(coder aDecoder:NSCoder)  {
        super.init(coder:aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let peripheral = self.peripheral {
            if let localName = peripheral.advertisedLocalName {
                self.localNameValueLabel.text = localName
                self.localNameLabel.textColor = UIColor.blackColor()
            }
            if let txPower = peripheral.advertisedTxPower {
                self.txPowerValueLabel.text = txPower.stringValue
                self.txPowerLabel.textColor = UIColor.blackColor()
            }
            if let isConnectable = peripheral.advertisedIsConnectable {
                self.isConnectableValueLabel.text = isConnectable.stringValue
                self.isConnectableLabel.textColor = UIColor.blackColor()
            }
            if let mfgData = peripheral.advertisedManufactuereData {
                self.manufacturerDataValueLabel.text = mfgData.hexStringValue()
                self.manufacturerDataLabel.textColor = UIColor.blackColor()
            }
            if let services = peripheral.advertisedServiceUUIDs {
                self.servicesLabel.textColor = UIColor.blackColor()
                self.servicesCountLabel.text = "\(services.count)"
            }
            if let servicesData = peripheral.advertisedServiceData {
                self.servicesDataLabel.textColor = UIColor.blackColor()
                self.servicesDataCountLabel.text = "\(servicesData.count)"
            }
            if let overflowServices = peripheral.advertisedOverflowServiceUUIDs {
                self.overflowServicesLabel.textColor = UIColor.blackColor()
                self.overflowServicesCountLabel.text = "\(overflowServices.count)"
            }
            if let solicitedServices = peripheral.advertisedSolicitedServiceUUIDs {
                self.solicitedServicesLabel.textColor = UIColor.blackColor()
                self.solicitedServicesCountLabel.text = "\(solicitedServices.count)"
            }
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"didBecomeActive", name:BlueCapNotification.didBecomeActive, object:nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"didResignActive", name:BlueCapNotification.didResignActive, object:nil)
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    func didResignActive() {
        self.navigationController?.popToRootViewControllerAnimated(false)
        Logger.debug()
    }
    
    func didBecomeActive() {
        Logger.debug()
    }

}
