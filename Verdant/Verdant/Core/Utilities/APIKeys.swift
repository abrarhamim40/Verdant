//
//  APIKeys.swift
//  Verdant
//
//  Created by Abrar Hamim on 5/16/26.
//

import Foundation

enum APIKeys {
    enum Environment: String {
        case development
        case staging
        case production
    }

    static let plantID: String = value(for: "PLANT_ID_API_KEY")
    static let gemini: String = value(for: "GEMINI_API_KEY")
    static let revenueCat: String = value(for: "REVENUECAT_API_KEY")
    static let postHog: String = optionalValue(for: "POSTHOG_API_KEY") ?? ""
    static let sentryDSN: String = optionalValue(for: "SENTRY_DSN") ?? ""

    static let environment: Environment = {
        let raw = optionalValue(for: "ENVIRONMENT") ?? "development"
        return Environment(rawValue: raw) ?? .development
    }()

    // MARK: - Loader

    private static let config: [String: Any] = {
        guard
            let url = Bundle.main.url(forResource: "Config", withExtension: "plist"),
            let data = try? Data(contentsOf: url),
            let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any]
        else {
            fatalError("Config.plist missing. Copy Config.example.plist → Resources/Config.plist and fill in real keys.")
        }
        return plist
    }()

    private static func value(for key: String) -> String {
        guard let raw = config[key] as? String, !raw.isEmpty, !raw.hasPrefix("YOUR_") else {
            fatalError("Config.plist key \"\(key)\" is missing or still a placeholder.")
        }
        return raw
    }

    private static func optionalValue(for key: String) -> String? {
        guard let raw = config[key] as? String, !raw.isEmpty, !raw.hasPrefix("YOUR_") else {
            return nil
        }
        return raw
    }
}
