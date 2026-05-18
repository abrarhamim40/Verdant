//
//  PlantListView.swift
//  Verdant
//
//  Created by Abrar Hamim on 5/17/26.
//
//  Day 22-23 deliverable: 2-column grid of saved plants with searchable text,
//  indoor/outdoor filter chips, and a sort menu. Replaces the placeholder
//  list that was inline in RootView during Day 14.

import SwiftUI
import SwiftData

struct PlantListView: View {
    @Query(sort: \Plant.dateAdded, order: .reverse) private var plants: [Plant]

    @State private var searchText = ""
    @State private var sortOption: SortOption = .dateAdded
    @State private var filterOption: FilterOption = .all
    @State private var showAddSheet = false

    enum SortOption: String, CaseIterable, Identifiable {
        case dateAdded = "Recently added"
        case name = "Name (A→Z)"
        case healthFirst = "Healthy first"
        case needsCare = "Needs care first"
        var id: Self { self }
    }

    enum FilterOption: String, CaseIterable, Identifiable {
        case all = "All"
        case indoor = "Indoor"
        case outdoor = "Outdoor"
        case growLight = "Grow light"
        var id: Self { self }
    }

    private var visiblePlants: [Plant] {
        var result = plants

        switch filterOption {
        case .all: break
        case .indoor: result = result.filter { $0.indoorOrOutdoor == "indoor" }
        case .outdoor: result = result.filter { $0.indoorOrOutdoor == "outdoor" }
        case .growLight: result = result.filter { $0.hasGrowLight }
        }

        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !query.isEmpty {
            result = result.filter { plant in
                plant.displayName.localizedCaseInsensitiveContains(query) ||
                plant.name.localizedCaseInsensitiveContains(query) ||
                (plant.location ?? "").localizedCaseInsensitiveContains(query) ||
                plant.commonNames.contains { $0.localizedCaseInsensitiveContains(query) }
            }
        }

        switch sortOption {
        case .dateAdded:
            result.sort { $0.dateAdded > $1.dateAdded }
        case .name:
            result.sort { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
        case .healthFirst:
            result.sort { Self.healthRank($0) < Self.healthRank($1) }
        case .needsCare:
            result.sort { Self.healthRank($0) > Self.healthRank($1) }
        }

        return result
    }

    /// Lower = healthier. Used by sort.
    private static func healthRank(_ plant: Plant) -> Int {
        switch plant.currentHealthStatus {
        case "healthy": return 0
        case "stressed": return 1
        case "diseased": return 2
        case "critical": return 3
        default: return 1
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if plants.isEmpty {
                    emptyState
                } else {
                    gridContent
                }
            }
            .navigationTitle(navigationTitle)
            .toolbar { toolbarContent }
            .navigationDestination(for: UUID.self) { id in
                if let plant = plants.first(where: { $0.id == id }) {
                    PlantDetailView(plant: plant)
                }
            }
            .searchable(text: $searchText, prompt: "Search plants")
            .background(Color.backgroundPrimary.ignoresSafeArea())
            .sheet(isPresented: $showAddSheet) {
                AddPlantSheet()
            }
        }
    }

    // MARK: - Title

    private var navigationTitle: String {
        plants.isEmpty ? "My Plants" : "My Plants (\(plants.count))"
    }

    // MARK: - Empty state

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No plants yet", systemImage: "leaf")
        } description: {
            Text("Scan a plant and tap the heart to save it here, or add one manually.")
        } actions: {
            Button {
                Haptics.selection()
                showAddSheet = true
            } label: {
                Label("Add a plant", systemImage: "plus")
                    .font(.subheadline.weight(.semibold))
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.forestGreen)
        }
    }

    private var noResultsState: some View {
        ContentUnavailableView.search(text: searchText)
    }

    // MARK: - Grid

    private let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    @ViewBuilder
    private var gridContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                filterChips

                if visiblePlants.isEmpty {
                    noResultsState
                        .padding(.top, 60)
                } else {
                    LazyVGrid(columns: columns, spacing: 18) {
                        ForEach(visiblePlants) { plant in
                            NavigationLink(value: plant.id) {
                                PlantCard(plant: plant)
                            }
                            .buttonStyle(.pressable)
                            .transition(.asymmetric(
                                insertion: .scale(scale: 0.85).combined(with: .opacity),
                                removal: .scale(scale: 0.9).combined(with: .opacity)
                            ))
                        }
                    }
                    .padding(.horizontal, 16)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: visiblePlants.map(\.id))
                }
            }
            .padding(.vertical, 12)
        }
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(FilterOption.allCases) { option in
                    chip(for: option)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private func chip(for option: FilterOption) -> some View {
        let isSelected = filterOption == option
        return Button {
            Haptics.selection()
            withAnimation(.easeInOut(duration: 0.2)) {
                filterOption = option
            }
        } label: {
            Text(option.rawValue)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? Color.forestGreen : Color.sage.opacity(0.18))
                .foregroundStyle(isSelected ? Color.white : Color.forestGreen)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                Haptics.selection()
                showAddSheet = true
            } label: {
                Image(systemName: "plus")
            }
            .accessibilityLabel("Add a plant")
        }
        if !plants.isEmpty {
            ToolbarItem(placement: .topBarLeading) {
                Menu {
                    Picker("Sort by", selection: $sortOption) {
                        ForEach(SortOption.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                } label: {
                    Image(systemName: "arrow.up.arrow.down.circle")
                }
                .accessibilityLabel("Sort plants")
            }
        }
    }
}

#Preview {
    PlantListView()
        .modelContainer(for: [
            AppUser.self,
            Plant.self,
            PlantScan.self,
            CareReminder.self,
            UserPreferences.self
        ], inMemory: true)
}
