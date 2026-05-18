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
            RootView()
        }
        .modelContainer(sharedModelContainer)
    }
}
