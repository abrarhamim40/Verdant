//
//  AddPlantSheet.swift
//  Verdant
//
//  Created by Abrar Hamim on 5/18/26.
//
//  Day 27 — manual plant entry, for users who already know what they have
//  and don't want to scan. No PlantScan is created; the detail screen will
//  fall back to noScanCallout until a scan is run.

import SwiftUI
import SwiftData
import os

struct AddPlantSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var location: String = ""
    @State private var sunlightLevel: String = "medium"
    @State private var indoorOrOutdoor: String = "indoor"
    @State private var hasGrowLight: Bool = false
    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                nameSection
                careSection
                hintSection
            }
            .navigationTitle("Add a plant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .disabled(isSaving)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        save()
                    } label: {
                        if isSaving {
                            ProgressView()
                        } else {
                            Text("Add").bold()
                        }
                    }
                    .disabled(isSaving || trimmedName.isEmpty)
                }
            }
            .alert("Couldn't add", isPresented: errorBinding) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    // MARK: - Sections

    private var nameSection: some View {
        Section {
            TextField("Plant name", text: $name)
                .textInputAutocapitalization(.words)
            TextField("Location (e.g., Bedroom)", text: $location)
                .textInputAutocapitalization(.words)
        } header: {
            Text("What to call it")
        } footer: {
            Text("Use whatever name you'd recognize — \"Big Mo\" works just as well as \"Monstera deliciosa\".")
        }
    }

    private var careSection: some View {
        Section("Care") {
            Picker("Sunlight", selection: $sunlightLevel) {
                Text("Low light").tag("low")
                Text("Medium").tag("medium")
                Text("Bright").tag("bright")
            }
            Picker("Where it lives", selection: $indoorOrOutdoor) {
                Text("Indoor").tag("indoor")
                Text("Outdoor").tag("outdoor")
            }
            Toggle("Has a grow light", isOn: $hasGrowLight)
        }
    }

    private var hintSection: some View {
        Section {
            Label {
                Text("Run a scan later for AI identification and a care plan.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } icon: {
                Image(systemName: "camera.viewfinder")
                    .foregroundStyle(Color.forestGreen)
            }
        }
    }

    // MARK: - Helpers

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespaces)
    }

    private var trimmedLocation: String {
        location.trimmingCharacters(in: .whitespaces)
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )
    }

    // MARK: - Save

    private func save() {
        isSaving = true

        let plant = Plant(
            name: trimmedName,
            nickname: trimmedName,
            location: trimmedLocation.isEmpty ? nil : trimmedLocation
        )
        plant.sunlightLevel = sunlightLevel
        plant.indoorOrOutdoor = indoorOrOutdoor
        plant.hasGrowLight = hasGrowLight
        plant.currentHealthStatus = "healthy"

        let reminders = Plant.defaultReminders()
        for reminder in reminders { reminder.plant = plant }

        modelContext.insert(plant)
        reminders.forEach(modelContext.insert)

        do {
            try modelContext.save()
            Logger.data.info("Added plant manually: \(trimmedName, privacy: .public)")
            Haptics.success()
            scheduleNotifications(for: reminders, plantName: trimmedName)
            dismiss()
        } catch {
            isSaving = false
            Logger.data.error("Manual add failed: \(error.localizedDescription, privacy: .public)")
            Haptics.error()
            errorMessage = "Couldn't add right now. Try again."
        }
    }

    /// Fire-and-forget — permission prompt fires on first save, subsequent
    /// saves just schedule. Silently skipped if user denies permission.
    private func scheduleNotifications(for reminders: [CareReminder], plantName: String) {
        Task {
            await NotificationService.shared.requestAuthorizationIfNeeded()
            for reminder in reminders {
                await NotificationService.shared.schedule(
                    reminderID: reminder.id,
                    type: reminder.type,
                    plantName: plantName,
                    nextDue: reminder.nextDue,
                    isEnabled: reminder.isEnabled
                )
            }
        }
    }
}
