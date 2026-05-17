//
//  SourceCitationsView.swift
//  Verdant
//
//  Created by Abrar Hamim on 5/17/26.
//
//  Trust-building footer: shows where the identification, description, and
//  care plan came from. Plant.id description text is CC BY-SA, so we attribute
//  the license. AI-generated content is flagged so users know to verify.

import SwiftUI

struct SourceCitationsView: View {
    let plantDetails: PlantDetails?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader

            row(label: "Identification",
                value: "Plant.id v3",
                link: nil,
                icon: "leaf.arrow.triangle.circlepath")

            if let articleURL = plantDetails?.url.flatMap(URL.init) {
                row(label: "Read more",
                    value: "Wikipedia",
                    link: articleURL,
                    icon: "book.closed")
            }

            if let description = plantDetails?.description {
                let licenseLabel = description.licenseName ?? "Public domain"
                row(label: "Description",
                    value: licenseLabel,
                    link: description.licenseUrl.flatMap(URL.init),
                    icon: "doc.text")
            }

            row(label: "Care plan",
                value: "AI-generated · verify with care",
                link: nil,
                icon: "wand.and.stars")
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.sage.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Subviews

    private var sectionHeader: some View {
        Label("Sources", systemImage: "info.circle.fill")
            .font(.headline)
            .foregroundStyle(Color.sage)
    }

    @ViewBuilder
    private func row(label: String, value: String, link: URL?, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .frame(width: 22)
                .foregroundStyle(Color.sage)
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            if let link {
                Link(destination: link) {
                    HStack(spacing: 4) {
                        Text(value)
                            .font(.subheadline.weight(.medium))
                        Image(systemName: "arrow.up.right")
                            .font(.caption2)
                    }
                    .foregroundStyle(Color.forestGreen)
                }
            } else {
                Text(value)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
            }
        }
    }
}
