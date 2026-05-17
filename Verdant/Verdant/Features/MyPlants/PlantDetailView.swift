//
//  PlantDetailView.swift
//  Verdant
//
//  Created by Abrar Hamim on 5/17/26.
//
//  Day 14 minimal detail view — closes the save flow by giving the user
//  something meaningful to tap into. Day 24-25 will replace this with the
//  full detail screen (scan history timeline, edit/delete, care reminders).

import SwiftUI
import SwiftData

struct PlantDetailView: View {
    let plant: Plant

    private var latestScan: PlantScan? {
        plant.scans?.sorted { $0.date > $1.date }.first
    }

    private var latestAnalysis: PlantAnalysisResult? {
        guard let json = latestScan?.analysisJSON,
              let data = json.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(PlantAnalysisResult.self, from: data)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                photoHeader
                content
            }
        }
        .background(Color.backgroundPrimary.ignoresSafeArea())
        .navigationTitle(plant.displayName)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Photo

    @ViewBuilder
    private var photoHeader: some View {
        if let data = plant.imageData, let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(height: 260)
                .frame(maxWidth: .infinity)
                .clipped()
        } else {
            ZStack {
                Color.sage.opacity(0.3)
                Image(systemName: "leaf.fill")
                    .font(.system(size: 56, weight: .light))
                    .foregroundStyle(Color.forestGreen)
            }
            .frame(height: 260)
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Content

    private var content: some View {
        VStack(alignment: .leading, spacing: 20) {
            identificationSection
            careAttributesSection
            if let analysis = latestAnalysis {
                latestScanSection(analysis)
                SourceCitationsView(plantDetails: analysis.details)
            }
            footerSection
        }
        .padding(20)
    }

    private var identificationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(plant.displayName)
                .font(.system(.largeTitle, design: .serif).weight(.bold))
            if let scientific = plant.scientificName ?? Optional(plant.name), scientific != plant.displayName {
                Text(scientific)
                    .font(.subheadline.italic())
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 8) {
                healthBadge
                if let lastCheck = plant.lastHealthCheck {
                    Text("· Checked \(lastCheck, format: .relative(presentation: .named))")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
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

    private var careAttributesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Care setup", systemImage: "info.circle.fill")
                .font(.headline)
                .foregroundStyle(Color.forestGreen)

            attrRow(icon: "house", label: "Location", value: plant.location ?? "Not set")
            attrRow(icon: "sun.max", label: "Sunlight", value: plant.sunlightLevel.capitalized)
            attrRow(icon: plant.indoorOrOutdoor == "indoor" ? "sofa" : "tree", label: "Where", value: plant.indoorOrOutdoor.capitalized)
            attrRow(
                icon: "lightbulb",
                label: "Grow light",
                value: plant.hasGrowLight ? "Yes" : "No"
            )
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.sage.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func attrRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .frame(width: 22)
                .foregroundStyle(Color.forestGreen)
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.medium))
        }
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
            }

            TreatmentStepsView(plan: analysis.treatment, compact: true)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.forestGreen.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Footer

    private var footerSection: some View {
        Text("Scan history, reminders, and edit options arrive in Week 4.")
            .font(.footnote)
            .foregroundStyle(.tertiary)
            .frame(maxWidth: .infinity)
            .padding(.top, 8)
    }
}
