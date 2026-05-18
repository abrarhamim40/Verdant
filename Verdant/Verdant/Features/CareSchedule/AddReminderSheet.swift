//
//  AddReminderSheet.swift
//  Verdant
//
//  Created by Abrar Hamim on 5/19/26.
//
//  Recreates a deleted reminder OR adds a non-default one (pruning, misting)
//  to an existing plant. The Save flow auto-seeds watering + fertilizing on
//  Plant create, but anything beyond that has to flow through here so the
//  user isn't locked into the initial set.

import SwiftUI
import SwiftData
import os

struct AddReminderSheet: View {
    let plant: Plant

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var type: ReminderType = .watering
    @State private var unit: FrequencyUnit = .days
    @State private var frequencyValue: Int = 7
    @State private var notes: String = ""
    @State private var amount: String = ""
    @State private var preferredTime: Date = Self.defaultMorning()
    @State private var errorMessage: String?

    /// Days vs hours selector for sub-day reminders like "every 12 hours".
    enum FrequencyUnit: String, CaseIterable, Identifiable {
        case days, hours
        var id: Self { self }
        var label: String {
            switch self {
            case .days:  return "Days"
            case .hours: return "Hours"
            }
        }
        /// Stepper bounds per unit. Hours clamp at 23 — bigger goes through Days.
        var range: ClosedRange<Int> {
            switch self {
            case .days:  return 1...365
            case .hours: return 1...23
            }
        }
        func valueLabel(_ value: Int) -> String {
            switch self {
            case .days:  return "\(value) \(value == 1 ? "day" : "days")"
            case .hours: return "\(value) \(value == 1 ? "hour" : "hours")"
            }
        }
    }

    /// Picker-friendly type wrapper. The model stores `type` as a String, but
    /// SwiftUI Picker wants Hashable cases — and forcing the dev to pass raw
    /// strings makes wrong values too easy.
    enum ReminderType: String, CaseIterable, Identifiable {
        case watering, fertilizing, pruning, misting
        var id: Self { self }

        var label: String {
            switch self {
            case .watering:    return "Water"
            case .fertilizing: return "Fertilize"
            case .pruning:     return "Prune"
            case .misting:     return "Mist"
            }
        }

        var icon: String {
            switch self {
            case .watering:    return "drop.fill"
            case .fertilizing: return "sparkles"
            case .pruning:     return "scissors"
            case .misting:     return "humidity.fill"
            }
        }

        /// Sensible default cadence per care type — user can override on the stepper.
        var defaultDays: Int {
            switch self {
            case .watering:    return 7
            case .fertilizing: return 30
            case .pruning:     return 90
            case .misting:     return 3
            }
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                typeSection
                frequencySection
                detailsSection
            }
            .navigationTitle("Add reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") { save() }
                        .bold()
                        .disabled(frequencyValue < 1)
                }
            }
            .alert("Couldn't add", isPresented: errorBinding) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
            .onChange(of: type) { _, newType in
                // Reset the stepper to the new type's default whenever the
                // user switches between watering / pruning / etc. Defaults
                // are in days; switching to Hours keeps the same numeric value
                // but the unit picker handles the bounds via clamping below.
                unit = .days
                frequencyValue = newType.defaultDays
            }
            .onChange(of: unit) { _, newUnit in
                // Clamp the stepper value into the new unit's range when the
                // user flips Days <-> Hours.
                frequencyValue = min(max(frequencyValue, newUnit.range.lowerBound), newUnit.range.upperBound)
            }
        }
    }

    // MARK: - Sections

    private var typeSection: some View {
        Section {
            Picker("Care type", selection: $type) {
                ForEach(ReminderType.allCases) { reminderType in
                    Label(reminderType.label, systemImage: reminderType.icon)
                        .tag(reminderType)
                }
            }
            .pickerStyle(.menu)
        } header: {
            Text("What kind of care")
        } footer: {
            Text("Watering and fertilizing are auto-seeded when you save a plant. Add pruning and misting yourself — they're species-dependent.")
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
            if unit == .hours {
                Text("Use Hours for plants that need care multiple times a day, like seedlings or tropical mistings.")
            } else {
                Text("Switch to Hours for sub-day cadences (e.g. every 12 hours).")
            }
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
            Text("First notification fires \(frequencyDays) \(frequencyDays == 1 ? "day" : "days") from now at the time you pick here.")
        }
    }

    // MARK: - Helpers

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

    /// Day-based first fire: next occurrence of preferredTime hour:minute.
    /// Used when unit is .days so the first daily reminder lands at the
    /// user's preferred time of day.
    private static func firstFireDate(preferredTime: Date) -> Date {
        let calendar = Calendar.current
        let now = Date()
        let time = calendar.dateComponents([.hour, .minute], from: preferredTime)

        var today = calendar.dateComponents([.year, .month, .day], from: now)
        today.hour = time.hour
        today.minute = time.minute

        guard let todayAtTime = calendar.date(from: today) else {
            return calendar.date(byAdding: .day, value: 1, to: now) ?? now
        }

        if todayAtTime > now {
            return todayAtTime
        }
        return calendar.date(byAdding: .day, value: 1, to: todayAtTime) ?? now
    }

    /// Hour-based first fire: simply now + N hours so the next watering on a
    /// 12-hour cadence lands 12 hours from creation, not "tomorrow at 9 AM".
    private static func firstFireDate(hoursFromNow hours: Int) -> Date {
        Calendar.current.date(byAdding: .hour, value: hours, to: Date()) ?? Date()
    }

    // MARK: - Save

    private func save() {
        // The model's init seeds frequencyDays — we override with sub-day if
        // the user chose hours so the model arithmetic uses the right unit.
        let reminder = CareReminder(type: type.rawValue, frequencyDays: 1)

        switch unit {
        case .days:
            reminder.frequencyDays = frequencyValue
            reminder.nextDue = Self.firstFireDate(preferredTime: preferredTime)
        case .hours:
            reminder.frequencyHours = frequencyValue
            reminder.frequencyDays = 1
            reminder.nextDue = Self.firstFireDate(hoursFromNow: frequencyValue)
        }

        reminder.preferredTime = preferredTime
        reminder.amount = amount.trimmingCharacters(in: .whitespaces).isEmpty ? nil : amount
        reminder.notes = notes.trimmingCharacters(in: .whitespaces).isEmpty ? nil : notes
        reminder.plant = plant

        modelContext.insert(reminder)

        do {
            try modelContext.save()
            Haptics.success()
            Logger.data.info("Added reminder \(type.rawValue, privacy: .public) for \(plant.displayName, privacy: .public)")
        } catch {
            Logger.data.error("Add reminder failed: \(error.localizedDescription, privacy: .public)")
            Haptics.error()
            errorMessage = "Couldn't add the reminder. Try again."
            return
        }

        let reminderID = reminder.id
        let reminderType = reminder.type
        let plantName = plant.displayName
        let nextDue = reminder.nextDue

        let chosenTime = preferredTime
        Task {
            // Request permission lazily here too — if the user only ever
            // added a reminder manually (not via the auto-seed save flow)
            // this might be their first request.
            await NotificationService.shared.requestAuthorizationIfNeeded()
            await NotificationService.shared.schedule(
                reminderID: reminderID,
                type: reminderType,
                plantName: plantName,
                nextDue: nextDue,
                preferredTime: chosenTime,
                isEnabled: true
            )
        }

        dismiss()
    }
}
