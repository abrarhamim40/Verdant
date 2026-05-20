//
//  MockAdGateway.swift
//  Verdant
//
//  Created by Abrar Hamim on 5/20/26.
//
//  Development stand-in for the real AdMob-backed gateway. Simulates a 2-ad
//  watch with a configurable delay so the UI can be exercised before AdMob
//  is integrated (Week 6, requires paid Apple Developer + AdMob account).
//
//  Production code constructs MockAdGateway in DEBUG builds; the real
//  GADRewardedAdGateway replaces it once the AdMob SDK is wired up.

import Foundation

@MainActor
final class MockAdGateway: AdGateway {
    /// Total fake delay across the simulated ad pair. Production rewarded
    /// ads are ~15-30 s each so 4 s by default makes the loading state
    /// visible without slowing dev iteration. Tests should pass a tiny
    /// value (e.g. `.milliseconds(10)`) so they finish fast.
    var simulatedTotalDelay: Duration

    /// Flip to `false` to exercise the failure path (user closed early,
    /// network dropped, ad-load timeout, etc.).
    var simulatedSuccess: Bool

    init(simulatedTotalDelay: Duration = .seconds(4), simulatedSuccess: Bool = true) {
        self.simulatedTotalDelay = simulatedTotalDelay
        self.simulatedSuccess = simulatedSuccess
    }

    func presentDoubleAdWall() async -> Bool {
        do {
            try await Task.sleep(for: simulatedTotalDelay)
        } catch {
            // Cancellation mid-watch — treat as a failed completion.
            return false
        }
        return simulatedSuccess
    }
}
