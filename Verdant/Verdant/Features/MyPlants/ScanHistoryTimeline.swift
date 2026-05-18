//
//  ScanHistoryTimeline.swift
//  Verdant
//
//  Created by Abrar Hamim on 5/18/26.
//
//  Day 26 — Vertical timeline of all PlantScan records for a plant.
//  PlantDetailView surfaces the latest scan in detail; this section gives
//  the user a photo journal of every scan that came before it so they can
//  compare health over time.

import SwiftUI

struct ScanHistoryTimeline: View {
    /// Caller passes scans pre-sorted (most recent first). The latest scan is
    /// already rendered in PlantDetailView, so callers typically slice it off.
    let scans: [PlantScan]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Label("Scan history", systemImage: "clock.arrow.circlepath")
                    .font(.headline)
                    .foregroundStyle(Color.forestGreen)
                Spacer()
                Text("\(scans.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.sage.opacity(0.20))
                    .clipShape(Capsule())
            }

            VStack(spacing: 0) {
                ForEach(Array(scans.enumerated()), id: \.element.id) { index, scan in
                    ScanHistoryRow(
                        scan: scan,
                        isLast: index == scans.count - 1
                    )
                }
            }
        }
    }
}

private struct ScanHistoryRow: View {
    let scan: PlantScan
    let isLast: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            timelineRail
            card
        }
    }

    // MARK: - Timeline rail

    private var timelineRail: some View {
        VStack(spacing: 0) {
            Circle()
                .fill(dotColor)
                .frame(width: 11, height: 11)
                .overlay(
                    Circle()
                        .stroke(Color.backgroundPrimary, lineWidth: 2)
                )
                .padding(.top, 18)
            if !isLast {
                Rectangle()
                    .fill(Color.sage.opacity(0.35))
                    .frame(width: 2)
                    .frame(maxHeight: .infinity)
            }
        }
        .frame(width: 11)
    }

    // MARK: - Card

    private var card: some View {
        HStack(spacing: 12) {
            photoThumbnail

            VStack(alignment: .leading, spacing: 4) {
                Text(scan.date, format: .dateTime.day().month(.abbreviated).year())
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)

                Text(scan.plantNameDetected.isEmpty ? "Unknown plant" : scan.plantNameDetected)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: healthIcon)
                            .font(.caption2)
                        Text(healthLabel)
                            .font(.caption.weight(.medium))
                    }
                    .foregroundStyle(dotColor)

                    Text("·")
                        .font(.caption)
                        .foregroundStyle(.tertiary)

                    Text("\(scan.confidencePercent)%")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if scan.photoCount > 1 {
                        Text("·")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                        HStack(spacing: 3) {
                            Image(systemName: "square.stack.3d.up.fill")
                                .font(.caption2)
                            Text("\(scan.photoCount)")
                                .font(.caption.weight(.medium))
                        }
                        .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.sage.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .padding(.bottom, isLast ? 0 : 10)
    }

    @ViewBuilder
    private var photoThumbnail: some View {
        if let data = scan.imageData, let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        } else {
            ZStack {
                Color.sage.opacity(0.25)
                Image(systemName: "leaf.fill")
                    .font(.system(size: 22, weight: .light))
                    .foregroundStyle(Color.forestGreen)
            }
            .frame(width: 60, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }

    // MARK: - Health mapping

    private var dotColor: Color {
        switch scan.healthStatus {
        case "healthy": return .forestGreen
        case "stressed": return .sage
        case "diseased", "critical": return .terracotta
        default: return .secondary
        }
    }

    private var healthIcon: String {
        switch scan.healthStatus {
        case "healthy": return "checkmark.circle.fill"
        case "stressed": return "eye.fill"
        case "diseased": return "cross.case.fill"
        case "critical": return "exclamationmark.triangle.fill"
        default: return "questionmark.circle"
        }
    }

    private var healthLabel: String {
        switch scan.healthStatus {
        case "healthy": return "Healthy"
        case "stressed": return "Monitor"
        case "diseased": return "Needs care"
        case "critical": return "Urgent"
        default: return "Unknown"
        }
    }
}
