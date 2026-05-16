//
//  RootView.swift
//  Verdant
//
//  Created by Abrar Hamim on 5/16/26.
//

import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            HomeTabPlaceholder()
                .tabItem { Label("Home", systemImage: "house") }

            ScanTabPlaceholder()
                .tabItem { Label("Scan", systemImage: "camera.viewfinder") }

            MyPlantsTabPlaceholder()
                .tabItem { Label("My Plants", systemImage: "leaf") }

            SettingsTabPlaceholder()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .tint(Color("ForestGreen"))
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

private struct ScanTabPlaceholder: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Scan",
                systemImage: "camera.viewfinder",
                description: Text("Week 2–3 deliverable.")
            )
            .navigationTitle("Scan")
        }
    }
}

private struct MyPlantsTabPlaceholder: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "My Plants",
                systemImage: "leaf",
                description: Text("Week 4 deliverable.")
            )
            .navigationTitle("My Plants")
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
}
