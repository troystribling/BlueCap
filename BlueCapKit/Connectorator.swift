//
//  Connector.swift
//  BlueCap
//
//  Created by Troy Stribling on 6/14/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation

class Connectorator {

    let timeoutRetries : Int?
    let disconnectRetries : Int?
    
    var onTimeoutCallback           : ((peripheral:Peripheral) -> ())?
    var onDisconnectCallback        : ((peripheral:Peripheral) -> ())?
    var onForcedDisconnectCallback  : ((peripheral:Peripheral) -> ())?
    var onConnectCallback           : ((peripheral:Peripheral) -> ())?
    var onFailConnectCallback       : ((peripheral:Peripheral, error:NSError!) -> ())?
    var onGiveupCallback            : ((peripheral:Peripheral) -> ())?
    
    var timeoutCount    = 0
    var disconnectCount = 0
    
    // APPLICATION INTERFACE
    init () {
    }
    
    init(initConnector:(connector:Connectorator) -> ()) {
        initConnector(connector:self)
    }
    
    init(timeoutRetries:Int, disconnectRetries:Int) {
        self.timeoutRetries = timeoutRetries
        self.disconnectRetries = disconnectRetries
    }

    convenience init(timeoutRetries:Int, disconnectRetries:Int, initConnector:(connector:Connectorator) -> ()) {
        self.init(initConnector)
        self.timeoutRetries = timeoutRetries
        self.disconnectRetries = disconnectRetries
    }
    
    func onTimeout(onTimeoutCallback:(peripheral:Peripheral) -> ()) {
        self.onTimeoutCallback = onTimeoutCallback
    }
    
    func onDisconnect(onDisconnectCallback:(peripheral:Peripheral) -> ()) {
        self.onDisconnectCallback = onDisconnectCallback
    }
    
    func onConnect(onConnectCallback:(peripheral:Peripheral) -> ()) {
        self.onConnectCallback = onConnectCallback
    }

    func onFailConnect(onFailConnectCallback:(peripheral:Peripheral, error:NSError!) -> ()) {
        self.onFailConnectCallback = onFailConnectCallback
    }

    func onGiveup(onGiveupCallback:(peripheral:Peripheral) -> ()) {
        self.onGiveupCallback = onGiveupCallback
    }
    
    func onForcedDisconnect(onForcedDisconnectCallback:(peripheral:Peripheral) -> ()) {
        self.onForcedDisconnectCallback = onForcedDisconnectCallback
    }
    
    // INTERNAL INTERFACE
    func didTimeout(peripheral:Peripheral) {
        Logger.debug("Connectorator#didTimeout")
        if let timeoutRetries = self.timeoutRetries {
            if self.timeoutCount < self.timeoutRetries {
                self.callOnTimeout(peripheral)
                ++self.timeoutCount
            } else {
                self.callOnGiveUp(peripheral)
                self.timeoutCount = 0
            }
        } else {
            self.callOnTimeout(peripheral)
        }
    }

    func didDisconnect(peripheral:Peripheral) {
        Logger.debug("Connectorator#didDisconnect")
        if let disconnectRetries = self.disconnectRetries {
            if self.disconnectCount < self.disconnectRetries {
                ++self.disconnectCount
                self.callOnDisconnect(peripheral)
            } else {
                self.disconnectCount = 0
                self.callOnGiveUp(peripheral)
            }
        } else {
            self.callOnDisconnect(peripheral)
        }
    }
    
    func didForceDisconnect(peripheral:Peripheral) {
        Logger.debug("Connectorator#didForceDisconnect")
        if let onForcedDisconnectCallback = self.onForcedDisconnectCallback {
            CentralManager.asyncCallback(){onForcedDisconnectCallback(peripheral:peripheral)}
        }
    }
    
    func didConnect(peripheral:Peripheral) {
        Logger.debug("Connectorator#didConnect")
        if let onConnectCallback = self.onConnectCallback {
            self.timeoutCount = 0
            CentralManager.asyncCallback(){onConnectCallback(peripheral:peripheral)}
        }
    }
    
    func didFailConnect(peripheral:Peripheral, error:NSError!) {
        Logger.debug("Connectorator#didFailConnect")
        if let onFailConnectCallback = self.onFailConnectCallback {
            CentralManager.asyncCallback(){onFailConnectCallback(peripheral:peripheral, error:error)}
        }
    }
    
    // PROTECTED INTERFACE
    func callOnTimeout(peripheral:Peripheral) {
        if let onTimeoutCallback = self.onTimeoutCallback {
            CentralManager.asyncCallback(){onTimeoutCallback(peripheral:peripheral)}
        } else {
            peripheral.reconnect()
        }
    }
    
    func callOnDisconnect(peripheral:Peripheral) {
        if let onDisconnectCallback = self.onDisconnectCallback {
            CentralManager.asyncCallback(){onDisconnectCallback(peripheral:peripheral)}
        } else {
            peripheral.reconnect()
        }
    }
    
    func callOnGiveUp(peripheral:Peripheral) {
        if let onGiveupCallback = self.onGiveupCallback {
            CentralManager.asyncCallback(){onGiveupCallback(peripheral:peripheral)}
        }
    }
}