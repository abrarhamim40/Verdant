//
//  DiagnosisResultView.swift
//  Verdant
//
//  Created by Abrar Hamim on 5/17/26.
//
//  Full-screen diagnosis: plant photo header → identification + confidence ring +
//  health badge → care plan (immediate, weekly, warnings, prevention, timeline) →
//  alternative matches (collapsible). Day 14 will add the "Save this plant" sheet.

import SwiftUI

struct DiagnosisResultView: View {
    let result: PlantAnalysisResult
    let primaryPhotoData: Data?

    @State private var showAlternatives = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                photoHeader
                content
            }
        }
        .background(Color.backgroundPrimary.ignoresSafeArea())
        .navigationBarBackButtonHidden(false)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    // Day 14 wires this to "save to My Plants" sheet.
                } label: {
                    Image(systemName: "heart")
                }
                .accessibilityLabel("Save to My Plants")
            }
        }
    }

    // MARK: - Photo header

    @ViewBuilder
    private var photoHeader: some View {
        if let data = primaryPhotoData, let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(height: 280)
                .frame(maxWidth: .infinity)
                .clipped()
                .overlay(alignment: .bottom) {
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.4)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 120)
                }
        } else {
            placeholderHeader
        }
    }

    private var placeholderHeader: some View {
        ZStack {
            Color.sage.opacity(0.3)
            Image(systemName: "leaf.fill")
                .font(.system(size: 64, weight: .light))
                .foregroundStyle(Color.forestGreen)
        }
        .frame(height: 280)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Body

    private var content: some View {
        VStack(alignment: .leading, spacing: 24) {
            identificationSection
            if result.needsExpertReview {
                lowConfidenceCallout
            }
            if let disease = result.disease, result.hasDiseaseDetected {
                diseaseSection(disease)
            }
            treatmentSection
            warningSignsSection
            preventionSection
            if !result.alternativeMatches.isEmpty {
                alternativesSection
            }
            Spacer(minLength: 32)
        }
        .padding(20)
    }

    // MARK: - Identification

    private var identificationSection: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(displayName)
                    .font(.system(.largeTitle, design: .serif).weight(.bold))
                    .fixedSize(horizontal: false, vertical: true)
                if let scientific = result.scientificName, scientific != result.plantName {
                    Text(scientific)
                        .font(.subheadline.italic())
                        .foregroundStyle(.secondary)
                }
                if !commonNamesExcludingPrimary.isEmpty {
                    Text(commonNamesExcludingPrimary.joined(separator: " · "))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                HealthBadge(status: HealthBadge.Status(result: result))
                    .padding(.top, 6)
            }
            Spacer(minLength: 12)
            ConfidenceScoreView(confidence: result.confidence)
        }
    }

    private var displayName: String {
        result.commonNames.first ?? result.plantName
    }

    private var commonNamesExcludingPrimary: [String] {
        Array(result.commonNames.dropFirst()).prefix(4).map { $0 }
    }

    // MARK: - Low confidence

    private var lowConfidenceCallout: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Color.terracotta)
            VStack(alignment: .leading, spacing: 4) {
                Text("We're not fully sure")
                    .font(.subheadline.weight(.semibold))
                Text("Confidence is below 70%. Consider another photo from a different angle, or check the alternatives below.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.terracotta.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: - Disease

    private func diseaseSection(_ disease: DiseaseSuggestion) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("Possible issue", icon: "cross.case.fill", tint: .terracotta)
            HStack(alignment: .firstTextBaseline) {
                Text(disease.name)
                    .font(.title3.weight(.semibold))
                Spacer()
                ConfidenceScoreView(confidence: disease.probability, style: .pill)
            }
            if let description = disease.details?.description {
                Text(description)
                    .font(.body)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.terracotta.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Treatment

    private var treatmentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Care plan", icon: "drop.fill", tint: .forestGreen)
            Text(result.treatment.summary)
                .font(.body)
            HStack(spacing: 12) {
                frequencyChip(icon: "drop", label: "Water", days: result.treatment.wateringFrequencyDays)
                frequencyChip(icon: "sparkles", label: "Feed", days: result.treatment.fertilizingFrequencyDays)
            }
            if !result.treatment.immediateActions.isEmpty {
                actionList(title: "Do this now", items: result.treatment.immediateActions)
            }
            if !result.treatment.weeklyCare.isEmpty {
                actionList(title: "Every week", items: result.treatment.weeklyCare)
            }
            if !result.treatment.recoveryTimeline.isEmpty {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "clock.fill")
                        .foregroundStyle(Color.sage)
                    Text(result.treatment.recoveryTimeline)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 6)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.sage.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Warning signs

    @ViewBuilder
    private var warningSignsSection: some View {
        if !result.treatment.warningSigns.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                sectionHeader("Watch for", icon: "eye.fill", tint: .terracotta)
                ForEach(result.treatment.warningSigns, id: \.self) { sign in
                    bulletRow(sign, color: .terracotta)
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.terracotta.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    // MARK: - Prevention

    @ViewBuilder
    private var preventionSection: some View {
        if !result.treatment.preventionTips.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                sectionHeader("Prevention", icon: "shield.fill", tint: .forestGreen)
                ForEach(result.treatment.preventionTips, id: \.self) { tip in
                    bulletRow(tip, color: .forestGreen)
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.forestGreen.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    // MARK: - Alternative matches

    private var alternativesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    showAlternatives.toggle()
                }
            } label: {
                HStack {
                    sectionHeader("Could also be", icon: "questionmark.circle.fill", tint: .sage)
                    Spacer()
                    Image(systemName: showAlternatives ? "chevron.up" : "chevron.down")
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)

            if showAlternatives {
                VStack(spacing: 8) {
                    ForEach(result.alternativeMatches) { alt in
                        alternativeRow(alt)
                    }
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.sage.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func alternativeRow(_ suggestion: PlantSuggestion) -> some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(suggestion.details?.commonNames?.first ?? suggestion.name)
                    .font(.body.weight(.medium))
                if suggestion.details?.commonNames?.first != nil {
                    Text(suggestion.name)
                        .font(.caption.italic())
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            ConfidenceScoreView(confidence: suggestion.probability, style: .pill)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Reusable bits

    private func sectionHeader(_ title: String, icon: String, tint: Color) -> some View {
        Label(title, systemImage: icon)
            .font(.headline)
            .foregroundStyle(tint)
    }

    private func bulletRow(_ text: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "circle.fill")
                .font(.system(size: 6))
                .foregroundStyle(color)
                .padding(.top, 7)
            Text(text)
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func actionList(title: String, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .padding(.top, 4)
            ForEach(items, id: \.self) { item in
                bulletRow(item, color: .forestGreen)
            }
        }
    }

    private func frequencyChip(icon: String, label: String, days: Int) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundStyle(Color.forestGreen)
            Text("\(label) · \(days)d")
                .font(.subheadline.weight(.medium))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.6))
        .clipShape(Capsule())
    }
}
