//
//  PhotoGuidanceTips.swift
//  Verdant
//
//  Created by Abrar Hamim on 5/17/26.
//
//  Composition guidance for plant photos. Plant.id accuracy is heavily input-dependent —
//  filling the frame, natural light, and disease close-ups all materially improve
//  identification and disease detection rates.

import SwiftUI

struct PhotoGuidanceTips: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("For best results", systemImage: "lightbulb.fill")
                .font(.headline)
                .foregroundStyle(Color.terracotta)

            VStack(alignment: .leading, spacing: 10) {
                GuidanceRow(icon: "sun.max.fill", text: "Use natural light — skip the flash")
                GuidanceRow(icon: "viewfinder", text: "Fill the frame with the plant")
                GuidanceRow(icon: "leaf.fill", text: "Close-up of affected leaves if diseased")
                GuidanceRow(icon: "camera.macro", text: "Multiple angles boost accuracy")
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.terracotta.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct GuidanceRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .frame(width: 24)
                .foregroundStyle(Color.terracotta)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.primary)
        }
    }
}

#Preview {
    PhotoGuidanceTips()
        .padding()
}
