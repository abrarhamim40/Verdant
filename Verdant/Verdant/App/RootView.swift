//
//  RootView.swift
//  Verdant
//
//  Created by Abrar Hamim on 5/16/26.
//

import SwiftUI
import SwiftData

enum RootTab: String, Hashable {
    case home, scan, myPlants, settings
}

struct RootView: View {
    @SceneStorage("selectedTab") private var selectedTab: RootTab = .home

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeTabPlaceholder()
                .tabItem { Label("Home", systemImage: "house") }
                .tag(RootTab.home)

            ScanView()
                .tabItem { Label("Scan", systemImage: "camera.viewfinder") }
                .tag(RootTab.scan)

            PlantListView()
                .tabItem { Label("My Plants", systemImage: "leaf") }
                .tag(RootTab.myPlants)

            SettingsTabPlaceholder()
                .tabItem { Label("Settings", systemImage: "gearshape") }
                .tag(RootTab.settings)
        }
        .tint(.forestGreen)
    }
}

private struct HomeTabPlaceholder: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Home",
                systemImage: "house",
                description: Text("Week 4 deliverable.")
            )
            .navigationTitle("Verdant")
        }
    }
}

private struct SettingsTabPlaceholder: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Settings",
                systemImage: "gearshape",
                description: Text("Week 6+ deliverable.")
            )
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    RootView()
        .modelContainer(for: [
            AppUser.self,
            Plant.self,
            PlantScan.self,
            CareReminder.self,
            UserPreferences.self
        ], inMemory: true)
}
