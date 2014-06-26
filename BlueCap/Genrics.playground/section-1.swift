// Playground - noun: a place where people can play

import UIKit

class Characteristic {
}

protocol CharateristicProfileProtocol {
    
    typealias T
    
    func serializeObject(serializeObjectCallback:(obejct:T) -> NSData)
    func serializeString(serializeStringCallback:(data:Dictionary<String, String>) -> NSData)
    func deserializeData(deserializeDataCallback:(data:NSData) -> T)
    func stringValue(stringValueCallback:(data:(T) -> Dictionary<String, String>))
    func afterDiscovered(afterDiscoveredCallback:(characteristic:Characteristic) -> ())

    func value(data:NSData) -> T
    func stringValue(object:T) -> Dictionary<String, String>
    func deserializeData(data:NSData) -> T
}