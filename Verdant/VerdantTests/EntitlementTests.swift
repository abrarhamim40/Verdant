//
//  EntitlementTests.swift
//  VerdantTests
//
//  Created by Abrar Hamim on 5/20/26.
//

import Testing
import Foundation
@testable import Verdant

@MainActor
struct EntitlementTests {

    // MARK: - Helpers

    private func makeEntitlement(
        quota: Int = 3,
        date: Date = Date(timeIntervalSinceReferenceDate: 800_000_000) // arbitrary fixed point
    ) -> (Entitlement, UserDefaults) {
        let suite = "verdant.test.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        let entitlement = Entitlement(defaults: defaults, freeMonthlyQuota: quota, now: { date })
        return (entitlement, defaults)
    }

    // MARK: - Initial state

    @Test func freshDefaultsStartUnusedAndUnlocked() {
        let (ent, _) = makeEntitlement()
        #expect(ent.isPremium == false)
        #expect(ent.freeScansUsedThisMonth == 0)
        #expect(ent.hasAdUnlock == false)
        #expect(ent.remainingFreeScans == 3)
        #expect(ent.currentPermission() == .allowed)
    }

    // MARK: - Free quota consumption

    @Test func freeScansConsumeQuotaOneAtATime() {
        let (ent, _) = makeEntitlement()
        ent.recordScanCompleted()
        #expect(ent.freeScansUsedThisMonth == 1)
        #expect(ent.remainingFreeScans == 2)
        #expect(ent.currentPermission() == .allowed)

        ent.recordScanCompleted()
        #expect(ent.freeScansUsedThisMonth == 2)
        #expect(ent.remainingFreeScans == 1)
        #expect(ent.currentPermission() == .allowed)

        ent.recordScanCompleted()
        #expect(ent.freeScansUsedThisMonth == 3)
        #expect(ent.remainingFreeScans == 0)
        #expect(ent.currentPermission() == .requiresAds(remainingFree: 0))
    }

    @Test func quotaExhaustedRequiresAds() {
        let (ent, _) = makeEntitlement()
        for _ in 0..<3 { ent.recordScanCompleted() }
        #expect(ent.currentPermission() == .requiresAds(remainingFree: 0))
    }

    @Test func quotaCannotGoNegative() {
        let (ent, _) = makeEntitlement()
        for _ in 0..<10 { ent.recordScanCompleted() } // way more than quota
        #expect(ent.freeScansUsedThisMonth == 3)
        #expect(ent.remainingFreeScans == 0)
    }

    // MARK: - Ad-unlock token

    @Test func grantAdUnlockSetsToken() {
        let (ent, _) = makeEntitlement()
        for _ in 0..<3 { ent.recordScanCompleted() }
        #expect(ent.currentPermission() == .requiresAds(remainingFree: 0))

        ent.grantAdUnlock()
        #expect(ent.hasAdUnlock == true)
        #expect(ent.currentPermission() == .allowed)
    }

    @Test func adUnlockIsSingleUse() {
        let (ent, _) = makeEntitlement()
        for _ in 0..<3 { ent.recordScanCompleted() } // quota exhausted
        ent.grantAdUnlock()

        ent.recordScanCompleted() // consume token
        #expect(ent.hasAdUnlock == false)
        #expect(ent.freeScansUsedThisMonth == 3) // quota unchanged — token absorbed it
        #expect(ent.currentPermission() == .requiresAds(remainingFree: 0))
    }

    @Test func adUnlockConsumedBeforeFreeQuotaWhenBothPresent() {
        // Defensive: if both are somehow available, token goes first (more valuable to user).
        let (ent, _) = makeEntitlement()
        ent.grantAdUnlock()
        ent.recordScanCompleted()
        #expect(ent.hasAdUnlock == false)
        #expect(ent.freeScansUsedThisMonth == 0)
    }

    // MARK: - Premium

    @Test func premiumIsAlwaysAllowed() {
        let (ent, _) = makeEntitlement()
        ent.setPremium(true)

        for _ in 0..<100 { ent.recordScanCompleted() }
        #expect(ent.isPremium == true)
        #expect(ent.freeScansUsedThisMonth == 0) // counter untouched for premium
        #expect(ent.remainingFreeScans == .max)
        #expect(ent.currentPermission() == .allowed)
    }

