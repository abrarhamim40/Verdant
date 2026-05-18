//
//  LatestScanSection.swift
//  Verdant
//
//  Created by Abrar Hamim on 5/18/26.
//
//  Day 26 split — the "Latest scan" card in PlantDetailView, factored out
//  so the parent stays under the 300-line guideline. Renders the most
//  recent analysis: identification, multi-angle badge, confidence ring,
//  optional disease block, and the full TreatmentStepsView.

import SwiftUI

struct LatestScanSection: View {
    let analysis: PlantAnalysisResult
    /// Optional so the section can render in previews / cache-only contexts
    /// without a backing SwiftData record (e.g. when shown before save).
    let scan: PlantScan?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            identification
            if let disease = analysis.disease, analysis.hasDiseaseDetected {
                diseaseBlock(disease)
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

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Label("Latest scan", systemImage: "doc.text.image.fill")
                .font(.headline)
                .foregroundStyle(Color.forestGreen)
            Spacer()
            if let date = scan?.date {
                Text(date, format: .relative(presentation: .named))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Identification

    private var identification: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Identified as")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(analysis.plantName)
                    .font(.body.weight(.semibold))
                if let scan, scan.photoCount > 1 {
                    multiAngleBadge(count: scan.photoCount)
                }
            }
            Spacer()
            ConfidenceScoreView(confidence: analysis.confidence)
        }
    }

    private func multiAngleBadge(count: Int) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "square.stack.3d.up.fill")
                .font(.caption2)
            Text("\(count) angles")
                .font(.caption.weight(.medium))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(Color.sage.opacity(0.20))
        .foregroundStyle(Color.forestGreen)
        .clipShape(Capsule())
    }

    // MARK: - Disease

    @ViewBuilder
    private func diseaseBlock(_ disease: DiseaseSuggestion) -> some View {
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
}
