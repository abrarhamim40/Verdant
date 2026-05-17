//
//  HealthBadge.swift
//  Verdant
//
//  Created by Abrar Hamim on 5/17/26.
//
//  At-a-glance plant health indicator. Maps PlantAnalysisResult disease state
//  to one of four states so the user knows immediately how concerned to be.

import SwiftUI

struct HealthBadge: View {
    let status: Status

    enum Status {
        case healthy
        case watch
        case treat
        case critical

        init(result: PlantAnalysisResult) {
            guard let disease = result.disease, result.hasDiseaseDetected else {
                self = .healthy
                return
            }
            switch disease.probability {
            case 0.85...: self = .critical
            case 0.70..<0.85: self = .treat
            default: self = .watch
            }
        }

        var label: String {
            switch self {
            case .healthy: return "Healthy"
            case .watch: return "Monitor"
            case .treat: return "Needs Care"
            case .critical: return "Urgent"
            }
        }

        var icon: String {
            switch self {
            case .healthy: return "checkmark.circle.fill"
            case .watch: return "eye.fill"
            case .treat: return "cross.case.fill"
            case .critical: return "exclamationmark.triangle.fill"
            }
        }

        var color: Color {
            switch self {
            case .healthy: return .forestGreen
            case .watch: return .sage
            case .treat: return .terracotta
            case .critical: return .terracotta
            }
        }
    }

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: status.icon)
                .font(.subheadline)
            Text(status.label)
                .font(.subheadline.weight(.semibold))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(status.color.opacity(0.18))
        .foregroundStyle(status.color)
        .clipShape(Capsule())
        .accessibilityLabel("Plant health: \(status.label)")
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 12) {
        HealthBadge(status: .healthy)
        HealthBadge(status: .watch)
        HealthBadge(status: .treat)
        HealthBadge(status: .critical)
    }
    .padding()
}
