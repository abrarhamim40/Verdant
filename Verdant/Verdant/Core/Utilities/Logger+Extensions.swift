//
//  Logger+Extensions.swift
//  Verdant
//
//  Created by Abrar Hamim on 5/16/26.
//

import Foundation
import os

extension Logger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.verdant.app"

    static let network = Logger(subsystem: subsystem, category: "network")
    static let ai = Logger(subsystem: subsystem, category: "ai")
    static let data = Logger(subsystem: subsystem, category: "data")
    static let ui = Logger(subsystem: subsystem, category: "ui")
    static let subscription = Logger(subsystem: subsystem, category: "subscription")
    static let auth = Logger(subsystem: subsystem, category: "auth")
}
