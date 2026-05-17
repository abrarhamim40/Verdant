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

            MyPlantsTabPlaceholder()
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

private struct MyPlantsTabPlaceholder: View {
    @Query(sort: \Plant.dateAdded, order: .reverse) private var plants: [Plant]

    var body: some View {
        NavigationStack {
            if plants.isEmpty {
                ContentUnavailableView(
                    "No plants yet",
                    systemImage: "leaf",
                    description: Text("Scan a plant and tap the heart to save it here.")
                )
                .navigationTitle("My Plants")
            } else {
                List(plants) { plant in
                    NavigationLink(value: plant.id) {
                        HStack(spacing: 14) {
                            if let data = plant.imageData, let image = UIImage(data: data) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 56, height: 56)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            } else {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color.sage.opacity(0.3))
                                    .frame(width: 56, height: 56)
                                    .overlay(Image(systemName: "leaf").foregroundStyle(Color.forestGreen))
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(plant.displayName)
                                    .font(.body.weight(.semibold))
                                if let location = plant.location, !location.isEmpty {
                                    Text(location)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                }
                .navigationTitle("My Plants (\(plants.count))")
                .navigationDestination(for: UUID.self) { id in
                    if let plant = plants.first(where: { $0.id == id }) {
                        PlantDetailView(plant: plant)
                    }
                }
            }
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
