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
    private var onTimeoutCallback           : ((peripheral:Peripheral) -> ())?
    private var onDisconnectCallback        : ((peripheral:Peripheral) -> ())?
    private var onForcedDisconnectCallback  : ((peripheral:Peripheral) -> ())?
    private var onConnectCallback           : ((peripheral:Peripheral) -> ())?
    private var onFailConnectCallback       : ((peripheral:Peripheral, error:NSError!) -> ())?
    private var onGiveupCallback            : ((peripheral:Peripheral) -> ())?
    
    private var timeoutCount    = 0
    private var disconnectCount = 0
    
    // PUBLIC
    public let timeoutRetries      : Int?
    public let disconnectRetries   : Int?

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
    
    public func onTimeout(onTimeoutCallback:(peripheral:Peripheral) -> ()) {
        self.onTimeoutCallback = onTimeoutCallback
    }
    
    public func onDisconnect(onDisconnectCallback:(peripheral:Peripheral) -> ()) {
        self.onDisconnectCallback = onDisconnectCallback
    }
    
    public func onConnect(onConnectCallback:(peripheral:Peripheral) -> ()) {
        self.onConnectCallback = onConnectCallback
    }

    public func onFailConnect(onFailConnectCallback:(peripheral:Peripheral, error:NSError!) -> ()) {
        self.onFailConnectCallback = onFailConnectCallback
    }

    public func onGiveup(onGiveupCallback:(peripheral:Peripheral) -> ()) {
        self.onGiveupCallback = onGiveupCallback
    }
    
    public func onForcedDisconnect(onForcedDisconnectCallback:(peripheral:Peripheral) -> ()) {
        self.onForcedDisconnectCallback = onForcedDisconnectCallback
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
        if let onForcedDisconnectCallback = self.onForcedDisconnectCallback {
            CentralManager.asyncCallback(){onForcedDisconnectCallback(peripheral:peripheral)}
        }
    }
    
    internal func didConnect(peripheral:Peripheral) {
        Logger.debug("Connectorator#didConnect")
        if let onConnectCallback = self.onConnectCallback {
            self.timeoutCount = 0
            CentralManager.asyncCallback(){onConnectCallback(peripheral:peripheral)}
        }
    }
    
    internal func didFailConnect(peripheral:Peripheral, error:NSError!) {
        Logger.debug("Connectorator#didFailConnect")
        if let onFailConnectCallback = self.onFailConnectCallback {
            CentralManager.asyncCallback(){onFailConnectCallback(peripheral:peripheral, error:error)}
        }
    }
    
    internal func callOnTimeout(peripheral:Peripheral) {
        if let onTimeoutCallback = self.onTimeoutCallback {
            CentralManager.asyncCallback(){onTimeoutCallback(peripheral:peripheral)}
        } else {
            peripheral.reconnect()
        }
    }
    
    internal func callOnDisconnect(peripheral:Peripheral) {
        if let onDisconnectCallback = self.onDisconnectCallback {
            CentralManager.asyncCallback(){onDisconnectCallback(peripheral:peripheral)}
        } else {
            peripheral.reconnect()
        }
    }
    
    internal func callOnGiveUp(peripheral:Peripheral) {
        if let onGiveupCallback = self.onGiveupCallback {
            CentralManager.asyncCallback(){onGiveupCallback(peripheral:peripheral)}
        }
    }
}