    @Test func premiumIgnoresAdUnlock() {
        let (ent, _) = makeEntitlement()
        ent.setPremium(true)
        ent.grantAdUnlock()
        #expect(ent.hasAdUnlock == false) // ignored — premium doesn't accumulate ad tokens
    }

    @Test func downgradeFromPremiumPreservesCounters() {
        let (ent, _) = makeEntitlement()
        // Pre-premium scans
        ent.recordScanCompleted()
        ent.recordScanCompleted()

        // Become premium
        ent.setPremium(true)
        ent.recordScanCompleted() // no-op
        #expect(ent.freeScansUsedThisMonth == 2)

        // Downgrade (subscription expired)
        ent.setPremium(false)
        #expect(ent.freeScansUsedThisMonth == 2) // counter preserved
        #expect(ent.remainingFreeScans == 1)
    }

    // MARK: - Month rollover

    @Test func quotaResetsWhenMonthChanges() {
        // First month: exhaust quota
        let firstDate = Date(timeIntervalSinceReferenceDate: 800_000_000) // some point
        let suite = "verdant.test.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        let first = Entitlement(defaults: defaults, freeMonthlyQuota: 3, now: { firstDate })
        for _ in 0..<3 { first.recordScanCompleted() }
        #expect(first.freeScansUsedThisMonth == 3)

        // Next month — same UserDefaults, new clock function
        let nextMonth = Calendar(identifier: .gregorian).date(byAdding: .month, value: 1, to: firstDate)!
        let second = Entitlement(defaults: defaults, freeMonthlyQuota: 3, now: { nextMonth })
        #expect(second.freeScansUsedThisMonth == 0) // rolled over
        #expect(second.currentPermission() == .allowed)
        #expect(second.remainingFreeScans == 3)
    }

    @Test func quotaDoesNotResetWithinSameMonth() {
        let day1 = Date(timeIntervalSinceReferenceDate: 800_000_000)
        let day2 = day1.addingTimeInterval(60 * 60 * 24) // +1 day
        let suite = "verdant.test.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)

        let day1Ent = Entitlement(defaults: defaults, freeMonthlyQuota: 3, now: { day1 })
        day1Ent.recordScanCompleted()
        day1Ent.recordScanCompleted()

        let day2Ent = Entitlement(defaults: defaults, freeMonthlyQuota: 3, now: { day2 })
        #expect(day2Ent.freeScansUsedThisMonth == 2) // same month — counter preserved
    }

    // MARK: - Persistence

    @Test func stateSurvivesFreshInit() {
        let suite = "verdant.test.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        let date = Date(timeIntervalSinceReferenceDate: 800_000_000)

        do {
            let ent = Entitlement(defaults: defaults, freeMonthlyQuota: 3, now: { date })
            ent.recordScanCompleted()
            ent.grantAdUnlock()
            ent.setPremium(true)
        }

        let reloaded = Entitlement(defaults: defaults, freeMonthlyQuota: 3, now: { date })
        #expect(reloaded.isPremium == true)
        #expect(reloaded.freeScansUsedThisMonth == 1)
        #expect(reloaded.hasAdUnlock == true)
    }

    // MARK: - Weekly ad-unlock cap (post-pivot 2026-05-26 ad model)

    @Test func adUnlockConsumptionIncrementsWeeklyCounter() {
        let (ent, _) = makeEntitlement()
        for _ in 0..<3 { ent.recordScanCompleted() } // exhaust monthly quota
        #expect(ent.adUnlockedScansThisWeek == 0)

        ent.grantAdUnlock()
        ent.recordScanCompleted() // consumes the ad-unlock token
        #expect(ent.adUnlockedScansThisWeek == 1)
        #expect(ent.remainingAdUnlocksThisWeek == 1)

        ent.grantAdUnlock()
        ent.recordScanCompleted()
        #expect(ent.adUnlockedScansThisWeek == 2)
        #expect(ent.remainingAdUnlocksThisWeek == 0)
    }

    @Test func consumingFreeQuotaDoesNotIncrementWeeklyCounter() {
        // Sanity: only ad-unlocks count toward the weekly cap, not free scans.
        let (ent, _) = makeEntitlement()
        ent.recordScanCompleted()
        ent.recordScanCompleted()
        #expect(ent.adUnlockedScansThisWeek == 0)
    }

