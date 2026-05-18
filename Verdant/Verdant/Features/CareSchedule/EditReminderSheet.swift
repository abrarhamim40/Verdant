//
//  EditReminderSheet.swift
//  Verdant
//
//  Created by Abrar Hamim on 5/19/26.
//
//  Day 33 — manual care override. Verdant's honest pitch is that the user
//  knows their climate and home better than any AI default — this sheet lets
//  them adjust frequency, time, notes, enable/disable, or delete a reminder.
//  Reschedules the notification on save so the next alert lines up.

import SwiftUI
import SwiftData
import os

struct EditReminderSheet: View {
    @Bindable var reminder: CareReminder

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var unit: FrequencyUnit
    @State private var frequencyValue: Int
    @State private var notes: String
    @State private var amount: String
    @State private var preferredTime: Date
    @State private var isEnabled: Bool
    @State private var showDeleteConfirm = false
    @State private var errorMessage: String?

    // Day 34 — undo + backdate state. Default backdate to "yesterday at the
    // preferred time" so the most common path (forgot to mark yesterday) is
    // one tap away.
    @State private var backdateDate: Date = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()

    /// iOS denial — if the user toggles "Enabled" on but system permission is off,
    /// notifications still won't fire. We show a footer hint in that case.
    @State private var systemAuthState: NotificationService.AuthorizationState = .notDetermined

    /// Days vs hours selector. Mirrors AddReminderSheet so the same picker is
    /// available when retroactively switching a daily reminder to hourly.
    enum FrequencyUnit: String, CaseIterable, Identifiable {
        case days, hours
        var id: Self { self }
        var label: String { self == .days ? "Days" : "Hours" }
        var range: ClosedRange<Int> { self == .days ? 1...365 : 1...23 }
        func valueLabel(_ value: Int) -> String {
            switch self {
            case .days:  return "\(value) \(value == 1 ? "day" : "days")"
            case .hours: return "\(value) \(value == 1 ? "hour" : "hours")"
            }
        }
    }

    init(reminder: CareReminder) {
        self.reminder = reminder
        // Reflect the current state: if frequencyHours is set, start in Hours mode.
        if let hours = reminder.frequencyHours, hours > 0 {
            _unit = State(initialValue: .hours)
            _frequencyValue = State(initialValue: hours)
        } else {
            _unit = State(initialValue: .days)
            _frequencyValue = State(initialValue: reminder.frequencyDays)
        }
        _notes = State(initialValue: reminder.notes ?? "")
        _amount = State(initialValue: reminder.amount ?? "")
        _preferredTime = State(initialValue: reminder.preferredTime ?? Self.defaultMorning())
        _isEnabled = State(initialValue: reminder.isEnabled)
    }

