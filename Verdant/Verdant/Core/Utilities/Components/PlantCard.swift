//
//  PlantCard.swift
//  Verdant
//
//  Created by Abrar Hamim on 5/17/26.
//
//  Square-ish plant card for the My Plants grid. Photo on top, name + location
//  below, a small health dot in the corner of the photo so the user can see
//  at a glance which plants need attention.

import SwiftUI

struct PlantCard: View {
    let plant: Plant

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            photoArea
            metaArea
        }
    }

    // MARK: - Photo

    private var photoArea: some View {
        ZStack(alignment: .topTrailing) {
            photoOrPlaceholder
            healthDot
                .padding(8)
        }
    }

    @ViewBuilder
    private var photoOrPlaceholder: some View {
        // The clear Rectangle defines the exact 1:1 sizing — fills the
        // column width and uses aspectRatio to compute its own height.
        // The photo lives in .overlay so it fills the container regardless
        // of source aspect (portrait, landscape, square), with clipped()
        // trimming whatever overflows. Previously the image's intrinsic
        // dimensions leaked into layout — pushing siblings narrower or
        // wider than the column.
        Rectangle()
            .fill(Color.sage.opacity(0.3))
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                if let data = plant.imageData, let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 36, weight: .light))
                        .foregroundStyle(Color.forestGreen)
                }
            }
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var healthDot: some View {
        let color: Color = healthDotColor
        return Circle()
            .fill(color)
            .frame(width: 12, height: 12)
            .overlay(Circle().stroke(.white, lineWidth: 2))
            .accessibilityLabel("Health: \(plant.currentHealthStatus)")
    }

    private var healthDotColor: Color {
        switch plant.currentHealthStatus {
        case "healthy": return .forestGreen
        case "stressed": return .sage
        case "diseased", "critical": return .terracotta
        default: return .sage
        }
    }

    // MARK: - Meta

    private var metaArea: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(plant.displayName)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
                .foregroundStyle(.primary)
            if let location = plant.location, !location.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .font(.caption2)
                    Text(location)
                        .font(.caption)
                }
                .lineLimit(1)
                .foregroundStyle(.secondary)
            } else {
                Text(plant.scientificName ?? plant.name)
                    .font(.caption.italic())
                    .lineLimit(1)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 2)
    }
}
