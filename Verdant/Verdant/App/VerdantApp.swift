//
//  VerdantApp.swift
//  Verdant
//
//  Created by Abrar Hamim on 5/16/26.
//

import SwiftUI
import SwiftData
import os

@main
struct VerdantApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    let sharedModelContainer: ModelContainer = {
        let schema = Schema([
            AppUser.self,
            Plant.self,
            PlantScan.self,
            CareReminder.self,
            UserPreferences.self
        ])

        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic
        )

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            Logger.data.critical("Failed to create ModelContainer: \(error.localizedDescription, privacy: .public)")
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentRoot()
        }
        .modelContainer(sharedModelContainer)
    }
}

/// Gates the first-launch experience: the OnboardingView runs once, sets
/// hasCompletedOnboarding via @AppStorage, and the user lands on the tab
/// bar from then on. Cross-fades between the two so the transition feels
/// designed rather than abrupt. Also applies the user-chosen appearance
/// (system / light / dark) so SettingsView's picker takes effect app-wide.
private struct ContentRoot: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("appearancePreference") private var appearanceRaw: String = AppearancePreference.system.rawValue

    private var appearance: AppearancePreference {
        AppearancePreference(rawValue: appearanceRaw) ?? .system
    }

    var body: some View {
        ZStack {
            if hasCompletedOnboarding {
                RootView()
                    .transition(.opacity)
            } else {
                OnboardingView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: hasCompletedOnboarding)
        .preferredColorScheme(appearance.colorScheme)
    }
}
