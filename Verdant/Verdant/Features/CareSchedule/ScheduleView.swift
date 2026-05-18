//
//  ScheduleView.swift
//  Verdant
//
//  Created by Abrar Hamim on 5/19/26.
//
//  Day 31-32 — central care schedule. Replaces the Home tab placeholder.
//  Time-of-day greeting, today's progress bar, streak chip, Overdue / Today /
//  This week / Later buckets, and a Completed today section that catches
//  finished reminders so the user sees their accomplishment instead of the
//  card vanishing into a future bucket.

import SwiftUI
import SwiftData
import UIKit

struct ScheduleView: View {
    @Query(
        filter: #Predicate<CareReminder> { reminder in reminder.isEnabled },
        sort: \CareReminder.nextDue
    ) private var reminders: [CareReminder]

    @Query private var plants: [Plant]

    @State private var authState: NotificationService.AuthorizationState = .notDetermined
    @Environment(\.scenePhase) private var scenePhase

    private let calendar = Calendar.current

    var body: some View {
        NavigationStack {
            Group {
                if plants.isEmpty {
                    emptyState
                } else if reminders.isEmpty {
                    noRemindersState
                } else {
                    schedule
                }
            }
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.large)
            .background(Color.backgroundPrimary.ignoresSafeArea())
            .task { await refreshAuthState() }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    Task { await refreshAuthState() }
                }
            }
        }
    }

    private func refreshAuthState() async {
        authState = await NotificationService.shared.authorizationState()
    }

    // MARK: - Active / completed split

    /// "Completed today" means done for today, nothing more to do until
    /// tomorrow or later. A reminder rescheduled to fire again today (sub-day
    /// cadence, or user edited preferredTime to a later time today) belongs
    /// in active — there's still action coming up before midnight.
    private var activeReminders: [CareReminder] {
        let endOfToday = endOfToday()
        return reminders.filter { reminder in
            guard let last = reminder.lastCompleted else { return true }
            // Completed today AND next fire is tomorrow+ → not active.
            if calendar.isDateInToday(last) && reminder.nextDue >= endOfToday {
                return false
            }
            return true
        }
    }

    private var completedTodayReminders: [CareReminder] {
        let endOfToday = endOfToday()
        return reminders.filter { reminder in
            guard let last = reminder.lastCompleted else { return false }
            return calendar.isDateInToday(last) && reminder.nextDue >= endOfToday
        }
        .sorted { ($0.lastCompleted ?? .distantPast) > ($1.lastCompleted ?? .distantPast) }
    }

    private func endOfToday() -> Date {
        let startOfToday = calendar.startOfDay(for: Date())
        return calendar.date(byAdding: .day, value: 1, to: startOfToday) ?? startOfToday
    }

    private var dueTodayCount: Int {
        let startOfToday = calendar.startOfDay(for: Date())
        let endOfToday = calendar.date(byAdding: .day, value: 1, to: startOfToday) ?? Date()
        return activeReminders.filter { $0.nextDue < endOfToday }.count + completedTodayReminders.count
    }

    private var doneTodayCount: Int {
        completedTodayReminders.count
    }

    private var maxStreak: Int {
        reminders.map(\.streak).max() ?? 0
    }

    // MARK: - Bucketing

    private var groupedReminders: [Section] {
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)
        let endOfToday = calendar.date(byAdding: .day, value: 1, to: startOfToday) ?? now
        let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfToday) ?? now

        var overdue: [CareReminder] = []
        var today: [CareReminder] = []
        var thisWeek: [CareReminder] = []
        var later: [CareReminder] = []

        for reminder in activeReminders {
            if reminder.nextDue < startOfToday {
                overdue.append(reminder)
            } else if reminder.nextDue < endOfToday {
                today.append(reminder)
            } else if reminder.nextDue < endOfWeek {
                thisWeek.append(reminder)
            } else {
                later.append(reminder)
            }
        }

        var sections: [Section] = []
        if !overdue.isEmpty { sections.append(Section(kind: .overdue, items: overdue)) }
        if !today.isEmpty { sections.append(Section(kind: .today, items: today)) }
        if !thisWeek.isEmpty { sections.append(Section(kind: .thisWeek, items: thisWeek)) }
        if !later.isEmpty { sections.append(Section(kind: .later, items: later)) }
        return sections
    }

    // MARK: - Schedule body

    private var schedule: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if authState == .denied {
                    notificationsDeniedBanner
                }
                heroHeader
                ForEach(groupedReminders) { section in
                    sectionView(section)
                }
                if !completedTodayReminders.isEmpty {
                    completedTodaySection
                }
            }
            .padding(20)
            .animation(.easeInOut(duration: 0.25), value: completedTodayReminders.count)
        }
    }

    // MARK: - Hero header (greeting + progress + streak)

    private var heroHeader: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Image(systemName: timeOfDayIcon)
                            .font(.title3)
                            .foregroundStyle(Color.terracotta)
                        Text(greeting)
                            .font(.system(.title2, design: .serif).weight(.semibold))
                    }
                    Text(Date(), format: .dateTime.weekday(.wide).day().month(.wide))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if maxStreak >= 2 {
                    streakChip
                }
            }
            progressBlock
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCard(cornerRadius: 20)
    }

    private var greeting: String {
        let hour = calendar.component(.hour, from: Date())
        switch hour {
        case 4..<12:  return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default:      return "Late night"
        }
    }

    private var timeOfDayIcon: String {
        let hour = calendar.component(.hour, from: Date())
        switch hour {
        case 5..<12:  return "sunrise.fill"
        case 12..<17: return "sun.max.fill"
        case 17..<20: return "sun.horizon.fill"
        default:      return "moon.stars.fill"
        }
    }

    private var streakChip: some View {
        HStack(spacing: 4) {
            Image(systemName: "flame.fill")
                .font(.caption.weight(.bold))
            Text("\(maxStreak) streak")
                .font(.caption.weight(.semibold))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color.terracotta.opacity(0.15))
        .foregroundStyle(Color.terracotta)
        .clipShape(Capsule())
    }

    @ViewBuilder
    private var progressBlock: some View {
        if dueTodayCount > 0 {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline) {
                    Text("\(doneTodayCount) of \(dueTodayCount) done")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    if doneTodayCount == dueTodayCount {
                        Text("🌿 all caught up")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(Color.forestGreen)
                    } else {
                        Text("\(Int((Double(doneTodayCount) / Double(dueTodayCount)) * 100))%")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                }
                GeometryReader { proxy in
                    let progress = Double(doneTodayCount) / Double(dueTodayCount)
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.sage.opacity(0.25))
                        Capsule()
                            .fill(Color.forestGreen)
                            .frame(width: max(8, proxy.size.width * progress))
                            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: progress)
                    }
                }
                .frame(height: 10)
            }
        } else {
            HStack(spacing: 6) {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(Color.forestGreen)
                Text("No care due today — relax")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Sections

    private func sectionView(_ section: Section) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Label(section.kind.title, systemImage: section.kind.icon)
                    .font(.headline)
                    .foregroundStyle(section.kind.tint)
                Spacer()
                Text("\(section.items.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.sage.opacity(0.20))
                    .clipShape(Capsule())
            }
            VStack(spacing: 8) {
                ForEach(section.items) { reminder in
                    ReminderCard(reminder: reminder)
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.95).combined(with: .opacity),
                            removal: .opacity.combined(with: .move(edge: .trailing))
                        ))
                }
            }
        }
    }

    private var completedTodaySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Label("Completed today", systemImage: "checkmark.seal.fill")
                    .font(.headline)
                    .foregroundStyle(Color.forestGreen)
                Spacer()
                Text("\(completedTodayReminders.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.forestGreen)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.forestGreen.opacity(0.15))
                    .clipShape(Capsule())
            }
            VStack(spacing: 8) {
                ForEach(completedTodayReminders) { reminder in
                    CompletedReminderRow(reminder: reminder)
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.97).combined(with: .opacity),
                            removal: .opacity
                        ))
                }
            }
        }
    }

    // MARK: - Banner

    private var notificationsDeniedBanner: some View {
        Button {
            Haptics.selection()
            openAppSettings()
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "bell.slash.fill")
                    .font(.title3)
                    .foregroundStyle(Color.terracotta)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Notifications are off")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text("Reminders won't alert you. Tap to enable in Settings.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.terracotta.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    // MARK: - Empty states

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No plants yet", systemImage: "leaf")
        } description: {
            Text("Add or scan your first plant to start a care schedule.")
        }
    }

    private var noRemindersState: some View {
        ContentUnavailableView {
            Label("All caught up", systemImage: "checkmark.circle.fill")
        } description: {
            Text("Every reminder is paused. Re-enable one from a plant's detail screen to bring it back here.")
        }
    }
}

