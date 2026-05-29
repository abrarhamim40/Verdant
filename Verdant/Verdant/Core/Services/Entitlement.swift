//
//  Entitlement.swift
//  Verdant
//
//  Created by Abrar Hamim on 5/20/26.
//
//  Source of truth for what a user is allowed to scan. Combines a
//  RevenueCat-driven isPremium flag with locally-tracked free-tier counters:
//    • 3 ad-free scans per calendar month
//    • a single-use ad-unlock token earned via the Double-Ad Wall
//    • a weekly cap of 2 ad-unlocked scans (post-pivot 2026-05-26 ad model)
//  Scan gate consults this before any paid API call.
//  See .claude/plan/01-PLAN.md (pricing) and .claude/plan/03-DECISIONS.md #5.

import Foundation
import Combine

@MainActor
final class Entitlement: ObservableObject {

    /// Result of the gate check.
    enum Permission: Equatable {
        case allowed                          // premium, free quota, or valid ad-unlock
        case requiresAds(remainingFree: Int)  // user must watch the Double-Ad Wall
        case weeklyCapReached                 // free quota empty + already used N ad-unlocks this week
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
    @Published private(set) var adUnlockedScansThisWeek: Int {
        didSet { defaults.set(adUnlockedScansThisWeek, forKey: Keys.adUnlockedScansWeek) }
    }

    /// Persisted as "yyyy-MM". Compared on every access; mismatch triggers monthly rollover.
    private var lastResetMonth: String {
        didSet { defaults.set(lastResetMonth, forKey: Keys.lastResetMonth) }
    }
    /// Persisted as "yyyy-Www" (ISO 8601 week). Mismatch triggers weekly rollover.
    private var lastResetWeek: String {
        didSet { defaults.set(lastResetWeek, forKey: Keys.lastResetWeek) }
    }

    let freeMonthlyQuota: Int
    let weeklyAdUnlockCap: Int

    // MARK: - Deps

    private let defaults: UserDefaults
    private let now: () -> Date

    static let shared = Entitlement()

    init(
        defaults: UserDefaults = .standard,
        freeMonthlyQuota: Int = 3,
        weeklyAdUnlockCap: Int = 2,
        now: @escaping () -> Date = { Date() }
    ) {
        self.defaults = defaults
        self.freeMonthlyQuota = freeMonthlyQuota
        self.weeklyAdUnlockCap = weeklyAdUnlockCap
        self.now = now
        self.isPremium = defaults.bool(forKey: Keys.isPremium)
        self.freeScansUsedThisMonth = defaults.integer(forKey: Keys.freeScansUsed)
        self.hasAdUnlock = defaults.bool(forKey: Keys.hasAdUnlock)
        self.adUnlockedScansThisWeek = defaults.integer(forKey: Keys.adUnlockedScansWeek)

        // didSet doesn't fire during init — if we fall back to "current month/week" without
        // also writing it to defaults, the next session's rollover check will compare today
        // against today. Persist explicitly when we synthesise a value.
        if let stored = defaults.string(forKey: Keys.lastResetMonth) {
            self.lastResetMonth = stored
        } else {
            let synthesised = Self.monthKey(for: now())
            self.lastResetMonth = synthesised
            defaults.set(synthesised, forKey: Keys.lastResetMonth)
        }
        if let stored = defaults.string(forKey: Keys.lastResetWeek) {
            self.lastResetWeek = stored
        } else {
            let synthesised = Self.weekKey(for: now())
            self.lastResetWeek = synthesised
            defaults.set(synthesised, forKey: Keys.lastResetWeek)
        }
        rolloverIfNeeded()
        weeklyRolloverIfNeeded()
    }

    // MARK: - Gate