    var body: some View {
        NavigationStack {
            Form {
                summarySection
                frequencySection
                detailsSection
                statusSection
                historySection
                dangerSection
            }
            .navigationTitle(reminder.plant?.displayName ?? "Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }
                        .bold()
                        .disabled(frequencyValue < 1)
                }
            }
            .task {
                systemAuthState = await NotificationService.shared.authorizationState()
            }
            .alert("Couldn't save", isPresented: errorBinding) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
            .confirmationDialog(
                "Delete this reminder?",
                isPresented: $showDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) { delete() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("You can re-add it later from the plant's detail screen.")
            }
        }
    }

    // MARK: - Sections

    private var summarySection: some View {
        Section {
            LabeledContent("Type", value: typeLabel)
            if reminder.customFrequency {
                LabeledContent {
                    Label("Custom", systemImage: "slider.horizontal.3")
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(Color.terracotta)
                } label: {
                    Text("Source")
                }
            } else {
                LabeledContent("Source", value: "Suggested")
            }
        }
    }

    private var frequencySection: some View {
        Section {
            Picker("Unit", selection: $unit) {
                ForEach(FrequencyUnit.allCases) { u in
                    Text(u.label).tag(u)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: unit) { _, newUnit in
                // Clamp the stepper into the new unit's range when switching.
                frequencyValue = min(max(frequencyValue, newUnit.range.lowerBound), newUnit.range.upperBound)
            }

            Stepper(value: $frequencyValue, in: unit.range) {
                HStack {
                    Text("Every")
                    Text(unit.valueLabel(frequencyValue))
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color.forestGreen)
                }
            }
        } header: {
            Text("How often")
        } footer: {
            Text("Hours = sub-day cadence (every 12 hours). Days = once-a-day or longer.")
        }
    }

    private var detailsSection: some View {
        Section {
            TextField("e.g. 1 cup, top inch dry", text: $amount, axis: .vertical)
                .lineLimit(1...2)
            TextField("Notes (optional)", text: $notes, axis: .vertical)
                .lineLimit(1...4)
            DatePicker("Preferred time", selection: $preferredTime, displayedComponents: .hourAndMinute)
        } header: {
            Text("Details")
        } footer: {
            Text("Notifications fire at your preferred time on the due date.")
        }
    }

    private var statusSection: some View {
        Section {
            Toggle(isOn: $isEnabled) {
                Label("Enabled", systemImage: isEnabled ? "bell.fill" : "bell.slash")
            }
            if let lastCompleted = reminder.lastCompleted {
                LabeledContent("Last completed") {
                    Text(lastCompleted, format: .relative(presentation: .named))
                        .foregroundStyle(.secondary)
                }
            }
            if reminder.streak >= 2 {
                LabeledContent("Streak") {
                    Label("\(reminder.streak)", systemImage: "flame.fill")
                        .foregroundStyle(Color.terracotta)
                }
            }
        } footer: {
            if isEnabled && systemAuthState == .denied {
                Text("Notifications are disabled for Verdant in iOS Settings. Enable them there to actually receive these alerts.")
                    .foregroundStyle(Color.terracotta)
            }
        }
    }

    // MARK: - History (Day 34: undo + backdate)

    @ViewBuilder
    private var historySection: some View {
        Section {
            DatePicker(
                "Log a past completion",
                selection: $backdateDate,
                in: ...Date(),
                displayedComponents: .date
            )
            Button {
                logBackdate()
            } label: {
                Label("Mark done at this date", systemImage: "calendar.badge.checkmark")
            }
            .disabled(backdateDate > Date())

            if !reminder.completionHistory.isEmpty {
                Button(role: .destructive) {
                    undoLast()
                } label: {
                    Label("Undo last completion", systemImage: "arrow.uturn.backward")
                }
            }

            ForEach(recentCompletions, id: \.self) { date in
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.forestGreen)
                    Text(date, format: .dateTime.day().month(.abbreviated).year())
                        .font(.subheadline)
                    Spacer()
                    Text(date, format: .relative(presentation: .named))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("History")
        } footer: {
            if reminder.completionHistory.isEmpty {
                Text("Forgot to log something? Pick a past date and tap \"Mark done at this date\". Tapped ✓ by mistake? Use \"Undo last completion\".")
            } else {
                Text("Most recent first. Backdating updates streak; undo removes the last completion.")
            }
        }
    }

    private var recentCompletions: [Date] {
        Array(reminder.completionHistory.reversed().prefix(5))
    }

    private var dangerSection: some View {
        Section {
            Button(role: .destructive) {
                Haptics.warning()
                showDeleteConfirm = true
            } label: {
                Label("Delete reminder", systemImage: "trash")
            }
        }
    }

    // MARK: - Helpers

    private var typeLabel: String {
        switch reminder.type {
        case "watering":    return "Water"
        case "fertilizing": return "Fertilize"
        case "pruning":     return "Prune"
        case "misting":     return "Mist"
        default:            return reminder.type.capitalized
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )
    }

    private static func defaultMorning() -> Date {
        var components = DateComponents()
        components.hour = 9
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }

    // MARK: - Save

    private func save() {
        // Compare against the reminder's current effective unit so we only
        // reschedule when the user actually changed the cadence.
        let currentlyHours = (reminder.frequencyHours ?? 0) > 0
        let willBeHours = unit == .hours
        let unitChanged = currentlyHours != willBeHours
        let valueChanged: Bool = {
            if willBeHours {
                return frequencyValue != (reminder.frequencyHours ?? 0)
            } else {
                return frequencyValue != reminder.frequencyDays
            }
        }()
        let frequencyChanged = unitChanged || valueChanged
        let enabledChanged = isEnabled != reminder.isEnabled
        let preferredTimeChanged = !Self.sameMinute(reminder.preferredTime, preferredTime)

        reminder.notes = notes.trimmingCharacters(in: .whitespaces).isEmpty ? nil : notes
        reminder.amount = amount.trimmingCharacters(in: .whitespaces).isEmpty ? nil : amount
        reminder.preferredTime = preferredTime
        reminder.isEnabled = isEnabled

        if frequencyChanged {
            // Re-anchors nextDue inside the model + flips customFrequency on.
            switch unit {
            case .days:
                reminder.setCustomFrequency(frequencyValue)
            case .hours:
                reminder.setCustomFrequencyHours(frequencyValue)
            }
        }

        // Shift the existing nextDue's time-of-day to the new preferredTime
        // so the user immediately sees the change land on the reminder card
        // (and so the scheduled notification fires at the right hour:minute,
        // not at the original creation time-of-day).
        if preferredTimeChanged {
            let calendar = Calendar.current
            let time = calendar.dateComponents([.hour, .minute], from: preferredTime)
            var dateParts = calendar.dateComponents([.year, .month, .day], from: reminder.nextDue)
            dateParts.hour = time.hour
            dateParts.minute = time.minute
            if let updated = calendar.date(from: dateParts) {
                reminder.nextDue = updated
            }
        }

        // Snapshot for the Task — reminder access has to stay on the main actor.
        let reminderID = reminder.id
        let type = reminder.type
        let plantName = reminder.plant?.displayName ?? "Plant"
        let nextDue = reminder.nextDue
        let chosenTime = reminder.preferredTime
        let enabled = reminder.isEnabled

        do {
            try modelContext.save()
            Haptics.success()
            Logger.data.info("Edited reminder \(type, privacy: .public) for \(plantName, privacy: .public)")
        } catch {
            Logger.data.error("Reminder save failed: \(error.localizedDescription, privacy: .public)")
            Haptics.error()
            errorMessage = "Couldn't save right now. Try again."
            return
        }

        // Reschedule whenever frequency, enabled, or preferred time changed.
        if frequencyChanged || enabledChanged || preferredTimeChanged {
            Task {
                await NotificationService.shared.schedule(
                    reminderID: reminderID,
                    type: type,
                    plantName: plantName,
                    nextDue: nextDue,
                    preferredTime: chosenTime,
                    isEnabled: enabled
                )
            }
        }

        dismiss()
    }

    /// Compare two Date? values down to hour:minute resolution so we don't
    /// reschedule on imperceptible DatePicker drift.
    private static func sameMinute(_ a: Date?, _ b: Date?) -> Bool {
        guard let a, let b else { return a == nil && b == nil }
        let calendar = Calendar.current
        let ca = calendar.dateComponents([.hour, .minute], from: a)
        let cb = calendar.dateComponents([.hour, .minute], from: b)
        return ca.hour == cb.hour && ca.minute == cb.minute
    }

    // MARK: - Undo + backdate (Day 34)

    private func undoLast() {
        guard !reminder.completionHistory.isEmpty else { return }
        Haptics.warning()
        reminder.undoLastCompletion()
        persistAndReschedule(label: "undo")
    }

    private func logBackdate() {
        // Snap to noon on the picked day so it sorts cleanly and the
        // notification recalc lands on a sensible hour.
        var components = Calendar.current.dateComponents([.year, .month, .day], from: backdateDate)
        components.hour = 12
        let snapped = Calendar.current.date(from: components) ?? backdateDate

        Haptics.success()
        reminder.backdate(to: snapped)
        persistAndReschedule(label: "backdate")
    }

    private func persistAndReschedule(label: String) {
        let reminderID = reminder.id
        let type = reminder.type
        let plantName = reminder.plant?.displayName ?? "Plant"
        let nextDue = reminder.nextDue
        let chosenTime = reminder.preferredTime
        let isEnabled = reminder.isEnabled

        do {
            try modelContext.save()
            Logger.data.info("\(label, privacy: .public) \(type, privacy: .public) for \(plantName, privacy: .public)")
        } catch {
            Logger.data.error("\(label, privacy: .public) save failed: \(error.localizedDescription, privacy: .public)")
            Haptics.error()
            errorMessage = "Couldn't update right now. Try again."
            return
        }

        Task {
            await NotificationService.shared.schedule(
                reminderID: reminderID,
                type: type,
                plantName: plantName,
                nextDue: nextDue,
                preferredTime: chosenTime,
                isEnabled: isEnabled
            )
        }
    }

    // MARK: - Delete

    private func delete() {
        let reminderID = reminder.id
        let type = reminder.type

        modelContext.delete(reminder)

        do {
            try modelContext.save()
            Haptics.success()
            Logger.data.info("Deleted reminder \(type, privacy: .public)")
        } catch {
            Logger.data.error("Reminder delete failed: \(error.localizedDescription, privacy: .public)")
            Haptics.error()
            errorMessage = "Couldn't delete right now. Try again."
            return
        }

        Task {
            await NotificationService.shared.cancel(reminderID: reminderID)
        }

        dismiss()
    }
}
