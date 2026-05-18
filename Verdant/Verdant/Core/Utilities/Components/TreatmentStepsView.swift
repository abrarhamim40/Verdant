//
//  TreatmentStepsView.swift
//  Verdant
//
//  Created by Abrar Hamim on 5/17/26.
//
//  Reusable presentation of a Gemini TreatmentPlan: summary, watering/feeding
//  frequency chips, immediate actions, weekly care routine, and recovery
//  timeline. Used by DiagnosisResultView (full) and PlantDetailView (compact).

import SwiftUI

struct TreatmentStepsView: View {
    let plan: TreatmentPlan
    var compact: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !plan.summary.isEmpty {
                Text(plan.summary)
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)
            }

            frequencyChips

            if !compact, !plan.immediateActions.isEmpty {
                actionList(title: "Do this now", items: plan.immediateActions, accent: .forestGreen)
            }

            if !compact, !plan.weeklyCare.isEmpty {
                actionList(title: "Every week", items: plan.weeklyCare, accent: .forestGreen)
            }

            if !plan.recoveryTimeline.isEmpty {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "clock.fill")
                        .foregroundStyle(Color.sage)
                    Text(plan.recoveryTimeline)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 4)
            }
        }
    }

    // MARK: - Subviews

    private var frequencyChips: some View {
        HStack(spacing: 12) {
            frequencyChip(icon: "drop", label: "Water", days: plan.wateringFrequencyDays)
            frequencyChip(icon: "sparkles", label: "Feed", days: plan.fertilizingFrequencyDays)
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
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .accessibilityLabel("\(label) every \(days) days")
    }

    private func actionList(title: String, items: [String], accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .padding(.top, 4)
            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 6))
                        .foregroundStyle(accent)
                        .padding(.top, 7)
                    Text(item)
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}
