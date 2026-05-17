//
//  PlantAnalysisResult.swift
//  Verdant
//
//  Created by Abrar Hamim on 5/17/26.
//
//  Combined output of one full scan: Plant.id identification + Gemini treatment.
//  Cached as Data inside ResponseCache; persisted via PlantScan.analysisJSON.

import Foundation

nonisolated struct PlantAnalysisResult: Codable, Sendable, Identifiable {
    let id: UUID
    let plantName: String
    let commonNames: [String]
    let scientificName: String?
    let confidence: Double
    let details: PlantDetails?
    let disease: DiseaseSuggestion?
    let treatment: TreatmentPlan
    let alternativeMatches: [PlantSuggestion]
    let timestamp: Date

    init(
        id: UUID = UUID(),
        plantName: String,
        commonNames: [String],
        scientificName: String?,
        confidence: Double,
        details: PlantDetails? = nil,
        disease: DiseaseSuggestion?,
        treatment: TreatmentPlan,
        alternativeMatches: [PlantSuggestion],
        timestamp: Date = Date()
    ) {
        self.id = id
        self.plantName = plantName
        self.commonNames = commonNames
        self.scientificName = scientificName
        self.confidence = confidence
        self.details = details
        self.disease = disease
        self.treatment = treatment
        self.alternativeMatches = alternativeMatches
        self.timestamp = timestamp
    }

    var confidencePercent: Int { Int(confidence * 100) }
    var isHighConfidence: Bool { confidence >= 0.85 }
    var needsExpertReview: Bool { confidence < 0.70 }
    var hasDiseaseDetected: Bool { (disease?.probability ?? 0) > 0.5 }
}
