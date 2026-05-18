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
    @State private var frequencyDays: Int = 7
    @State private var notes: String = ""
    @State private var amount: String = ""
    @State private var preferredTime: Date = Self.defaultMorning()
    @State private var errorMessage: String?

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
                        .disabled(frequencyDays < 1)
                }
            }
            .alert("Couldn't add", isPresented: errorBinding) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
            .onChange(of: type) { _, newType in
                // Reset the stepper to the new type's default whenever the
                // user switches between watering / pruning / etc.
                frequencyDays = newType.defaultDays
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
            Stepper(value: $frequencyDays, in: 1...365) {
                HStack {
                    Text("Every")
                    Text("\(frequencyDays) \(frequencyDays == 1 ? "day" : "days")")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color.forestGreen)
                }
            }
        } header: {
            Text("How often")
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

    // MARK: - Save

    private func save() {
        let reminder = CareReminder(type: type.rawValue, frequencyDays: frequencyDays)
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
                isEnabled: true
            )
        }

        dismiss()
    }
}
