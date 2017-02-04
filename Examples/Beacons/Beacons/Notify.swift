//
//  Notify.swift
//  BlueCap
//
//  Created by Troy Stribling on 9/24/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//
import UIKit

class Notify {
    
    static var eventCount = 0
    
    class func resetEventCount() {
        eventCount = 0;
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
    
    class func withMessage(_ message:String) {
        if UIApplication.shared.applicationState != .active {
            eventCount += 1
            let localNotification = UILocalNotification()
            localNotification.alertBody = message
            localNotification.soundName = UILocalNotificationDefaultSoundName
            localNotification.applicationIconBadgeNumber = eventCount
            UIApplication.shared.presentLocalNotificationNow(localNotification)
        }
        
    }
    
}
