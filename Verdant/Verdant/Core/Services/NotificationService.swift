//
//  NotificationService.swift
//  Verdant
//
//  Created by Abrar Hamim on 5/18/26.
//
//  Day 29-30 — wraps UNUserNotificationCenter for CareReminder scheduling.
//  Permission is requested lazily at the first plant save, not on app launch,
//  so users see the prompt in context (they've just saved a plant they
//  actually want to be reminded about).

import Foundation
import UserNotifications
import os

actor NotificationService {
    static let shared = NotificationService()

    private let center = UNUserNotificationCenter.current()

    enum AuthorizationState: Sendable {
        case notDetermined
        case granted
        case denied
        case provisional
    }

    // MARK: - Permission

    func authorizationState() async -> AuthorizationState {
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .notDetermined: return .notDetermined
        case .denied: return .denied
        case .authorized, .ephemeral: return .granted
        case .provisional: return .provisional
        @unknown default: return .notDetermined
        }
    }

    /// Asks the system prompt once. Subsequent calls return current state
    /// without re-prompting (iOS only allows the prompt to fire once).
    @discardableResult
    func requestAuthorizationIfNeeded() async -> AuthorizationState {
        let current = await authorizationState()
        guard current == .notDetermined else { return current }

        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            Logger.notifications.info("Permission prompt result: \(granted ? "granted" : "denied", privacy: .public)")
            return granted ? .granted : .denied
        } catch {
            Logger.notifications.error("requestAuthorization failed: \(error.localizedDescription, privacy: .public)")
            return .denied
        }
    }

    // MARK: - Schedule

    /// Schedules a local notification for the reminder's `nextDue`. Replaces
    /// any pending request already keyed to the same reminder ID, so callers
    /// can re-schedule freely after a completion / backdate / frequency edit.
    func schedule(reminderID: UUID, type: String, plantName: String, nextDue: Date, isEnabled: Bool) async {
        // Always clear the old request first — keeps the pending queue in
        // sync with the model when isEnabled flips off or the date moves.
        await cancel(reminderID: reminderID)

        guard isEnabled else { return }

        let state = await authorizationState()
        guard state == .granted || state == .provisional else {
            Logger.notifications.debug("Skip schedule for \(type, privacy: .public) — auth not granted")
            return
        }

        let content = UNMutableNotificationContent()
        content.title = Self.notificationTitle(for: type, plantName: plantName)
        content.body = Self.notificationBody(for: type)
        content.sound = .default
        content.userInfo = [
            "reminderID": reminderID.uuidString,
            "type": type
        ]

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Self.triggerComponents(for: nextDue),
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: reminderID.uuidString,
            content: content,
            trigger: trigger
        )

        do {
            try await center.add(request)
            Logger.notifications.info("Scheduled \(type, privacy: .public) for \(plantName, privacy: .public)")
        } catch {
            Logger.notifications.error("Schedule failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    // MARK: - Cancel

    func cancel(reminderID: UUID) async {
        center.removePendingNotificationRequests(withIdentifiers: [reminderID.uuidString])
    }

    func cancel(reminderIDs: [UUID]) async {
        guard !reminderIDs.isEmpty else { return }
        let ids = reminderIDs.map(\.uuidString)
        center.removePendingNotificationRequests(withIdentifiers: ids)
        Logger.notifications.debug("Cancelled \(ids.count, privacy: .public) reminder(s)")
    }

    // MARK: - Debug

    func pendingCount() async -> Int {
        await center.pendingNotificationRequests().count
    }

    // MARK: - Content helpers

    private static func notificationTitle(for type: String, plantName: String) -> String {
        switch type {
        case "watering":    return String(localized: "Water \(plantName)")
        case "fertilizing": return String(localized: "Fertilize \(plantName)")
        case "pruning":     return String(localized: "Prune \(plantName)")
        case "misting":     return String(localized: "Mist \(plantName)")
        default:            return String(localized: "Check on \(plantName)")
        }
    }

    private static func notificationBody(for type: String) -> String {
        switch type {
        case "watering":    return String(localized: "Your plant is ready for water.")
        case "fertilizing": return String(localized: "Time for a feed — plants thrive on routine.")
        case "pruning":     return String(localized: "A quick trim keeps growth balanced.")
        case "misting":     return String(localized: "A light mist will boost humidity.")
        default:            return String(localized: "Check in with your plant today.")
        }
    }

    /// Snaps reminders to a reasonable hour. If the stored time is before 7 AM
    /// (e.g. seeded at midnight when Plant was created), bump to 9 AM so the
    /// user gets the alert during the day instead of overnight.
    private static func triggerComponents(for date: Date) -> DateComponents {
        var components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: date
        )
        if (components.hour ?? 0) < 7 {
            components.hour = 9
            components.minute = 0
        }
        return components
    }
}
