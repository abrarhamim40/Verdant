//
//  PlantHeroHeader.swift
//  Verdant
//
//  Created by Abrar Hamim on 5/18/26.
//
//  Day 27 split — the 380pt photo header at the top of PlantDetailView, with
//  overlaid serif title + optional scientific name and dual gradients (top
//  protects the toolbar, bottom keeps the title legible against bright photos).

import SwiftUI

struct PlantHeroHeader: View {
    let plant: Plant

    private let height: CGFloat = 380

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            photoOrPlaceholder
                .frame(height: height)
                .frame(maxWidth: .infinity)
                .clipped()

            LinearGradient(
                colors: [.black.opacity(0.35), .clear],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 120)
            .frame(maxWidth: .infinity, alignment: .top)
            .allowsHitTesting(false)

            LinearGradient(
                colors: [.clear, .black.opacity(0.65)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 180)
            .frame(maxWidth: .infinity, alignment: .bottom)
            .allowsHitTesting(false)

            titleBlock
        }
        .frame(height: height)
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(plant.displayName)
                .font(.system(.largeTitle, design: .serif).weight(.bold))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.35), radius: 4, y: 2)
            if let scientific = plant.scientificName, scientific != plant.displayName {
                Text(scientific)
                    .font(.subheadline.italic())
                    .foregroundStyle(.white.opacity(0.9))
                    .shadow(color: .black.opacity(0.35), radius: 3, y: 1)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var photoOrPlaceholder: some View {
        if let data = plant.imageData, let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            ZStack {
                Color.sage.opacity(0.35)
                Image(systemName: "leaf.fill")
                    .font(.system(size: 80, weight: .light))
                    .foregroundStyle(Color.forestGreen)
            }
        }
    }
}
