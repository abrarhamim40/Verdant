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
    let photoCount: Int

    @State private var showAlternatives = false
    @State private var showSaveSheet = false
    @State private var isSaved = false
    @Environment(\.dismiss) private var dismiss

    init(result: PlantAnalysisResult, primaryPhotoData: Data?, photoCount: Int = 1) {
        self.result = result
        self.primaryPhotoData = primaryPhotoData
        self.photoCount = photoCount
    }

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
                    if !isSaved {
                        Haptics.impact(.light)
                        showSaveSheet = true
                    }
                } label: {
                    Image(systemName: isSaved ? "heart.fill" : "heart")
                        .foregroundStyle(isSaved ? Color.terracotta : Color.forestGreen)
                        .contentTransition(.symbolEffect(.replace))
                }
                .accessibilityLabel(isSaved ? "Saved to My Plants" : "Save to My Plants")
                .disabled(isSaved)
            }
        }
        .sheet(isPresented: $showSaveSheet) {
            SavePlantSheet(
                result: result,
                primaryPhotoData: primaryPhotoData,
                photoCount: photoCount,
                onSaved: { isSaved = true }
            )
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
            SourceCitationsView(plantDetails: result.details)
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
                HStack(spacing: 8) {
                    HealthBadge(status: HealthBadge.Status(result: result))
                    if photoCount > 1 {
                        multiAngleBadge
                    }
                }
                .padding(.top, 6)
            }
            Spacer(minLength: 12)
            ConfidenceScoreView(confidence: result.confidence)
        }
    }

    private var displayName: String {
        result.commonNames.first ?? result.plantName
    }

    private var multiAngleBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "square.stack.3d.up.fill")
                .font(.caption)
            Text("\(photoCount) angles")
                .font(.subheadline.weight(.semibold))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color.sage.opacity(0.18))
        .foregroundStyle(Color.forestGreen)
        .clipShape(Capsule())
        .accessibilityLabel("Identified using \(photoCount) photos")
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
            TreatmentStepsView(plan: result.treatment)
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
                Haptics.selection()
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

}
