//
//  Connector.swift
//  BlueCap
//
//  Created by Troy Stribling on 6/14/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation

public class Connectorator {

    private var timeoutCount    = 0
    private var disconnectCount = 0
    
    internal var peripheral     : Peripheral?
    
    public var timeout          : (() -> ())?
    public var disconnect       : (() -> ())?
    public var forceDisconnect  : (() -> ())?
    public var connect          : (() -> ())?
    public var failedConnect    : ((error:NSError!) -> ())?
    public var giveUp           : (() -> ())?

    public var timeoutRetries           = -1
    public var disconnectRetries        = -1
    public var connectionTimeout        = 10.0
    public var characteristicTimeout    = 10.0

    public init () {
    }
    
    public init(initializer:(connector:Connectorator) -> ()) {
        initializer(connector:self)
    }
    
    // INTERNAL
    internal func didTimeout() {
        Logger.debug("Connectorator#didTimeout")
        if self.timeoutRetries > 0 {
            if self.timeoutCount < self.timeoutRetries {
                self.callDidTimeout()
                ++self.timeoutCount
            } else {
                self.callDidGiveUp()
                self.timeoutCount = 0
            }
        } else {
            self.callDidTimeout()
        }
    }

    internal func didDisconnect() {
        Logger.debug("Connectorator#didDisconnect")
        if self.disconnectRetries > 0 {
            if self.disconnectCount < self.disconnectRetries {
                ++self.disconnectCount
                self.callDidDisconnect()
            } else {
                self.disconnectCount = 0
                self.callDidGiveUp()
            }
        } else {
            self.callDidDisconnect()
        }
    }
    
    internal func didForceDisconnect() {
        Logger.debug("Connectorator#didForceDisconnect")
        if let forcedDisconnect = self.forceDisconnect {
            CentralManager.asyncCallback(){forcedDisconnect()}
        }
    }
    
    internal func didConnect() {
        Logger.debug("Connectorator#didConnect")
        if let connect = self.connect {
            self.timeoutCount = 0
            CentralManager.asyncCallback(){connect()}
        }
    }
    
    internal func didFailConnect(error:NSError!) {
        Logger.debug("Connectorator#didFailConnect")
        if let failedConnect = self.failedConnect {
            CentralManager.asyncCallback(){failedConnect(error:error)}
        }
    }
    
    internal func callDidTimeout() {
        if let timeout = self.timeout {
            CentralManager.asyncCallback(){timeout()}
        } else {
            self.peripheral?.reconnect()
        }
    }
    
    internal func callDidDisconnect() {
        if let disconnect = self.disconnect {
            CentralManager.asyncCallback(){disconnect()}
        } else {
            self.peripheral?.reconnect()
        }
    }
    
    internal func callDidGiveUp() {
        if let giveUp = self.giveUp {
            CentralManager.asyncCallback(){giveUp()}
        }
    }
}