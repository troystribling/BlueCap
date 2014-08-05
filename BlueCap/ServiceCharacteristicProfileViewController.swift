//
//  ServiceCharacteristicProfileViewController.swift
//  BlueCap
//
//  Created by Troy Stribling on 8/5/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import UIKit
import BlueCapKit

class ServiceCharacteristicProfileViewController : UITableViewController {
    
    var characteristicProfile : CharacteristicProfile?
    
    @IBOutlet var uuidLabel                                 : UILabel!
    
    @IBOutlet var permissionRead                            : UILabel!
    @IBOutlet var permissionWrite                           : UILabel!
    @IBOutlet var permissionReadEncryption                  : UILabel!
    @IBOutlet var permissionWriteEncryption                 : UILabel!

    @IBOutlet var propertyBroadcastLabel                    : UILabel!
    @IBOutlet var propertyReadLabel                         : UILabel!
    @IBOutlet var propertyWriteWithoutResponseLabel         : UILabel!
    @IBOutlet var propertyWriteLabel                        : UILabel!
    @IBOutlet var propertyNotifyLabel                       : UILabel!
    @IBOutlet var propertyIndicateLabel                     : UILabel!
    @IBOutlet var propertyAuthenticatedSignedWritesLabel    : UILabel!
    @IBOutlet var propertyExtendedPropertiesLabel           : UILabel!
    @IBOutlet var propertyNotifyEncryptionRequiredLabel     : UILabel!
    @IBOutlet var propertyIndicateEncryptionRequiredLabel   : UILabel!

    struct MainStoryboard {
        static let serviceCharacteristicProfileValuesSegue = "ServiceCharacteristicProfileValues"
    }

    init(coder aDecoder:NSCoder!)  {
        super.init(coder:aDecoder)
    }
    
    override func viewDidLoad()  {
        super.viewDidLoad()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue!, sender: AnyObject!) {
    }
    

}
