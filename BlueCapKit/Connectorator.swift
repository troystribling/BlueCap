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
    
    var onTimeout       : ((peripheral:Peripheral) -> ())?
    var onDisconnect    : ((peripheral:Peripheral) -> ())?
    var onConnect       : ((peripheral:Peripheral) -> ())?
    var onFailConnect   : ((peripheral:Peripheral, error:NSError!) -> ())?
    var onGiveup        : ((peripheral:Peripheral) -> ())?
    
    var timeoutCount = 0
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
    
    func onTimeout(onTimeout:(peripheral:Peripheral)->()) {
        self.onTimeout = onTimeout
    }
    
    func onDisconnect(onDisconnect:(peripheral:Peripheral)->()) {
        self.onDisconnect = onDisconnect
    }
    
    func onConnect(onConnect:(peripheral:Peripheral) -> ()) {
        self.onConnect = onConnect
    }

    func onFailConnect(onFailConnect:(peripheral:Peripheral, error:NSError!) -> ()) {
        self.onFailConnect = onFailConnect
    }

    func onGiveup(onGiveup:(peripheral:Peripheral) -> ()) {
        self.onGiveup = onGiveup
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
    
    func didConnect(peripheral:Peripheral) {
        if let onConnect = self.onConnect {
            self.timeoutCount = 0
            onConnect(peripheral:peripheral)
        }
    }
    
    func didFailConnect(peripheral:Peripheral, error:NSError!) {
        if let onFailConnect = self.onFailConnect {
            onFailConnect(peripheral:peripheral, error:error)
        }
    }
    
    // PRIVATE INTERFACE
    func callOnTimeout(peripheral:Peripheral) {
        if let onTimeout = self.onTimeout {
            onTimeout(peripheral:peripheral)
        } else {
            peripheral.reconnect()
        }
    }
    
    func callOnDisconnect(peripheral:Peripheral) {
        if let onDisconnect = self.onDisconnect {
            onDisconnect(peripheral:peripheral)
        } else {
            peripheral.reconnect()
        }
    }
    
    func callOnGiveUp(peripheral:Peripheral) {
        if let onGiveup = self.onGiveup {
            onGiveup(peripheral:peripheral)
        }
    }
}