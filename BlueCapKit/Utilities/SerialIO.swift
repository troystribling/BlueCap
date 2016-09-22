//
//  SerialIODictionary.swift
//
//  Created by Troy Stribling on 1/24/16.
//  Copyright © 2016 Troy Stribling. All rights reserved.
//

import Foundation

// MARK: Serialize Dictionary Access
public class SerialIODictionary<T, U> where T: Hashable {

    fileprivate var data = [T: U]()
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

    var count: Int {
        return self.data.count
    }

    subscript(key: T) -> U? {
        get {
            return self.queue.sync { return self.data[key] }
        }
        set {
            self.queue.sync { self.data[key] = newValue }
        }
    }

    func removeValueForKey(_ key: T) {
        _ = self.queue.sync { self.data.removeValue(forKey: key) }
    }

    func removeAll() {
        self.queue.sync { self.data.removeAll() }
    }
    
}

// MARK: Serialize Array Access
public class SerialIOArray<T> {

    fileprivate var _data = [T]()
    let queue: Queue

    init(_ queue: Queue) {
        self.queue = queue
    }

    var data: [T] {
        get {
            return self.queue.sync { return self._data }
        }
        set {
            self.queue.sync { self._data = newValue }
        }
    }

    var first: T? {
        return self.queue.sync { return self._data.first }
    }

    var count: Int {
        return self.data.count
    }

    subscript(i: Int) -> T {
        get {
            return self.queue.sync { return self._data[i] }
        }
        set {
            self.queue.sync { self._data[i] = newValue }
        }
    }

    func append(_ value: T) {
        self.queue.sync { self._data.append(value) }
    }

    func removeAtIndex(_ i: Int) {
        _ = self.queue.sync { self._data.remove(at: i) }
    }

    func map<M>(_ transform: (T) -> M) -> [M] {
        return self._data.map(transform)
    }

}

