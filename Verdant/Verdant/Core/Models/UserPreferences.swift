//
//  UserPreferences.swift
//  Verdant
//
//  Created by Abrar Hamim on 5/17/26.
//

import Foundation
import SwiftData

@Model
final class UserPreferences {
    var id: UUID = UUID()

    var language: String = "en"
    var temperatureUnit: String = "C"
    var preferDarkMode: Bool?

    var notificationsEnabled: Bool = true
    var dailyReminderTime: Date = Date()
    var weeklyDigestEnabled: Bool = true

    var hasCompletedOnboarding: Bool = false
    var hasSeenPaywall: Bool = false
    var lastPaywallShown: Date?
    var lastReviewPromptDate: Date?

    var totalScansCount: Int = 0
    var totalPlantsCount: Int = 0

    init() {
        self.language = Locale.current.language.languageCode?.identifier ?? "en"
        self.temperatureUnit = Locale.current.measurementSystem == .us ? "F" : "C"

        var components = DateComponents()
        components.hour = 9
        components.minute = 0
        self.dailyReminderTime = Calendar.current.date(from: components) ?? Date()
    }
}
