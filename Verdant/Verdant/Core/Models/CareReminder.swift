//
//  CareReminder.swift
//  Verdant
//
//  Created by Abrar Hamim on 5/17/26.
//

import Foundation
import SwiftData

@Model
final class CareReminder {
    var id: UUID = UUID()
    var type: String = "watering"
    var frequencyDays: Int = 7

    /// Sub-day frequency override. When set (1...23) it takes precedence over
    /// frequencyDays so plants that need watering multiple times a day (e.g.
    /// every 12 hours) are representable. Optional so existing data and
    /// daily-only reminders work unchanged.
    var frequencyHours: Int?

    var customFrequency: Bool = false
    var isEnabled: Bool = true
    var nextDue: Date = Date()
    var lastCompleted: Date?

    var notes: String?
    var amount: String?
    var preferredTime: Date?

    var completionHistory: [Date] = []
    var streak: Int = 0

    var plant: Plant?

    init(type: String, frequencyDays: Int) {
        self.type = type
        self.frequencyDays = frequencyDays
        self.nextDue = Calendar.current.date(
            byAdding: .day,
            value: frequencyDays,
            to: Date()
        ) ?? Date()
    }

    // MARK: - Effective interval (hours-first, days-fallback)

    /// Single source of truth for "how often" arithmetic. Returns the interval
    /// in hours. Sub-day reminders (frequencyHours set, in range 1...23) win;
    /// otherwise we fall back to frequencyDays * 24.
    var intervalHours: Int {
        if let hours = frequencyHours, hours > 0 {
            return hours
        }
        return max(1, frequencyDays) * 24
    }

    /// Streak grace window: gives the user a window of leeway proportional to
    /// the interval so a slightly-late tap still counts toward the streak.
    private var streakGraceHours: Int {
        // 2 days for daily+ intervals, 2 hours for sub-day. Keeps the same
        // "+2 day" forgiveness the previous code had for daily reminders.
        return intervalHours >= 24 ? intervalHours + 48 : intervalHours + 2
    }

    // MARK: - Mutations

    func markCompleted(at date: Date = Date()) {
        lastCompleted = date
        completionHistory.append(date)

        if let last = completionHistory.dropLast().last {
            let hoursSince = Calendar.current.dateComponents([.hour], from: last, to: date).hour ?? 0
            if hoursSince <= streakGraceHours {
                streak += 1
            } else {
                streak = 1
            }
        } else {
            streak = 1
        }

        nextDue = Calendar.current.date(byAdding: .hour, value: intervalHours, to: date) ?? Date()
    }

    func undoLastCompletion() {
        guard !completionHistory.isEmpty else { return }
        completionHistory.removeLast()
        lastCompleted = completionHistory.last
        streak = max(0, streak - 1)

        if let last = lastCompleted {
            nextDue = Calendar.current.date(byAdding: .hour, value: intervalHours, to: last) ?? Date()
        }
    }

    func backdate(to date: Date) {
        completionHistory.append(date)
        completionHistory.sort()
        lastCompleted = completionHistory.last

        nextDue = Calendar.current.date(byAdding: .hour, value: intervalHours, to: date) ?? Date()
    }

    /// User-driven frequency change in days. Clears any sub-day override so
    /// the daily cadence is the active interval again.
    func setCustomFrequency(_ days: Int) {
        customFrequency = true
        frequencyDays = days
        frequencyHours = nil

        let anchor = lastCompleted ?? Date()
        nextDue = Calendar.current.date(byAdding: .day, value: days, to: anchor) ?? Date()
    }

    /// User-driven sub-day frequency change. Clamped to 1...23; anything
    /// beyond should use setCustomFrequency(days:) instead.
    func setCustomFrequencyHours(_ hours: Int) {
        let clamped = max(1, min(23, hours))
        customFrequency = true
        frequencyHours = clamped
        // Keep frequencyDays at 1 so older daily-aware code that reads it
        // still gets a sane fallback when it ignores frequencyHours.
        frequencyDays = 1

        let anchor = lastCompleted ?? Date()
        nextDue = Calendar.current.date(byAdding: .hour, value: clamped, to: anchor) ?? Date()
    }

    // MARK: - Display helpers

    var isOverdue: Bool {
        nextDue < Date() && isEnabled
    }

    var daysUntilDue: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: nextDue).day ?? 0
    }

    /// "Every 12 hours" or "Every 7 days" for use in UI subtitles.
    var frequencyDescription: String {
        if let hours = frequencyHours, hours > 0 {
            if hours == 1 { return "every hour" }
            return "every \(hours) hours"
        }
        if frequencyDays == 1 { return "every day" }
        return "every \(frequencyDays) days"
    }
}