// MARK: - Completed row (slim card for accomplishments)

private struct CompletedReminderRow: View {
    let reminder: CareReminder

    @State private var showEditSheet = false

    var body: some View {
        Button {
            Haptics.selection()
            showEditSheet = true
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.forestGreen)
                        .frame(width: 36, height: 36)
                    Image(systemName: "checkmark")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(reminder.plant?.displayName ?? "Unknown plant")
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(1)
                        Text("·")
                            .foregroundStyle(.tertiary)
                        Text(typeLabel)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Text("Next: \(nextDueDescription)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                if let lastCompleted = reminder.lastCompleted {
                    Text(lastCompleted, format: .dateTime.hour().minute())
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accentCard(tint: .forestGreen, intensity: 0.10, cornerRadius: 14)
        }
        .buttonStyle(.pressable)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Double tap to edit, undo, or backdate this reminder.")
        .sheet(isPresented: $showEditSheet) {
            EditReminderSheet(reminder: reminder)
        }
    }

    private var typeLabel: String {
        switch reminder.type {
        case "watering":    return "Watered"
        case "fertilizing": return "Fertilized"
        case "pruning":     return "Pruned"
        case "misting":     return "Misted"
        default:            return reminder.type.capitalized
        }
    }

    /// Honest "Next" copy so the user can see exactly when the next fire is
    /// after editing preferredTime. Reads "tomorrow 9:00 AM" or "today 11:33
    /// PM" for near-term, "Mon May 25, 9:00 AM" for further out.
    private var nextDueDescription: String {
        let calendar = Calendar.current
        let nextDue = reminder.nextDue
        let timeString = nextDue.formatted(.dateTime.hour().minute())

        if calendar.isDateInToday(nextDue) {
            return "today \(timeString)"
        }
        if calendar.isDateInTomorrow(nextDue) {
            return "tomorrow \(timeString)"
        }
        let daysAway = calendar.dateComponents([.day], from: calendar.startOfDay(for: Date()), to: calendar.startOfDay(for: nextDue)).day ?? 0
        if daysAway < 7 {
            return "\(nextDue.formatted(.dateTime.weekday(.wide))) \(timeString)"
        }
        return "\(nextDue.formatted(.dateTime.day().month(.abbreviated))) \(timeString)"
    }
}

// MARK: - Section model

private struct Section: Identifiable {
    let kind: Kind
    let items: [CareReminder]
    var id: Kind { kind }

    enum Kind: String, CaseIterable, Identifiable {
        case overdue
        case today
        case thisWeek
        case later
        var id: Self { self }

        var title: String {
            switch self {
            case .overdue:  return "Overdue"
            case .today:    return "Today"
            case .thisWeek: return "This week"
            case .later:    return "Later"
            }
        }

        var icon: String {
            switch self {
            case .overdue:  return "exclamationmark.triangle.fill"
            case .today:    return "sun.max.fill"
            case .thisWeek: return "calendar"
            case .later:    return "moon.stars.fill"
            }
        }

        var tint: Color {
            switch self {
            case .overdue:  return Color.terracotta
            case .today:    return Color.forestGreen
            case .thisWeek: return Color.sage
            case .later:    return Color.sage
            }
        }
    }
}
