//
//  UIAlertViewExtensions.swift
//  BlueCap
//
//  Created by Troy Stribling on 7/6/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import UIKit

extension UIAlertController {

    class func alertOnError(_ error: Swift.Error, handler: ((UIAlertAction?) -> Void)? = nil) -> UIAlertController {
        let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: handler))
        return alert
    }

    class func alertOnErrorWithMessage(_ message: String, handler: ((UIAlertAction?) -> Void)? = nil) -> UIAlertController {
        let alert = UIAlertController(title: "Error", message:message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler:handler))
        return alert
    }

    class func alertWithMessage(_ message: String, handler: ((UIAlertAction?) -> Void)? = nil) -> UIAlertController {
        let alert = UIAlertController(title: "Alert", message:message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler:handler))
        return alert
    }
    
}
