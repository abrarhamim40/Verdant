//
//  ResponseCache.swift
//  Verdant
//
//  Created by Abrar Hamim on 5/17/26.
//

import Foundation

actor ResponseCache {
    private struct Entry {
        let data: Data
        let timestamp: Date
    }

    private var entries: [String: Entry] = [:]
    private let ttl: TimeInterval

    init(ttl: TimeInterval = 86_400) {
        self.ttl = ttl
    }

    func get(hash: String) -> Data? {
        guard let entry = entries[hash] else { return nil }
        if Date().timeIntervalSince(entry.timestamp) >= ttl {
            entries[hash] = nil
            return nil
        }
        return entry.data
    }

    func set(hash: String, data: Data) {
        entries[hash] = Entry(data: data, timestamp: Date())
    }

    func clear() {
        entries.removeAll()
    }
}
