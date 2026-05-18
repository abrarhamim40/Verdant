//
//  OnboardingView.swift
//  Verdant
//
//  Created by Abrar Hamim on 5/19/26.
//
//  4-page first-launch flow that introduces Verdant's honest-plant-app pitch.
//  Each page sets its own gradient theme; the background morphs smoothly when
//  the user swipes between pages so the whole flow feels like one continuous
//  scene rather than 4 disconnected screens. Completes via @AppStorage so the
//  flag survives launches and only the very first install sees it.

import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentPage: Int = 0

    private let pages: [OnboardingPage.Theme] = [
        .init(
            title: "Verdant",
            subtitle: "The honest plant app",
            body: "Built from a thousand angry reviews of competitors that overpromise. We show our confidence — even when it's low.",
            icon: "leaf.fill",
            highlights: [],
            topTint: Color(red: 0.10, green: 0.30, blue: 0.22),
            bottomTint: Color(red: 0.32, green: 0.55, blue: 0.42),
            heroPulse: 1.0
        ),
        .init(
            title: "Identify any plant",
            subtitle: "Plant.id + Apple Vision + Gemini",
            body: "Three models in a row so you get a real answer, with the percent confidence visible — not buried.",
            icon: "viewfinder",
            highlights: [
                "Species + common names + Wikipedia link",
                "Multi-photo scans for better accuracy",
                "Alternative matches when confidence is low"
            ],
            topTint: Color(red: 0.13, green: 0.32, blue: 0.28),
            bottomTint: Color(red: 0.40, green: 0.62, blue: 0.50),
            heroPulse: 1.05
        ),
        .init(
            title: "Spot problems early",
            subtitle: "Disease detection with hedging",
            body: "Plant.id's health model + a treatment plan from Gemini. If nothing's detected, we say so — we don't pretend a plant is fine.",
            icon: "cross.case.fill",
            highlights: [
                "Cause + symptoms + chemical + biological",
                "Severity badge: monitor, needs care, urgent",
                "Sources cited so you can verify yourself"
            ],
            topTint: Color(red: 0.32, green: 0.20, blue: 0.18),
            bottomTint: Color(red: 0.84, green: 0.55, blue: 0.27),
            heroPulse: 1.03
        ),
        .init(
            title: "Care your way",
            subtitle: "AI suggests. You decide.",
            body: "Override every default. Your climate, your hours, your call. Undo if you tap by mistake. Backdate if you forgot to log it.",
            icon: "drop.fill",
            highlights: [
                "Daily or every N hours — your call",
                "Mark complete with one tap, undo if needed",
                "Notifications fire at your preferred time"
            ],
            topTint: Color(red: 0.18, green: 0.35, blue: 0.30),
            bottomTint: Color(red: 0.46, green: 0.68, blue: 0.58),
            heroPulse: 1.02
        )
    ]

    var body: some View {
        ZStack {
            backgroundGradient
                .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                pageContent
                bottomControls
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        let theme = pages[currentPage]
        return LinearGradient(
            colors: [theme.topTint, theme.bottomTint],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .animation(.easeInOut(duration: 0.55), value: currentPage)
        .overlay {
            // Subtle vignette so the centered content always has a darker
            // backdrop than the corners.
            RadialGradient(
                colors: [.clear, .black.opacity(0.25)],
                center: .center,
                startRadius: 180,
                endRadius: 480
            )
            .ignoresSafeArea()
        }
    }

    // MARK: - Top bar (skip)

    private var topBar: some View {
        HStack {
            Spacer()
            if currentPage < pages.count - 1 {
                Button {
                    Haptics.selection()
                    finishOnboarding()
                } label: {
                    Text("Skip")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.7))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(.white.opacity(0.12))
                        .clipShape(Capsule())
                }
                .transition(.opacity)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .frame(height: 44)
    }

    // MARK: - Pages

    private var pageContent: some View {
        TabView(selection: $currentPage) {
            ForEach(Array(pages.enumerated()), id: \.offset) { index, theme in
                OnboardingPage(theme: theme)
                    .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(maxHeight: .infinity)
    }

    // MARK: - Bottom controls

    private var bottomControls: some View {
        VStack(spacing: 20) {
            pageIndicator
            primaryButton
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 32)
    }

    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<pages.count, id: \.self) { index in
                Capsule()
                    .fill(.white)
                    .frame(width: index == currentPage ? 28 : 8, height: 8)
                    .opacity(index == currentPage ? 1 : 0.4)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: currentPage)
            }
        }
    }

    private var primaryButton: some View {
        Button {
            Haptics.impact(.medium)
            advance()
        } label: {
            HStack(spacing: 8) {
                Text(primaryButtonLabel)
                    .font(.headline)
                Image(systemName: isLastPage ? "checkmark" : "arrow.right")
                    .font(.subheadline.weight(.bold))
            }
            .foregroundStyle(.black.opacity(0.85))
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: .black.opacity(0.15), radius: 12, y: 4)
        }
        .buttonStyle(.plain)
    }

    private var primaryButtonLabel: String {
        if isLastPage { return "Start" }
        if currentPage == 0 { return "Get started" }
        return "Continue"
    }

    private var isLastPage: Bool { currentPage == pages.count - 1 }

    // MARK: - Logic

    private func advance() {
        if isLastPage {
            finishOnboarding()
            return
        }
        withAnimation(.spring(response: 0.55, dampingFraction: 0.85)) {
            currentPage += 1
        }
    }

    private func finishOnboarding() {
        Haptics.success()
        withAnimation(.easeInOut(duration: 0.3)) {
            hasCompletedOnboarding = true
        }
    }
}
