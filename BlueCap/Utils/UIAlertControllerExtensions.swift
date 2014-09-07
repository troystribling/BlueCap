//
//  UIAlertViewExtensions.swift
//  BlueCap
//
//  Created by Troy Stribling on 7/6/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import UIKit

extension UIAlertController {
 
    class func alertOnError(error:NSError) -> UIAlertController {
        var alert = UIAlertController(title: "Error", message:error.localizedDescription, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
        return alert
    }


    class func alertOnError(message:String) -> UIAlertController {
        var alert = UIAlertController(title: "Error", message:message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
        return alert
    }

    class func alertWithMessage(message:String) -> UIAlertController {
        var alert = UIAlertController(title: "Message", message:message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
        return alert
    }

}