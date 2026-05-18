//
//  Logger+Extensions.swift
//  Verdant
//
//  Created by Abrar Hamim on 5/16/26.
//

import Foundation
import os

extension Logger {
    nonisolated private static let subsystem = Bundle.main.bundleIdentifier ?? "com.verdant.app"

    nonisolated static let network = Logger(subsystem: subsystem, category: "network")
    nonisolated static let ai = Logger(subsystem: subsystem, category: "ai")
    nonisolated static let data = Logger(subsystem: subsystem, category: "data")
    nonisolated static let ui = Logger(subsystem: subsystem, category: "ui")
    nonisolated static let subscription = Logger(subsystem: subsystem, category: "subscription")
    nonisolated static let auth = Logger(subsystem: subsystem, category: "auth")
    nonisolated static let notifications = Logger(subsystem: subsystem, category: "notifications")
}
