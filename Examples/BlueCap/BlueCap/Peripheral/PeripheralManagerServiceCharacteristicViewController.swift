//
//  PeripheralManagerServiceCharacteristicViewController.swift
//  BlueCap
//
//  Created by Troy Stribling on 8/19/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import UIKit
import CoreBluetooth
import BlueCapKit

class PeripheralManagerServiceCharacteristicViewController: UITableViewController {
    
    var characteristic: MutableCharacteristic?
    var peripheralManagerViewController: PeripheralManagerViewController?

    
    @IBOutlet var uuidLabel: UILabel!
    
    @IBOutlet var permissionReadableLabel: UILabel!
    @IBOutlet var permissionWriteableLabel: UILabel!
    @IBOutlet var permissionReadEncryptionLabel: UILabel!
    @IBOutlet var permissionWriteEncryptionLabel: UILabel!
    
    @IBOutlet var propertyBroadcastLabel: UILabel!
    @IBOutlet var propertyReadLabel: UILabel!
    @IBOutlet var propertyWriteWithoutResponseLabel: UILabel!
    @IBOutlet var propertyWriteLabel: UILabel!
    @IBOutlet var propertyNotifyLabel: UILabel!
    @IBOutlet var propertyIndicateLabel: UILabel!
    @IBOutlet var propertyAuthenticatedSignedWritesLabel: UILabel!
    @IBOutlet var propertyExtendedPropertiesLabel: UILabel!
    @IBOutlet var propertyNotifyEncryptionRequiredLabel: UILabel!
    @IBOutlet var propertyIndicateEncryptionRequiredLabel: UILabel!

    struct MainStoryboard {
        static let peripheralManagerServiceCharacteristicValuesSegue = "PeripheralManagerServiceCharacteristicValues"
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder:aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let characteristic = self.characteristic {
            self.uuidLabel.text = characteristic.uuid.uuidString
            
            self.permissionReadableLabel.text = self.booleanStringValue(characteristic.permissionEnabled(CBAttributePermissions.readable))
            self.permissionWriteableLabel.text = self.booleanStringValue(characteristic.permissionEnabled(CBAttributePermissions.writeable))
            self.permissionReadEncryptionLabel.text = self.booleanStringValue(characteristic.permissionEnabled(CBAttributePermissions.readEncryptionRequired))
            self.permissionWriteEncryptionLabel.text = self.booleanStringValue(characteristic.permissionEnabled(CBAttributePermissions.writeEncryptionRequired))
            
            self.propertyBroadcastLabel.text = self.booleanStringValue(characteristic.propertyEnabled(CBCharacteristicProperties.broadcast))
            self.propertyReadLabel.text = self.booleanStringValue(characteristic.propertyEnabled(CBCharacteristicProperties.read))
            self.propertyWriteWithoutResponseLabel.text = self.booleanStringValue(characteristic.propertyEnabled(CBCharacteristicProperties.writeWithoutResponse))
            self.propertyWriteLabel.text = self.booleanStringValue(characteristic.propertyEnabled(CBCharacteristicProperties.write))
            self.propertyNotifyLabel.text = self.booleanStringValue(characteristic.propertyEnabled(CBCharacteristicProperties.notify))
            self.propertyIndicateLabel.text = self.booleanStringValue(characteristic.propertyEnabled(CBCharacteristicProperties.indicate))
            self.propertyAuthenticatedSignedWritesLabel.text = self.booleanStringValue(characteristic.propertyEnabled(CBCharacteristicProperties.authenticatedSignedWrites))
            self.propertyExtendedPropertiesLabel.text = self.booleanStringValue(characteristic.propertyEnabled(CBCharacteristicProperties.extendedProperties))
            self.propertyNotifyEncryptionRequiredLabel.text = self.booleanStringValue(characteristic.propertyEnabled(CBCharacteristicProperties.notifyEncryptionRequired))
            self.propertyIndicateEncryptionRequiredLabel.text = self.booleanStringValue(characteristic.propertyEnabled(CBCharacteristicProperties.indicateEncryptionRequired))
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let characteristic = self.characteristic {
            self.navigationItem.title = characteristic.name
        }
        NotificationCenter.default.addObserver(self, selector:#selector(PeripheralManagerServiceCharacteristicViewController.didEnterBackground), name: NSNotification.Name.UIApplicationDidEnterBackground, object:nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationItem.title = ""
        NotificationCenter.default.removeObserver(self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any!) {
        if segue.identifier == MainStoryboard.peripheralManagerServiceCharacteristicValuesSegue {
            let viewController = segue.destination as! PeripheralManagerServicesCharacteristicValuesViewController
            viewController.characteristic = self.characteristic
            if let peripheralManagerViewController = self.peripheralManagerViewController {
                viewController.peripheralManagerViewController = peripheralManagerViewController
            }
        }
    }
    
    @objc func didEnterBackground() {
        Logger.debug()
        if let peripheralManagerViewController = self.peripheralManagerViewController {
            _ = self.navigationController?.popToViewController(peripheralManagerViewController, animated:false)
        }
    }
    
    func booleanStringValue(_ value:Bool) -> String {
        return value ? "YES" : "NO"
    }

}