    /// Read-only check — call right before starting an analysis or showing the gate UI.
    func currentPermission() -> Permission {
        rolloverIfNeeded()
        weeklyRolloverIfNeeded()
        if isPremium { return .allowed }
        if hasAdUnlock { return .allowed }
        if freeScansUsedThisMonth < freeMonthlyQuota { return .allowed }
        if adUnlockedScansThisWeek >= weeklyAdUnlockCap { return .weeklyCapReached }
        return .requiresAds(remainingFree: 0)
    }

    var remainingFreeScans: Int {
        if isPremium { return .max }
        return max(0, freeMonthlyQuota - freeScansUsedThisMonth)
    }

    var remainingAdUnlocksThisWeek: Int {
        if isPremium { return .max }
        return max(0, weeklyAdUnlockCap - adUnlockedScansThisWeek)
    }

    // MARK: - Transitions

    /// Call immediately after a successful AIService.analyzePlant completes.
    /// Premium users record nothing.
    /// Free users: consume the ad-unlock token first (the user paid 2 ads of attention for it),
    /// otherwise fall back to monthly quota. Consuming an ad-unlock also increments the
    /// weekly counter so the cap is enforced.
    func recordScanCompleted() {
        guard !isPremium else { return }
        if hasAdUnlock {
            hasAdUnlock = false
            adUnlockedScansThisWeek += 1
        } else if freeScansUsedThisMonth < freeMonthlyQuota {
            freeScansUsedThisMonth += 1
        }
    }

    /// Called by DoubleAdViewModel after both reward callbacks fire. Single-use token,
    /// cleared by the next recordScanCompleted(). Silently no-ops if the weekly cap
    /// is already reached — UI should consult currentPermission() *before* presenting
    /// the Double-Ad Wall, so this is a defence-in-depth check.
    func grantAdUnlock() {
        guard !isPremium else { return }
        weeklyRolloverIfNeeded()
        guard adUnlockedScansThisWeek < weeklyAdUnlockCap else { return }
        hasAdUnlock = true
    }

    /// RevenueCat callback hook — wire to the real subscription listener in Phase 4.
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

    private func weeklyRolloverIfNeeded() {
        let current = Self.weekKey(for: now())
        if current != lastResetWeek {
            adUnlockedScansThisWeek = 0
            lastResetWeek = current
        }
    }

    private static func monthKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: date)
    }

    /// ISO 8601 week key, e.g. "2026-W22". Weeks start Monday; this keeps the "wait until
    /// Monday" promise consistent globally without locale drift.
    private static func weekKey(for date: Date) -> String {
        var calendar = Calendar(identifier: .iso8601)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let comps = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        let year = comps.yearForWeekOfYear ?? 0
        let week = comps.weekOfYear ?? 0
        return String(format: "%04d-W%02d", year, week)
    }

    private enum Keys {
        static let isPremium = "verdant.entitlement.isPremium"
        static let freeScansUsed = "verdant.entitlement.freeScansUsedThisMonth"
        static let hasAdUnlock = "verdant.entitlement.hasAdUnlock"
        static let lastResetMonth = "verdant.entitlement.lastResetMonth"
        static let adUnlockedScansWeek = "verdant.entitlement.adUnlockedScansThisWeek"
        static let lastResetWeek = "verdant.entitlement.lastResetWeek"
    }

    #if DEBUG
    /// DEBUG-only helper for the in-app debug menu. Zeros the monthly + weekly counters
    /// and clears any ad-unlock token without waiting for rollover. Premium flag is
    /// untouched — use setPremium(_:) to toggle that separately.
    func _debugResetCounters() {
        freeScansUsedThisMonth = 0
        hasAdUnlock = false
        adUnlockedScansThisWeek = 0
    }

    /// DEBUG-only: max out the weekly ad-unlock cap to test the .weeklyCapReached state
    /// in the UI without watching real ads twice.
    func _debugMaxOutWeeklyCap() {
        adUnlockedScansThisWeek = weeklyAdUnlockCap
        hasAdUnlock = false
    }
    #endif
}
