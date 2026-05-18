//
//  PlantDetailView.swift
//  Verdant
//
//  Created by Abrar Hamim on 5/17/26.
//
//  Day 14 introduced this as a minimal save-flow closer. Day 24-25 refined it:
//  hero photo header with name overlay, care setup as a 2x2 tile grid, full
//  TreatmentStepsView, and toolbar menu with edit/delete stubs.
//  Day 26 adds scan history timeline (every PlantScan, not just the latest).
//  Day 27 wires the toolbar actions.

import SwiftUI
import SwiftData

struct PlantDetailView: View {
    let plant: Plant

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    private var sortedScans: [PlantScan] {
        (plant.scans ?? []).sorted { $0.date > $1.date }
    }

    private var latestScan: PlantScan? { sortedScans.first }

    /// Everything older than the latest scan — Day 26 timeline. The latest scan
    /// is already shown in detail above, so we slice it off to avoid duplication.
    private var previousScans: [PlantScan] {
        Array(sortedScans.dropFirst())
    }

    private var latestAnalysis: PlantAnalysisResult? {
        guard let json = latestScan?.analysisJSON,
              !json.isEmpty,
              let data = json.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(PlantAnalysisResult.self, from: data)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                heroHeader
                content
                    .padding(.top, 4)
            }
        }
        .ignoresSafeArea(edges: .top)
        .background(Color.backgroundPrimary.ignoresSafeArea())
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar { toolbarContent }
    }

    // MARK: - Hero header

    @ViewBuilder
    private var heroHeader: some View {
        ZStack(alignment: .bottomLeading) {
            photoOrPlaceholder
                .frame(height: 380)
                .frame(maxWidth: .infinity)
                .clipped()

            // Top gradient — protects the back button + ⋯ menu against bright photos
            LinearGradient(
                colors: [.black.opacity(0.35), .clear],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 120)
            .frame(maxWidth: .infinity, alignment: .top)
            .allowsHitTesting(false)

            // Bottom gradient — keeps the plant name legible regardless of photo
            LinearGradient(
                colors: [.clear, .black.opacity(0.65)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 180)
            .frame(maxWidth: .infinity, alignment: .bottom)
            .allowsHitTesting(false)

            VStack(alignment: .leading, spacing: 6) {
                Text(plant.displayName)
                    .font(.system(.largeTitle, design: .serif).weight(.bold))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.35), radius: 4, y: 2)
                if let scientific = plant.scientificName, scientific != plant.displayName {
                    Text(scientific)
                        .font(.subheadline.italic())
                        .foregroundStyle(.white.opacity(0.9))
                        .shadow(color: .black.opacity(0.35), radius: 3, y: 1)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: 380)
    }

    @ViewBuilder
    private var photoOrPlaceholder: some View {
        if let data = plant.imageData, let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            ZStack {
                Color.sage.opacity(0.35)
                Image(systemName: "leaf.fill")
                    .font(.system(size: 80, weight: .light))
                    .foregroundStyle(Color.forestGreen)
            }
        }
    }

    // MARK: - Content

    private var content: some View {
        VStack(alignment: .leading, spacing: 20) {
            statusRow
            careSetupSection
            if let analysis = latestAnalysis {
                LatestScanSection(analysis: analysis, scan: latestScan)
                if !previousScans.isEmpty {
                    ScanHistoryTimeline(scans: previousScans)
                }
                SourceCitationsView(plantDetails: analysis.details)
            } else {
                noScanCallout
            }
            footerSection
        }
        .padding(20)
    }

    // MARK: - Status row

    private var statusRow: some View {
        HStack(spacing: 10) {
            healthBadge
            if let lastCheck = plant.lastHealthCheck {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption2)
                    Text("Checked \(lastCheck, format: .relative(presentation: .named))")
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    private var healthBadge: some View {
        let status: HealthBadge.Status = {
            switch plant.currentHealthStatus {
            case "healthy": return .healthy
            case "stressed": return .watch
            case "diseased": return .treat
            case "critical": return .critical
            default: return .healthy
            }
        }()
        return HealthBadge(status: status)
    }

    // MARK: - Care setup tiles

    private var careSetupSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Care setup", systemImage: "info.circle.fill")
                .font(.headline)
                .foregroundStyle(Color.forestGreen)

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                careTile(icon: "house", label: "Location", value: plant.location ?? "Not set")
                careTile(icon: "sun.max", label: "Sunlight", value: plant.sunlightLevel.capitalized)
                careTile(
                    icon: plant.indoorOrOutdoor == "indoor" ? "sofa" : "tree",
                    label: "Where",
                    value: plant.indoorOrOutdoor.capitalized
                )
                careTile(
                    icon: "lightbulb",
                    label: "Grow light",
                    value: plant.hasGrowLight ? "Yes" : "No"
                )
            }
        }
    }

    private func careTile(icon: String, label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundStyle(Color.forestGreen)
                Text(label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
            }
            Text(value)
                .font(.body.weight(.medium))
                .foregroundStyle(.primary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.sage.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    // MARK: - No scan fallback

    private var noScanCallout: some View {
        VStack(spacing: 8) {
            Image(systemName: "photo.badge.exclamationmark")
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(.secondary)
            Text("No scan data")
                .font(.headline)
            Text("This plant was saved before scan history existed, or the analysis couldn't be decoded.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Color.sage.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Footer

    private var footerSection: some View {
        Text("Edit, delete, and care reminders arrive in Week 4-5.")
            .font(.footnote)
            .foregroundStyle(.tertiary)
            .frame(maxWidth: .infinity)
            .padding(.top, 4)
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Button {
                    // Day 27 wires edit sheet.
                } label: {
                    Label("Edit plant", systemImage: "pencil")
                }
                .disabled(true)

                Button(role: .destructive) {
                    // Day 27 wires delete with confirmation.
                } label: {
                    Label("Delete plant", systemImage: "trash")
                }
                .disabled(true)
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .accessibilityLabel("More actions")
        }
    }
}
