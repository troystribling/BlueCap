//
//  Connector.swift
//  BlueCap
//
//  Created by Troy Stribling on 6/14/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation

public class Connectorator {

    // PRIVATE
    private var timeoutCount    = 0
    private var disconnectCount = 0
    
    // PUBLIC
    public var onTimeout            : ((peripheral:Peripheral) -> ())?
    public var onDisconnect         : ((peripheral:Peripheral) -> ())?
    public var onForcedDisconnect   : ((peripheral:Peripheral) -> ())?
    public var onConnect            : ((peripheral:Peripheral) -> ())?
    public var onFailConnect        : ((peripheral:Peripheral, error:NSError!) -> ())?
    public var onGiveup             : ((peripheral:Peripheral) -> ())?

    public let timeoutRetries       : Int?
    public let disconnectRetries    : Int?

    public init () {
    }
    
    public init(initConnector:(connector:Connectorator) -> ()) {
        initConnector(connector:self)
    }
    
    public init(timeoutRetries:Int, disconnectRetries:Int, initConnector:((connector:Connectorator) -> ())? = nil) {
        self.timeoutRetries = timeoutRetries
        self.disconnectRetries = disconnectRetries
        if let runInitConnector = initConnector {
            runInitConnector(connector:self)
        }
    }
    
    // INTERNAL
    internal func didTimeout(peripheral:Peripheral) {
        Logger.debug("Connectorator#didTimeout")
        if let timeoutRetries = self.timeoutRetries {
            if self.timeoutCount < timeoutRetries {
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

    internal func didDisconnect(peripheral:Peripheral) {
        Logger.debug("Connectorator#didDisconnect")
        if let disconnectRetries = self.disconnectRetries {
            if self.disconnectCount < disconnectRetries {
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
    
    internal func didForceDisconnect(peripheral:Peripheral) {
        Logger.debug("Connectorator#didForceDisconnect")
        if let onForcedDisconnect = self.onForcedDisconnect {
            CentralManager.asyncCallback(){onForcedDisconnect(peripheral:peripheral)}
        }
    }
    
    internal func didConnect(peripheral:Peripheral) {
        Logger.debug("Connectorator#didConnect")
        if let onConnect = self.onConnect {
            self.timeoutCount = 0
            CentralManager.asyncCallback(){onConnect(peripheral:peripheral)}
        }
    }
    
    internal func didFailConnect(peripheral:Peripheral, error:NSError!) {
        Logger.debug("Connectorator#didFailConnect")
        if let onFailConnect = self.onFailConnect {
            CentralManager.asyncCallback(){onFailConnect(peripheral:peripheral, error:error)}
        }
    }
    
    internal func callOnTimeout(peripheral:Peripheral) {
        if let onTimeout = self.onTimeout {
            CentralManager.asyncCallback(){onTimeout(peripheral:peripheral)}
        } else {
            peripheral.reconnect()
        }
    }
    
    internal func callOnDisconnect(peripheral:Peripheral) {
        if let onDisconnect = self.onDisconnect {
            CentralManager.asyncCallback(){onDisconnect(peripheral:peripheral)}
        } else {
            peripheral.reconnect()
        }
    }
    
    internal func callOnGiveUp(peripheral:Peripheral) {
        if let onGiveup = self.onGiveup {
            CentralManager.asyncCallback(){onGiveup(peripheral:peripheral)}
        }
    }
}