//
//  ServiceCharacteristicProfileViewController.swift
//  BlueCap
//
//  Created by Troy Stribling on 8/5/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import UIKit
import CoreBluetooth
import BlueCapKit

class ServiceCharacteristicProfileViewController : UITableViewController {
    
    var characteristicProfile: BCCharacteristicProfile?
    
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
        static let serviceCharacteristicProfileValuesSegue = "ServiceCharacteristicProfileValues"
    }

    required init?(coder aDecoder:NSCoder)  {
        super.init(coder:aDecoder)
    }
    
    override func viewDidLoad()  {
        super.viewDidLoad()
        if let characteristicProfile = self.characteristicProfile {

            self.navigationItem.title = characteristicProfile.name
            self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)

            self.uuidLabel.text = characteristicProfile.UUID.UUIDString
            
            self.permissionReadableLabel.text = self.booleanStringValue(characteristicProfile.permissionEnabled(CBAttributePermissions.Readable))
            self.permissionWriteableLabel.text = self.booleanStringValue(characteristicProfile.permissionEnabled(CBAttributePermissions.Writeable))
            self.permissionReadEncryptionLabel.text = self.booleanStringValue(characteristicProfile.permissionEnabled(CBAttributePermissions.ReadEncryptionRequired))
            self.permissionWriteEncryptionLabel.text = self.booleanStringValue(characteristicProfile.permissionEnabled(CBAttributePermissions.WriteEncryptionRequired))
            
            self.propertyBroadcastLabel.text = self.booleanStringValue(characteristicProfile.propertyEnabled(CBCharacteristicProperties.Broadcast))
            self.propertyReadLabel.text = self.booleanStringValue(characteristicProfile.propertyEnabled(CBCharacteristicProperties.Read))
            self.propertyWriteWithoutResponseLabel.text = self.booleanStringValue(characteristicProfile.propertyEnabled(CBCharacteristicProperties.WriteWithoutResponse))
            self.propertyWriteLabel.text = self.booleanStringValue(characteristicProfile.propertyEnabled(CBCharacteristicProperties.Write))
            self.propertyNotifyLabel.text = self.booleanStringValue(characteristicProfile.propertyEnabled(CBCharacteristicProperties.Notify))
            self.propertyIndicateLabel.text = self.booleanStringValue(characteristicProfile.propertyEnabled(CBCharacteristicProperties.Indicate))
            self.propertyAuthenticatedSignedWritesLabel.text = self.booleanStringValue(characteristicProfile.propertyEnabled(CBCharacteristicProperties.AuthenticatedSignedWrites))
            self.propertyExtendedPropertiesLabel.text = self.booleanStringValue(characteristicProfile.propertyEnabled(CBCharacteristicProperties.ExtendedProperties))
            self.propertyNotifyEncryptionRequiredLabel.text = self.booleanStringValue(characteristicProfile.propertyEnabled(CBCharacteristicProperties.NotifyEncryptionRequired))
            self.propertyIndicateEncryptionRequiredLabel.text = self.booleanStringValue(characteristicProfile.propertyEnabled(CBCharacteristicProperties.IndicateEncryptionRequired))
            
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        if segue.identifier == MainStoryboard.serviceCharacteristicProfileValuesSegue {
            let viewController = segue.destinationViewController as! ServiceCharacteristicProfileValuesViewController
            viewController.characteristicProfile = self.characteristicProfile
        }
    }
    
    func booleanStringValue(value: Bool) -> String {
        return value ? "YES" : "NO"
    }

}
