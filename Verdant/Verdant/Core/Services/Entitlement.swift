//
//  Entitlement.swift
//  Verdant
//
//  Created by Abrar Hamim on 5/20/26.
//
//  Source of truth for what a user is allowed to scan. Combines a
//  RevenueCat-driven isPremium flag with locally-tracked free-tier counters
//  (3 ad-free scans / calendar month, plus a single-use ad-unlock token earned
//  via the Double-Ad Wall). Scan gate consults this before any paid API call.
//  See .claude/launch-prep/10-production-blueprint.md §4 and §6.2.

import Foundation

@MainActor
final class Entitlement: ObservableObject {

    /// Result of the gate check.
    enum Permission: Equatable {
        case allowed                          // premium, free quota, or valid ad-unlock
        case requiresAds(remainingFree: Int)  // user must watch the Double-Ad Wall
    }

    // MARK: - State (persisted via UserDefaults)

    @Published private(set) var isPremium: Bool {
        didSet { defaults.set(isPremium, forKey: Keys.isPremium) }
    }
    @Published private(set) var freeScansUsedThisMonth: Int {
        didSet { defaults.set(freeScansUsedThisMonth, forKey: Keys.freeScansUsed) }
    }
    @Published private(set) var hasAdUnlock: Bool {
        didSet { defaults.set(hasAdUnlock, forKey: Keys.hasAdUnlock) }
    }

    /// Persisted as "yyyy-MM". Compared on every access; mismatch triggers rollover.
    private var lastResetMonth: String {
        didSet { defaults.set(lastResetMonth, forKey: Keys.lastResetMonth) }
    }

    let freeMonthlyQuota: Int

    // MARK: - Deps

    private let defaults: UserDefaults
    private let now: () -> Date

    static let shared = Entitlement()

    init(
        defaults: UserDefaults = .standard,
        freeMonthlyQuota: Int = 3,
        now: @escaping () -> Date = { Date() }
    ) {
        self.defaults = defaults
        self.freeMonthlyQuota = freeMonthlyQuota
        self.now = now
        self.isPremium = defaults.bool(forKey: Keys.isPremium)
        self.freeScansUsedThisMonth = defaults.integer(forKey: Keys.freeScansUsed)
        self.hasAdUnlock = defaults.bool(forKey: Keys.hasAdUnlock)
        self.lastResetMonth = defaults.string(forKey: Keys.lastResetMonth) ?? Self.monthKey(for: now())
        rolloverIfNeeded()
    }

    // MARK: - Gate

    /// Read-only check — call right before starting an analysis or showing the gate UI.
    func currentPermission() -> Permission {
        rolloverIfNeeded()
        if isPremium { return .allowed }
        if hasAdUnlock { return .allowed }
        if freeScansUsedThisMonth < freeMonthlyQuota { return .allowed }
        return .requiresAds(remainingFree: 0)
    }

    var remainingFreeScans: Int {
        if isPremium { return .max }
        return max(0, freeMonthlyQuota - freeScansUsedThisMonth)
    }

    // MARK: - Transitions

    /// Call immediately after a successful AIService.analyzePlant completes.
    /// Premium users record nothing.
    /// Free users: consume the ad-unlock token first (the user paid 2 ads of attention for it),
    /// otherwise fall back to monthly quota.
    func recordScanCompleted() {
        guard !isPremium else { return }
        if hasAdUnlock {
            hasAdUnlock = false
        } else if freeScansUsedThisMonth < freeMonthlyQuota {
            freeScansUsedThisMonth += 1
        }
    }

    /// Called by DoubleAdViewModel after both reward callbacks fire. Single-use token,
    /// cleared by the next recordScanCompleted().
    func grantAdUnlock() {
        guard !isPremium else { return }
        hasAdUnlock = true
    }

    /// RevenueCat callback hook — wire to the real subscription listener in Week 6.
    func setPremium(_ premium: Bool) {
        isPremium = premium
    }

    // MARK: - Internals

    private func rolloverIfNeeded() {
        let current = Self.monthKey(for: now())
        if current != lastResetMonth {
            freeScansUsedThisMonth = 0
            lastResetMonth = current
        }
    }

    private static func monthKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: date)
    }

    private enum Keys {
        static let isPremium = "verdant.entitlement.isPremium"
        static let freeScansUsed = "verdant.entitlement.freeScansUsedThisMonth"
        static let hasAdUnlock = "verdant.entitlement.hasAdUnlock"
        static let lastResetMonth = "verdant.entitlement.lastResetMonth"
    }
}
