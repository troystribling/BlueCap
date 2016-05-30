//
//  FLSerialIODictionary.swift
//  FutureLocation
//
//  Created by Troy Stribling on 1/24/16.
//  Copyright © 2016 Troy Stribling. All rights reserved.
//

import Foundation

// MARK: Serialize Dictionary Access
public class FLSerialIODictionary<T, U where T: Hashable> {

    var data = [T: U]()
    let queue: Queue

    init(_ queue: Queue) {
        self.queue = queue
    }

    var values: [U] {
        return self.queue.sync { return Array(self.data.values) }
    }

    var keys: [T] {
        return self.queue.sync { return Array(self.data.keys) }
    }

    subscript(key: T) -> U? {
        get {
            return self.queue.sync { return self.data[key] }
        }
        set {
            self.queue.sync { self.data[key] = newValue }
        }
    }

    func removeValueForKey(key: T) {
        self.queue.sync { self.data.removeValueForKey(key) }
    }

    func removeAll() {
        self.queue.sync { self.data.removeAll() }
    }

}
