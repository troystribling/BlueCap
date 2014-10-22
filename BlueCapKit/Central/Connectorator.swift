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
    public var timeout           : ((peripheral:Peripheral) -> ())?
    public var disconnect        : ((peripheral:Peripheral) -> ())?
    public var forceDisconnect   : ((peripheral:Peripheral) -> ())?
    public var connect           : ((peripheral:Peripheral) -> ())?
    public var failedConnect     : ((peripheral:Peripheral, error:NSError!) -> ())?
    public var giveUp            : ((peripheral:Peripheral) -> ())?

    public let timeoutRetries       : Int?
    public let disconnectRetries    : Int?

    public init () {
    }
    
    public init(initializer:(connector:Connectorator) -> ()) {
        initializer(connector:self)
    }
    
    public init(timeoutRetries:Int?, disconnectRetries:Int?, initializer:((connector:Connectorator) -> ())? = nil) {
        self.timeoutRetries = timeoutRetries
        self.disconnectRetries = disconnectRetries
        if let initializer = initializer {
            initializer(connector:self)
        }
    }

    public convenience init(timeoutRetries:Int, initializer:((connector:Connectorator) -> ())? = nil) {
        self.init(timeoutRetries:timeoutRetries, disconnectRetries:nil, initializer:initializer)
    }

    public convenience init(disconnectRetries:Int, initializer:((connector:Connectorator) -> ())? = nil) {
        self.init(timeoutRetries:nil, disconnectRetries:disconnectRetries, initializer:initializer)
    }

    // INTERNAL
    internal func didTimeout(peripheral:Peripheral) {
        Logger.debug("Connectorator#didTimeout")
        if let timeoutRetries = self.timeoutRetries {
            if self.timeoutCount < timeoutRetries {
                self.callDidTimeout(peripheral)
                ++self.timeoutCount
            } else {
                self.callDidGiveUp(peripheral)
                self.timeoutCount = 0
            }
        } else {
            self.callDidTimeout(peripheral)
        }
    }

    internal func didDisconnect(peripheral:Peripheral) {
        Logger.debug("Connectorator#didDisconnect")
        if let disconnectRetries = self.disconnectRetries {
            if self.disconnectCount < disconnectRetries {
                ++self.disconnectCount
                self.callDidDisconnect(peripheral)
            } else {
                self.disconnectCount = 0
                self.callDidGiveUp(peripheral)
            }
        } else {
            self.callDidDisconnect(peripheral)
        }
    }
    
    internal func didForceDisconnect(peripheral:Peripheral) {
        Logger.debug("Connectorator#didForceDisconnect")
        if let forcedDisconnect = self.forceDisconnect {
            CentralManager.asyncCallback(){forcedDisconnect(peripheral:peripheral)}
        }
    }
    
    internal func didConnect(peripheral:Peripheral) {
        Logger.debug("Connectorator#didConnect")
        if let connect = self.connect {
            self.timeoutCount = 0
            CentralManager.asyncCallback(){connect(peripheral:peripheral)}
        }
    }
    
    internal func didFailConnect(peripheral:Peripheral, error:NSError!) {
        Logger.debug("Connectorator#didFailConnect")
        if let failedConnect = self.failedConnect {
            CentralManager.asyncCallback(){failedConnect(peripheral:peripheral, error:error)}
        }
    }
    
    internal func callDidTimeout(peripheral:Peripheral) {
        if let timeout = self.timeout {
            CentralManager.asyncCallback(){timeout(peripheral:peripheral)}
        } else {
            peripheral.reconnect()
        }
    }
    
    internal func callDidDisconnect(peripheral:Peripheral) {
        if let disconnect = self.disconnect {
            CentralManager.asyncCallback(){disconnect(peripheral:peripheral)}
        } else {
            peripheral.reconnect()
        }
    }
    
    internal func callDidGiveUp(peripheral:Peripheral) {
        if let giveUp = self.giveUp {
            CentralManager.asyncCallback(){giveUp(peripheral:peripheral)}
        }
    }
}