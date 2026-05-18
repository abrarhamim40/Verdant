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
        VStack(alignment: .leading, spacing: 0) {
            photoArea
            metaArea
                .padding(12)
        }
        .appCard(cornerRadius: 18)
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
        // 1:1 ratio container — photo as overlay so scaledToFill never leaks
        // into parent layout. Bottom corners stay square (the meta area is
        // attached below); top corners get the card's outer rounding.
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
            .overlay(alignment: .bottom) {
                // Soft gradient at bottom of photo for a subtle separator
                // against the white meta area below.
                LinearGradient(
                    colors: [.clear, .black.opacity(0.12)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 40)
                .allowsHitTesting(false)
            }
            .clipped()
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
