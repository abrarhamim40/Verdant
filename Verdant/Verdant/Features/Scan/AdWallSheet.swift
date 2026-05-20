//
//  AdWallSheet.swift
//  Verdant
//
//  Created by Abrar Hamim on 5/20/26.
//
//  The blueprint §4 Double-Ad Wall as a SwiftUI sheet. Shown by ScanView when
//  Entitlement.currentPermission() returns .requiresAds. Drives the AdGateway
//  through three states (idle → watching → succeeded/failed) and resolves via
//  onUnlock / onCancel closures so the caller can chain the scan navigation.

import SwiftUI

struct AdWallSheet: View {
    let adGateway: AdGateway
    let onUnlock: () -> Void
    let onCancel: () -> Void

    @State private var state: WatchState = .idle

    enum WatchState: Equatable {
        case idle
        case watching
        case failed
    }

    var body: some View {
        VStack(spacing: 28) {
            header
            body(for: state)
            actions(for: state)
            Spacer(minLength: 0)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.backgroundPrimary.ignoresSafeArea())
        .interactiveDismissDisabled(state == .watching)
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Header (constant across states)

    private var header: some View {
        VStack(spacing: 12) {
            Image(systemName: "play.rectangle.fill")
                .font(.system(size: 56, weight: .regular))
                .foregroundStyle(Color.forestGreen)
                .padding(.top, 20)

            Text("Watch 2 ads to scan")
                .font(.title2.weight(.bold))
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Per-state copy

    @ViewBuilder
    private func body(for state: WatchState) -> some View {
        switch state {
        case .idle:
            Text("You've used your 3 free scans this month. Watch 2 short rewarded ads to unlock one more — instantly, no cooldown.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)

        case .watching:
            VStack(spacing: 16) {
                ProgressView()
                    .controlSize(.large)
                    .tint(Color.forestGreen)
                Text("Loading ads…")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

        case .failed:
            VStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title)
                    .foregroundStyle(Color.terracotta)
                Text("That didn't complete. Both ads need to finish for the scan to unlock.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    // MARK: - Buttons per state

    @ViewBuilder
    private func actions(for state: WatchState) -> some View {
        switch state {
        case .idle:
            VStack(spacing: 12) {
                primaryButton(label: "Watch ads", action: watchAds)
                secondaryButton(label: "Maybe later", action: cancel)
            }
        case .watching:
            EmptyView()
        case .failed:
            VStack(spacing: 12) {
                primaryButton(label: "Try again", action: watchAds)
                secondaryButton(label: "Cancel", action: cancel)
            }
        }
    }

    private func primaryButton(label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.body.weight(.semibold))
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color.forestGreen)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    private func secondaryButton(label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Actions

    private func watchAds() {
        Haptics.impact(.light)
        state = .watching
        Task {
            let granted = await adGateway.presentDoubleAdWall()
            if granted {
                Haptics.success()
                onUnlock()
            } else {
                Haptics.warning()
                withAnimation(.easeInOut(duration: 0.25)) { state = .failed }
            }
        }
    }

    private func cancel() {
        Haptics.selection()
        onCancel()
    }
}

#Preview("Idle") {
    Color.clear.sheet(isPresented: .constant(true)) {
        AdWallSheet(
            adGateway: MockAdGateway(simulatedTotalDelay: .seconds(2)),
            onUnlock: {},
            onCancel: {}
        )
    }
}
