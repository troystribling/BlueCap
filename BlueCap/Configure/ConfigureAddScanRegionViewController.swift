//
//  ConfigureAddScanRegionViewController.swift
//  BlueCap
//
//  Created by Troy Stribling on 9/3/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import UIKit
import BlueCapKit
import CoreLocation

class ConfigureAddScanRegionViewController : UIViewController, UITextFieldDelegate {
    
    @IBOutlet var nameTextField    : UITextField!

    required init(coder aDecoder:NSCoder) {
        super.init(coder:aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    // UITextFieldDelegate
    func textFieldShouldReturn(textField: UITextField!) -> Bool {
        if let name = self.nameTextField.text {
            if !name.isEmpty {
                let progressView = ProgressView()
                progressView.show()
                LocationManager.sharedInstance().startUpdatingLocation() {(locationManager) in
                    locationManager.locationsUpdateSuccess = {(locations) in
                        locationManager.desiredAccuracy = kCLLocationAccuracyBest
                        if let location = locations.last {
                            Logger.debug("location update received: \(location)")
                            locationManager.stopUpdatingLocation()
                            ConfigStore.addScanRegion(name, region:location.coordinate)
                        }
                        progressView.remove()
                        self.navigationController?.popViewControllerAnimated(true)
                    }
                    locationManager.locationsUpdateFailed = {(error:NSError!) in
                        progressView.remove()
                        self.presentViewController(UIAlertController.alertOnError(error), animated:true, completion:nil)
                        self.navigationController?.popViewControllerAnimated(true)
                    }
                }
                return true
            } else {
                return false
            }
        } else {
            return false
        }
    }
    
}
