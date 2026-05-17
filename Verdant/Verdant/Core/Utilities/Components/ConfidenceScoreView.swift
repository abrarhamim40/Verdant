//
//  ConfidenceScoreView.swift
//  Verdant
//
//  Created by Abrar Hamim on 5/17/26.
//
//  Visible % confidence — one of the user complaints from the 1,000 reviews:
//  competitors hide their confidence so users don't know when to trust the answer.

import SwiftUI

struct ConfidenceScoreView: View {
    let confidence: Double
    var style: Style = .ring

    enum Style {
        case ring
        case pill
    }

    private var percent: Int { Int(confidence * 100) }

    private var tier: Tier {
        if confidence >= 0.85 { return .high }
        if confidence >= 0.70 { return .medium }
        return .low
    }

    enum Tier {
        case high, medium, low

        var color: Color {
            switch self {
            case .high: return .forestGreen
            case .medium: return .sage
            case .low: return .terracotta
            }
        }

        var label: String {
            switch self {
            case .high: return "Confident"
            case .medium: return "Likely"
            case .low: return "Uncertain"
            }
        }
    }

    var body: some View {
        switch style {
        case .ring: ring
        case .pill: pill
        }
    }

    private var ring: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .stroke(tier.color.opacity(0.15), lineWidth: 8)
                Circle()
                    .trim(from: 0, to: confidence)
                    .stroke(tier.color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.6), value: confidence)
                VStack(spacing: 0) {
                    Text("\(percent)")
                        .font(.title.bold())
                        .foregroundStyle(tier.color)
                    Text("%")
                        .font(.caption.bold())
                        .foregroundStyle(tier.color.opacity(0.8))
                }
            }
            .frame(width: 80, height: 80)
            Text(tier.label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(tier.color)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(percent) percent confidence, \(tier.label)")
    }

    private var pill: some View {
        Text("\(percent)% \(tier.label.lowercased())")
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(tier.color.opacity(0.18))
            .foregroundStyle(tier.color)
            .clipShape(Capsule())
    }
}

#Preview {
    VStack(spacing: 24) {
        HStack(spacing: 24) {
            ConfidenceScoreView(confidence: 0.92)
            ConfidenceScoreView(confidence: 0.76)
            ConfidenceScoreView(confidence: 0.55)
        }
        VStack(alignment: .leading, spacing: 8) {
            ConfidenceScoreView(confidence: 0.92, style: .pill)
            ConfidenceScoreView(confidence: 0.76, style: .pill)
            ConfidenceScoreView(confidence: 0.55, style: .pill)
        }
    }
    .padding()
}
