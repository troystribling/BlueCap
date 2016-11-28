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
    
    var characteristicProfile: CharacteristicProfile?
    
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
            self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)

            self.uuidLabel.text = characteristicProfile.uuid.uuidString
            
            self.permissionReadableLabel.text = self.booleanStringValue(characteristicProfile.permissionEnabled(.readable))
            self.permissionWriteableLabel.text = self.booleanStringValue(characteristicProfile.permissionEnabled(.writeable))
            self.permissionReadEncryptionLabel.text = self.booleanStringValue(characteristicProfile.permissionEnabled(.readEncryptionRequired))
            self.permissionWriteEncryptionLabel.text = self.booleanStringValue(characteristicProfile.permissionEnabled(.writeEncryptionRequired))
            
            self.propertyBroadcastLabel.text = self.booleanStringValue(characteristicProfile.propertyEnabled(.broadcast))
            self.propertyReadLabel.text = self.booleanStringValue(characteristicProfile.propertyEnabled(.read))
            self.propertyWriteWithoutResponseLabel.text = self.booleanStringValue(characteristicProfile.propertyEnabled(.writeWithoutResponse))
            self.propertyWriteLabel.text = self.booleanStringValue(characteristicProfile.propertyEnabled(.write))
            self.propertyNotifyLabel.text = self.booleanStringValue(characteristicProfile.propertyEnabled(.notify))
            self.propertyIndicateLabel.text = self.booleanStringValue(characteristicProfile.propertyEnabled(.indicate))
            self.propertyAuthenticatedSignedWritesLabel.text = self.booleanStringValue(characteristicProfile.propertyEnabled(.authenticatedSignedWrites))
            self.propertyExtendedPropertiesLabel.text = self.booleanStringValue(characteristicProfile.propertyEnabled(.extendedProperties))
            self.propertyNotifyEncryptionRequiredLabel.text = self.booleanStringValue(characteristicProfile.propertyEnabled(.notifyEncryptionRequired))
            self.propertyIndicateEncryptionRequiredLabel.text = self.booleanStringValue(characteristicProfile.propertyEnabled(.indicateEncryptionRequired))
            
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any!) {
        if segue.identifier == MainStoryboard.serviceCharacteristicProfileValuesSegue {
            let viewController = segue.destination as! ServiceCharacteristicProfileValuesViewController
            viewController.characteristicProfile = self.characteristicProfile
        }
    }
    
    func booleanStringValue(_ value: Bool) -> String {
        return value ? "YES" : "NO"
    }

}
