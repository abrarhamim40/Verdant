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

    func markCompleted(at date: Date = Date()) {
        lastCompleted = date
        completionHistory.append(date)

        if let last = completionHistory.dropLast().last {
            let daysSince = Calendar.current.dateComponents([.day], from: last, to: date).day ?? 0
            if daysSince <= frequencyDays + 2 {
                streak += 1
            } else {
                streak = 1
            }
        } else {
            streak = 1
        }

        nextDue = Calendar.current.date(
            byAdding: .day,
            value: frequencyDays,
            to: date
        ) ?? Date()
    }

    func undoLastCompletion() {
        guard !completionHistory.isEmpty else { return }
        completionHistory.removeLast()
        lastCompleted = completionHistory.last
        streak = max(0, streak - 1)

        if let last = lastCompleted {
            nextDue = Calendar.current.date(
                byAdding: .day,
                value: frequencyDays,
                to: last
            ) ?? Date()
        }
    }

    func backdate(to date: Date) {
        completionHistory.append(date)
        completionHistory.sort()
        lastCompleted = completionHistory.last

        nextDue = Calendar.current.date(
            byAdding: .day,
            value: frequencyDays,
            to: date
        ) ?? Date()
    }

    func setCustomFrequency(_ days: Int) {
        customFrequency = true
        frequencyDays = days

        if let last = lastCompleted {
            nextDue = Calendar.current.date(byAdding: .day, value: days, to: last) ?? Date()
        }
    }

    var isOverdue: Bool {
        nextDue < Date() && isEnabled
    }

    var daysUntilDue: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: nextDue).day ?? 0
    }
}