    @Test func weeklyCapReachedAfterTwoAdUnlocks() {
        let (ent, _) = makeEntitlement()
        for _ in 0..<3 { ent.recordScanCompleted() } // monthly quota gone
        ent.grantAdUnlock(); ent.recordScanCompleted()
        ent.grantAdUnlock(); ent.recordScanCompleted()

        #expect(ent.adUnlockedScansThisWeek == 2)
        #expect(ent.currentPermission() == .weeklyCapReached)
    }

    @Test func grantAdUnlockIsNoOpAtWeeklyCap() {
        let (ent, _) = makeEntitlement()
        for _ in 0..<3 { ent.recordScanCompleted() }
        ent.grantAdUnlock(); ent.recordScanCompleted()
        ent.grantAdUnlock(); ent.recordScanCompleted()
        // Already at cap. Even if the UI tried to present another ad wall and award a
        // token, Entitlement refuses it as defence-in-depth.

        ent.grantAdUnlock()
        #expect(ent.hasAdUnlock == false)
        #expect(ent.currentPermission() == .weeklyCapReached)
    }

    @Test func weeklyCounterResetsOnNewWeek() {
        // First week: exhaust quota + max out weekly ad-unlocks.
        let week1 = Date(timeIntervalSinceReferenceDate: 800_000_000)
        let suite = "verdant.test.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        let first = Entitlement(defaults: defaults, freeMonthlyQuota: 3, now: { week1 })
        for _ in 0..<3 { first.recordScanCompleted() }
        first.grantAdUnlock(); first.recordScanCompleted()
        first.grantAdUnlock(); first.recordScanCompleted()
        #expect(first.adUnlockedScansThisWeek == 2)
        #expect(first.currentPermission() == .weeklyCapReached)

        // Two weeks later — definitely a new ISO week. Same UserDefaults.
        let week3 = Calendar(identifier: .iso8601).date(byAdding: .weekOfYear, value: 2, to: week1)!
        let second = Entitlement(defaults: defaults, freeMonthlyQuota: 3, now: { week3 })
        #expect(second.adUnlockedScansThisWeek == 0)
        #expect(second.remainingAdUnlocksThisWeek == 2)
        // Monthly counter also rolled over because 2 weeks crossed a month boundary in
        // this fixed test date — that's fine, it's the realistic combination.
    }

    @Test func weeklyCapDoesNotResetWithinSameWeek() {
        let day1 = Date(timeIntervalSinceReferenceDate: 800_000_000)
        let day2 = day1.addingTimeInterval(60 * 60 * 24) // +1 day, same ISO week
        let suite = "verdant.test.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)

        let first = Entitlement(defaults: defaults, freeMonthlyQuota: 3, now: { day1 })
        for _ in 0..<3 { first.recordScanCompleted() }
        first.grantAdUnlock(); first.recordScanCompleted()
        #expect(first.adUnlockedScansThisWeek == 1)

        let second = Entitlement(defaults: defaults, freeMonthlyQuota: 3, now: { day2 })
        #expect(second.adUnlockedScansThisWeek == 1) // same week — counter preserved
    }

    @Test func premiumIgnoresWeeklyCap() {
        let (ent, _) = makeEntitlement()
        ent.setPremium(true)
        for _ in 0..<10 { ent.recordScanCompleted() }
        #expect(ent.adUnlockedScansThisWeek == 0) // premium recordScan is a no-op
        #expect(ent.remainingAdUnlocksThisWeek == .max)
        #expect(ent.currentPermission() == .allowed)
    }

    @Test func weeklyCapStatePersistsAcrossInit() {
        let suite = "verdant.test.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        let date = Date(timeIntervalSinceReferenceDate: 800_000_000)

        do {
            let ent = Entitlement(defaults: defaults, freeMonthlyQuota: 3, now: { date })
            for _ in 0..<3 { ent.recordScanCompleted() }
            ent.grantAdUnlock(); ent.recordScanCompleted()
        }

        let reloaded = Entitlement(defaults: defaults, freeMonthlyQuota: 3, now: { date })
        #expect(reloaded.adUnlockedScansThisWeek == 1)
        #expect(reloaded.remainingAdUnlocksThisWeek == 1)
    }
}
