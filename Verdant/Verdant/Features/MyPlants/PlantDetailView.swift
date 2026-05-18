//
//  PlantDetailView.swift
//  Verdant
//
//  Created by Abrar Hamim on 5/17/26.
//
//  Day 14 introduced this as a minimal save-flow closer. Day 24-25 refines it:
//  hero photo header with name overlay, care setup as a 2x2 tile grid, full
//  TreatmentStepsView, and toolbar menu with edit/delete stubs.
//  Day 26 will add scan history timeline; Day 27 wires the toolbar actions.

import SwiftUI
import SwiftData

struct PlantDetailView: View {
    let plant: Plant

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    private var latestScan: PlantScan? {
        plant.scans?.sorted { $0.date > $1.date }.first
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
                latestScanSection(analysis)
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

    // MARK: - Latest scan

    private func latestScanSection(_ analysis: PlantAnalysisResult) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Label("Latest scan", systemImage: "doc.text.image.fill")
                    .font(.headline)
                    .foregroundStyle(Color.forestGreen)
                Spacer()
                if let date = latestScan?.date {
                    Text(date, format: .relative(presentation: .named))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Identified as")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(analysis.plantName)
                        .font(.body.weight(.semibold))
                    if let scan = latestScan, scan.photoCount > 1 {
                        HStack(spacing: 4) {
                            Image(systemName: "square.stack.3d.up.fill")
                                .font(.caption2)
                            Text("\(scan.photoCount) angles")
                                .font(.caption.weight(.medium))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.sage.opacity(0.20))
                        .foregroundStyle(Color.forestGreen)
                        .clipShape(Capsule())
                    }
                }
                Spacer()
                ConfidenceScoreView(confidence: analysis.confidence)
            }

            if let disease = analysis.disease, analysis.hasDiseaseDetected {
                HStack(alignment: .firstTextBaseline) {
                    Image(systemName: "cross.case.fill")
                        .foregroundStyle(Color.terracotta)
                    Text(disease.name)
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    ConfidenceScoreView(confidence: disease.probability, style: .pill)
                }
                if let description = disease.details?.description {
                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Divider()
                .padding(.vertical, 4)

            TreatmentStepsView(plan: analysis.treatment)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.forestGreen.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
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
        Text("Scan history, edit, and care reminders arrive in Week 4-5.")
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
