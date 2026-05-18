//
//  AppearancePreference.swift
//  Verdant
//
//  Created by Abrar Hamim on 5/19/26.
//
//  User-chosen appearance override. Stored in @AppStorage so it survives
//  launches and applies before the SwiftUI hierarchy renders. Resolves to a
//  SwiftUI ColorScheme? — `nil` means "follow the system" so iOS still
//  drives the smooth fade when the OS-level appearance changes.

import SwiftUI

enum AppearancePreference: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: Self { self }

    var label: String {
        switch self {
        case .system: return "System"
        case .light:  return "Light"
        case .dark:   return "Dark"
        }
    }

    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light:  return "sun.max.fill"
        case .dark:   return "moon.stars.fill"
        }
    }

    /// Mapped to SwiftUI's optional color scheme. nil tells the framework to
    /// stop overriding so the system value bleeds through.
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }
}
