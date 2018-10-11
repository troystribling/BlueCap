//
//  Notify.swift
//  BlueCap
//
//  Created by Troy Stribling on 9/24/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//
import UIKit
import UserNotifications

class Notify {
    
    static var eventCount = 0
    
    class func resetEventCount() {
        eventCount = 0;
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
    
    class func withMessage(_ message:String) {
        if UIApplication.shared.applicationState != .active {
            eventCount += 1
            let content = UNMutableNotificationContent()
            content.title = ""
            content.body = message
            content.sound = UNNotificationSound.default
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.0, repeats: false)
            let request = UNNotificationRequest(identifier: "Immediate", content: content, trigger: trigger)
            let center = UNUserNotificationCenter.current()
            center.add(request)
        }
        
    }
    
}
