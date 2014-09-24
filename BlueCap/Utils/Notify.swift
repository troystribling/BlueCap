//
//  Notify.swift
//  BlueCap
//
//  Created by Troy Stribling on 9/24/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import UIKit

class Notify {
    
    class func withMessage(message:String, eventCount:Int, viewController:UIViewController) {
        if UIApplication.sharedApplication().applicationState == .Background {
            let localNotification = UILocalNotification()
            localNotification.fireDate = nil
            localNotification.alertBody = message
            localNotification.soundName = UILocalNotificationDefaultSoundName
            localNotification.applicationIconBadgeNumber = eventCount
        } else {
            viewController.presentViewController(UIAlertController.alertWithMessage(message), animated:true, completion:nil)
        }

    }
}
