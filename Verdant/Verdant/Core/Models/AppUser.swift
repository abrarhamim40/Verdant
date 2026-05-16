//
//  AppUser.swift
//  Verdant
//
//  Created by Abrar Hamim on 5/17/26.
//

import Foundation
import SwiftData

@Model
final class AppUser {
    var id: UUID = UUID()
    var appleUserID: String?
    var email: String?
    var displayName: String?
    var createdAt: Date = Date()
    var isAnonymous: Bool = true
    var hasCompletedOnboarding: Bool = false

    var preferredLanguage: String = "en"
    var temperatureUnit: String = "C"
    var location: String?
    var locationLatitude: Double?
    var locationLongitude: Double?

    var totalScansCount: Int = 0
    var lastActiveDate: Date = Date()

    init() {
        let langCode = Locale.current.language.languageCode?.identifier ?? "en"
        self.preferredLanguage = langCode
        self.temperatureUnit = Locale.current.measurementSystem == .us ? "F" : "C"
    }
}

extension AppUser {
    static var preview: AppUser {
        let user = AppUser()
        user.displayName = "Test User"
        user.totalScansCount = 12
        return user
    }
}
