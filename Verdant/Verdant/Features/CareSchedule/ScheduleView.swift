//
//  ScheduleView.swift
//  Verdant
//
//  Created by Abrar Hamim on 5/19/26.
//
//  Day 31-32 — central care schedule. Replaces the Home tab placeholder.
//  Groups every enabled CareReminder into Overdue / Today / This week / Later
//  buckets so the user sees the most urgent care at the top. Mark-done lives
//  on the ReminderCard itself.

import SwiftUI
import SwiftData

struct ScheduleView: View {
    @Query(
        filter: #Predicate<CareReminder> { reminder in reminder.isEnabled },
        sort: \CareReminder.nextDue
    ) private var reminders: [CareReminder]

    @Query private var plants: [Plant]

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
        }
    }

    // MARK: - Sections

    private var groupedReminders: [Section] {
        let now = Date()
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: now)
        let endOfToday = calendar.date(byAdding: .day, value: 1, to: startOfToday) ?? now
        let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfToday) ?? now

        var overdue: [CareReminder] = []
        var today: [CareReminder] = []
        var thisWeek: [CareReminder] = []
        var later: [CareReminder] = []

        for reminder in reminders {
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

    // MARK: - Schedule

    private var schedule: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                summaryHeader
                ForEach(groupedReminders) { section in
                    sectionView(section)
                }
            }
            .padding(20)
        }
    }

    private var summaryHeader: some View {
        let overdueCount = reminders.filter { $0.isOverdue }.count
        return VStack(alignment: .leading, spacing: 6) {
            Text(headlineForToday)
                .font(.system(.title2, design: .serif).weight(.semibold))
            if overdueCount > 0 {
                Text("\(overdueCount) overdue · take care of these first")
                    .font(.subheadline)
                    .foregroundStyle(Color.terracotta)
            } else {
                Text("\(plants.count) plant\(plants.count == 1 ? "" : "s") · \(reminders.count) reminder\(reminders.count == 1 ? "" : "s") on the schedule")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var headlineForToday: String {
        let date = Date().formatted(.dateTime.weekday(.wide).day().month(.wide))
        return date
    }

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
                }
            }
        }
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
