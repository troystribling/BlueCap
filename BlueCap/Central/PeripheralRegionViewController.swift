//
//  PeripheralRegionViewController.swift
//  BlueCap
//
//  Created by Troy Stribling on 11/14/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import UIKit
import BlueCapKit
import CoreLocation

class PeripheralRegionViewController : UITableViewController {
    
    @IBOutlet var latitudeLabel     : UILabel!
    @IBOutlet var longitudeLabel    : UILabel!
    @IBOutlet var address1Label     : UILabel!
    @IBOutlet var address2Label     : UILabel!
    @IBOutlet var address3Label     : UILabel!
    
    var peripheral : Peripheral!
    
    required init(coder aDecoder:NSCoder) {
        super.init(coder:aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        if let regionName = self.regionName {
//            self.navigationItem.title = peri
//            if let region = ConfigStore.getScanRegion(regionName) {
//                self.latitudeLabel.text = Double(region.latitude).format(".6")
//                self.longitudeLabel.text = Double(region.longitude).format(".6")
//                let location = CLLocation(latitude:region.latitude, longitude:region.longitude)
//                let progressView = ProgressView()
//                progressView.show()
//                LocationManager.reverseGeocodeLocation(location,
//                    reverseGeocodeSuccess:{(placemarks) in
//                        if let placemark = placemarks.first {
//                            if let address:AnyObject = placemark.addressDictionary["FormattedAddressLines"] {
//                                if let address = address as? [String] {
//                                    if address.count == 3 {
//                                        self.address1Label.text = address[0]
//                                        self.address2Label.text = address[1]
//                                        self.address3Label.text = address[2]
//                                    }
//                                }
//                            }
//                        }
//                        progressView.remove()
//                    }, reverseGeocodeFailed:{(error) in
//                        progressView.remove()
//                        self.presentViewController(UIAlertController.alertOnError(error), animated:true, completion:nil)
//                })
//            }
//        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
}