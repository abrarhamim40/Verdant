//
//  EditPlantSheet.swift
//  Verdant
//
//  Created by Abrar Hamim on 5/18/26.
//
//  Day 27 — edits an existing Plant's user-set fields (nickname, location,
//  sunlight, indoor/outdoor, grow light). Identification fields (name,
//  scientific name) stay locked because they came from Plant.id and editing
//  them would break the link to the original scan analysis.

import SwiftUI
import SwiftData
import os

struct EditPlantSheet: View {
    @Bindable var plant: Plant

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var nickname: String
    @State private var location: String
    @State private var sunlightLevel: String
    @State private var indoorOrOutdoor: String
    @State private var hasGrowLight: Bool
    @State private var isSaving = false
    @State private var errorMessage: String?

    init(plant: Plant) {
        self.plant = plant
        _nickname = State(initialValue: plant.nickname ?? plant.displayName)
        _location = State(initialValue: plant.location ?? "")
        _sunlightLevel = State(initialValue: plant.sunlightLevel)
        _indoorOrOutdoor = State(initialValue: plant.indoorOrOutdoor)
        _hasGrowLight = State(initialValue: plant.hasGrowLight)
    }

    var body: some View {
        NavigationStack {
            Form {
                identificationSection
                personalizeSection
                careSection
            }
            .navigationTitle("Edit plant")
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
                            Text("Save").bold()
                        }
                    }
                    .disabled(isSaving || trimmedNickname.isEmpty)
                }
            }
            .alert("Couldn't save", isPresented: errorBinding) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    // MARK: - Sections

    private var identificationSection: some View {
        Section {
            LabeledContent("Plant", value: plant.name)
            if let scientific = plant.scientificName, scientific != plant.name {
                LabeledContent("Scientific name", value: scientific)
            }
        } header: {
            Text("Identification")
        } footer: {
            Text("Identification comes from the scan and can't be edited here.")
        }
    }

    private var personalizeSection: some View {
        Section {
            TextField("Nickname", text: $nickname)
                .textInputAutocapitalization(.words)
            TextField("Location (e.g., Living Room)", text: $location)
                .textInputAutocapitalization(.words)
        } header: {
            Text("Make it yours")
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

    // MARK: - Helpers

    private var trimmedNickname: String {
        nickname.trimmingCharacters(in: .whitespaces)
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
        defer { isSaving = false }

        plant.nickname = trimmedNickname
        plant.location = trimmedLocation.isEmpty ? nil : trimmedLocation
        plant.sunlightLevel = sunlightLevel
        plant.indoorOrOutdoor = indoorOrOutdoor
        plant.hasGrowLight = hasGrowLight

        do {
            try modelContext.save()
            Logger.data.info("Edited plant: \(trimmedNickname, privacy: .public)")
            Haptics.success()
            dismiss()
        } catch {
            Logger.data.error("Edit save failed: \(error.localizedDescription, privacy: .public)")
            Haptics.error()
            errorMessage = "Couldn't save right now. Try again."
        }
    }
}
