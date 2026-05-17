//
//  SavePlantSheet.swift
//  Verdant
//
//  Created by Abrar Hamim on 5/17/26.
//
//  Day 14 deliverable. Adds a Plant + PlantScan to SwiftData with user-set
//  nickname, location, sunlight, indoor/outdoor, and grow-light flag.

import SwiftUI
import SwiftData
import os

struct SavePlantSheet: View {
    let result: PlantAnalysisResult
    let primaryPhotoData: Data?
    let photoCount: Int
    let onSaved: () -> Void

    @State private var nickname: String
    @State private var location: String = ""
    @State private var sunlightLevel: String = "medium"
    @State private var indoorOrOutdoor: String = "indoor"
    @State private var hasGrowLight: Bool = false
    @State private var isSaving = false
    @State private var errorMessage: String?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    init(
        result: PlantAnalysisResult,
        primaryPhotoData: Data?,
        photoCount: Int = 1,
        onSaved: @escaping () -> Void
    ) {
        self.result = result
        self.primaryPhotoData = primaryPhotoData
        self.photoCount = photoCount
        self.onSaved = onSaved
        _nickname = State(initialValue: result.commonNames.first ?? result.plantName)
    }

    var body: some View {
        NavigationStack {
            Form {
                identificationSection
                personalizeSection
                careSection
            }
            .navigationTitle("Save to My Plants")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .disabled(isSaving)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        savePlant()
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
        Section("Identification") {
            LabeledContent("Plant", value: result.plantName)
            if let scientific = result.scientificName, scientific != result.plantName {
                LabeledContent("Scientific name", value: scientific)
            }
            LabeledContent("Confidence", value: "\(result.confidencePercent)%")
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
        } footer: {
            Text("Nickname shows up everywhere instead of the scientific name.")
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

    // MARK: - Bindings + helpers

    private var trimmedNickname: String {
        nickname.trimmingCharacters(in: .whitespaces)
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )
    }

    // MARK: - Save

    private func savePlant() {
        isSaving = true
        defer { isSaving = false }

        let plant = Plant(
            name: result.plantName,
            nickname: trimmedNickname,
            location: location.trimmingCharacters(in: .whitespaces).isEmpty ? nil : location.trimmingCharacters(in: .whitespaces)
        )
        plant.commonNames = result.commonNames
        plant.scientificName = result.scientificName
        plant.imageData = primaryPhotoData
        plant.sunlightLevel = sunlightLevel
        plant.indoorOrOutdoor = indoorOrOutdoor
        plant.hasGrowLight = hasGrowLight
        plant.currentHealthStatus = result.hasDiseaseDetected ? "stressed" : "healthy"
        plant.lastHealthCheck = Date()

        let analysisJSON = encodeResultAsJSON(result)
        let scan = PlantScan(
            imageData: primaryPhotoData,
            analysisJSON: analysisJSON,
            plantNameDetected: result.plantName,
            healthStatus: result.hasDiseaseDetected ? "stressed" : "healthy",
            confidence: result.confidence,
            multiAngleScan: photoCount > 1,
            photoCount: photoCount
        )
        scan.diseaseDetected = result.disease?.name
        scan.diseaseProbability = result.disease?.probability
        scan.plant = plant

        modelContext.insert(plant)
        modelContext.insert(scan)

        do {
            try modelContext.save()
            Logger.data.info("Saved plant: \(trimmedNickname, privacy: .public)")
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            onSaved()
            dismiss()
        } catch {
            Logger.data.error("Save failed: \(error.localizedDescription, privacy: .public)")
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            errorMessage = "Couldn't save right now. Try again."
        }
    }

    private func encodeResultAsJSON(_ result: PlantAnalysisResult) -> String {
        do {
            let data = try JSONEncoder().encode(result)
            return String(data: data, encoding: .utf8) ?? ""
        } catch {
            Logger.data.error("Encode analysis failed: \(error.localizedDescription, privacy: .public)")
            return ""
        }
    }
}
