//
//  Accelerometer.swift
//  Peripheral
//
//  Created by Troy Stribling on 4/19/15.
//  Copyright (c) 2015 Troy Stribling. The MIT License (MIT).
//

import UIKit
import CoreMotion
import BlueCapKit

class Accelerometer {
    
    var motionManager           = CMMotionManager()
    let queue                   = NSOperationQueue.mainQueue()
    let accelerationDataPromise = StreamPromise<CMAcceleration>(capacity: 10)
    
    var updatePeriod : NSTimeInterval {
        get {
            return self.motionManager.accelerometerUpdateInterval
        }
        set {
            self.motionManager.accelerometerUpdateInterval = newValue
        }
    }
    
    var accelerometerActive: Bool {
        return self.motionManager.accelerometerActive
    }
    
    var accelerometerAvailable: Bool {
        return self.motionManager.accelerometerAvailable
    }
    
    init() {
        self.motionManager.accelerometerUpdateInterval = 1.0
    }
    
    func startAcceleromterUpdates() -> FutureStream<CMAcceleration> {
        self.motionManager.startAccelerometerUpdatesToQueue(self.queue) { (data: CMAccelerometerData?, error: NSError?) in
            if let error = error {
                self.accelerationDataPromise.failure(error)
            } else {
                if let data = data {
                    self.accelerationDataPromise.success(data.acceleration)
                }
            }
        }
        return self.accelerationDataPromise.future
    }
    
    func stopAccelerometerUpdates() {
        self.motionManager.stopAccelerometerUpdates()
    }
    
}

