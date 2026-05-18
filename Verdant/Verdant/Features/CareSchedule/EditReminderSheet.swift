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

    @State private var frequencyDays: Int
    @State private var notes: String
    @State private var amount: String
    @State private var preferredTime: Date
    @State private var isEnabled: Bool
    @State private var showDeleteConfirm = false
    @State private var errorMessage: String?

    init(reminder: CareReminder) {
        self.reminder = reminder
        _frequencyDays = State(initialValue: reminder.frequencyDays)
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
                        .disabled(frequencyDays < 1)
                }
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
        } footer: {
            Text("Your climate beats any default. Bump the interval up in dry season, down when growth slows.")
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
        }
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
        let frequencyChanged = frequencyDays != reminder.frequencyDays
        let enabledChanged = isEnabled != reminder.isEnabled

        reminder.notes = notes.trimmingCharacters(in: .whitespaces).isEmpty ? nil : notes
        reminder.amount = amount.trimmingCharacters(in: .whitespaces).isEmpty ? nil : amount
        reminder.preferredTime = preferredTime
        reminder.isEnabled = isEnabled

        if frequencyChanged {
            // Re-anchors nextDue inside the model + flips customFrequency on.
            reminder.setCustomFrequency(frequencyDays)
        }

        // Snapshot for the Task — reminder access has to stay on the main actor.
        let reminderID = reminder.id
        let type = reminder.type
        let plantName = reminder.plant?.displayName ?? "Plant"
        let nextDue = reminder.nextDue
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

        // Reschedule whenever the frequency moved OR the enabled toggle changed.
        if frequencyChanged || enabledChanged {
            Task {
                await NotificationService.shared.schedule(
                    reminderID: reminderID,
                    type: type,
                    plantName: plantName,
                    nextDue: nextDue,
                    isEnabled: enabled
                )
            }
        }

        dismiss()
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
