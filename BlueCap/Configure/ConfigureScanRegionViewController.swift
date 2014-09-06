//
//  ConfigureScanRegionViewController.swift
//  BlueCap
//
//  Created by Troy Stribling on 9/6/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import UIKit
import BlueCapKit
import CoreLocation

class ConfigureScanRegionViewController : UITableViewController {
    
    @IBOutlet var latitudeLable   : UILabel!
    @IBOutlet var longitudeLable  : UILabel!

    var regionName : String?
    
    required init(coder aDecoder:NSCoder) {
        super.init(coder:aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let regionName = self.regionName {
            self.navigationItem.title = regionName
            if let region = ConfigStore.getScanRegion(regionName) {
                self.latitudeLable.text = "\(region.latitude)"
                self.longitudeLable.text = "\(region.longitude)"
                let location = CLLocation(latitude:region.latitude, longitude:region.longitude)
                let progressView = ProgressView()
                progressView.show()
                LocationManager.reverseGeocodeLocation(location,
                    reverseGeocodeSuccess:{(placemarks) in
                        if let placemark = placemarks.first {
                            Logger.debug("\(placemark)")
                        }
                        progressView.remove()
                    }, reverseGeocodeFailed:{(error) in
                        progressView.remove()
                        self.presentViewController(UIAlertController.alertOnError(error), animated:true, completion:nil)
                })
            }
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
}
