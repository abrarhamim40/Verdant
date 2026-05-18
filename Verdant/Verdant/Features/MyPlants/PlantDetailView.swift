//
//  PlantDetailView.swift
//  Verdant
//
//  Created by Abrar Hamim on 5/17/26.
//
//  Day 14 introduced this as a minimal save-flow closer. Day 24-25 refined it:
//  hero photo header with name overlay, care setup as a 2x2 tile grid, full
//  TreatmentStepsView, and toolbar menu with edit/delete stubs.
//  Day 26 added the scan history timeline (every PlantScan, not just latest).
//  Day 27 wires the toolbar actions: edit sheet + delete confirmation.

import SwiftUI
import SwiftData
import os

struct PlantDetailView: View {
    let plant: Plant

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var showEditSheet = false
    @State private var showDeleteConfirm = false

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
                PlantHeroHeader(plant: plant)
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
        .sheet(isPresented: $showEditSheet) {
            EditPlantSheet(plant: plant)
        }
        .confirmationDialog(
            "Delete \(plant.displayName)?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete plant", role: .destructive) {
                deletePlant()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes the plant and all its scans. This can't be undone.")
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
                    Haptics.selection()
                    showEditSheet = true
                } label: {
                    Label("Edit plant", systemImage: "pencil")
                }

                Button(role: .destructive) {
                    Haptics.warning()
                    showDeleteConfirm = true
                } label: {
                    Label("Delete plant", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .accessibilityLabel("More actions")
        }
    }

    // MARK: - Delete

    private func deletePlant() {
        let name = plant.displayName
        // Snapshot reminder IDs before delete — cascade rule wipes the relationship,
        // and we need the IDs to cancel the pending UNNotificationRequests too.
        let reminderIDs = (plant.reminders ?? []).map(\.id)

        modelContext.delete(plant)
        do {
            try modelContext.save()
            Logger.data.info("Deleted plant: \(name, privacy: .public)")
            Haptics.success()
            Task { await NotificationService.shared.cancel(reminderIDs: reminderIDs) }
            dismiss()
        } catch {
            Logger.data.error("Delete failed: \(error.localizedDescription, privacy: .public)")
            Haptics.error()
        }
    }
}
