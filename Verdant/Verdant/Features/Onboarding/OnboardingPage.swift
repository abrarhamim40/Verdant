//
//  OnboardingPage.swift
//  Verdant
//
//  Created by Abrar Hamim on 5/19/26.
//
//  One page of the onboarding flow. Phased entrance animations so the hero,
//  title, body, and highlights stagger in instead of popping together —
//  PictureThis-style premium feel without dragging in a third-party motion
//  library. Pure SwiftUI: phaseAnimator + symbolEffect + matchedGeometryEffect.

import SwiftUI

struct OnboardingPage: View {
    let theme: Theme

    struct Theme {
        let title: String
        let subtitle: String
        let body: String
        let icon: String
        let highlights: [String]
        let topTint: Color
        let bottomTint: Color
        /// Pulsing scale boost on the hero icon — varies per page so each one
        /// reads as a distinct moment.
        let heroPulse: Double
    }

    @State private var phase: AnimationPhase = .preEntry

    enum AnimationPhase: CaseIterable {
        case preEntry, midEntry, settled
    }

    var body: some View {
        VStack(spacing: 28) {
            Spacer(minLength: 20)

            heroIcon

            VStack(spacing: 12) {
                Text(theme.title)
                    .font(.system(.largeTitle, design: .serif).weight(.bold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.18), radius: 6, y: 2)
                    .opacity(phase == .preEntry ? 0 : 1)
                    .offset(y: phase == .preEntry ? 20 : 0)

                Text(theme.subtitle)
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .opacity(phase == .preEntry ? 0 : (phase == .midEntry ? 0.7 : 1))
                    .offset(y: phase == .preEntry ? 16 : 0)
            }

            Text(theme.body)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.78))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 36)
                .opacity(phase == .settled ? 1 : 0)
                .offset(y: phase == .settled ? 0 : 12)

            if !theme.highlights.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(Array(theme.highlights.enumerated()), id: \.offset) { index, item in
                        highlightRow(item, index: index)
                    }
                }
                .padding(.horizontal, 28)
                .padding(.top, 8)
            }

            Spacer(minLength: 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear { runEntranceAnimation() }
    }

    // MARK: - Hero icon

    private var heroIcon: some View {
        ZStack {
            // Soft outer halo so the icon pops against the gradient.
            Circle()
                .fill(
                    RadialGradient(
                        colors: [.white.opacity(0.25), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 120
                    )
                )
                .frame(width: 260, height: 260)
                .scaleEffect(phase == .preEntry ? 0.6 : 1)
                .opacity(phase == .preEntry ? 0 : 1)

            Circle()
                .strokeBorder(.white.opacity(0.25), lineWidth: 1.5)
                .frame(width: 180, height: 180)
                .scaleEffect(phase == .preEntry ? 0.85 : 1)
                .opacity(phase == .preEntry ? 0 : 0.9)

            Image(systemName: theme.icon)
                .font(.system(size: 84, weight: .light))
                .foregroundStyle(.white)
                .symbolEffect(.pulse.byLayer, options: .repeating)
                .symbolEffect(.bounce, value: phase == .settled)
                .scaleEffect(phase == .preEntry ? 0.7 : (phase == .midEntry ? 1.05 : theme.heroPulse))
                .shadow(color: .black.opacity(0.2), radius: 12, y: 6)
        }
        .frame(height: 220)
    }

    // MARK: - Highlights

    private func highlightRow(_ text: String, index: Int) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.body)
                .foregroundStyle(.white)
                .background(
                    Circle()
                        .fill(.white.opacity(0.15))
                        .frame(width: 32, height: 32)
                )
                .frame(width: 32, height: 32)

            Text(text)
                .font(.callout)
                .foregroundStyle(.white.opacity(0.92))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .opacity(phase == .settled ? 1 : 0)
        .offset(y: phase == .settled ? 0 : 12)
        .animation(
            .spring(response: 0.55, dampingFraction: 0.85).delay(0.05 * Double(index)),
            value: phase
        )
    }

    // MARK: - Animation driver

    private func runEntranceAnimation() {
        phase = .preEntry
        withAnimation(.spring(response: 0.7, dampingFraction: 0.78)) {
            phase = .midEntry
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.85)) {
                phase = .settled
            }
        }
    }
}
