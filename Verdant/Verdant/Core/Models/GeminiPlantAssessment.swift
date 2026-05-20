//
//  GeminiPlantAssessment.swift
//  Verdant
//
//  Created by Abrar Hamim on 5/20/26.
//
//  Multimodal Gemini response shape per blueprint §5. The model returns one JSON
//  object covering identification, diagnosis, and treatment. AIService consumes this
//  via fallbackReason() to decide whether to use Gemini's answer or fall back to
//  Plant.id /health_assessment (blueprint §6.5 composite-fallback rules).

import Foundation

nonisolated struct GeminiPlantAssessment: Codable, Sendable, Equatable {
    let plantName: String
    let condition: String              // "Healthy" or specific disease name
    let confidenceScore: Int           // 0-100, logged for telemetry only — not a gate
    let symptoms: [String]             // visible symptoms; empty when condition is Healthy
    let organicTreatment: String       // step-by-step organic care plan
    let chemicalTreatment: String?     // optional — some conditions don't have a chemical fix

    enum CodingKeys: String, CodingKey {
        case plantName       = "plant_name"
        case condition
        case confidenceScore = "confidence_score"
        case symptoms
        case organicTreatment = "organic_treatment"
        case chemicalTreatment = "chemical_treatment"
    }

    var isHealthy: Bool {
        condition.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "healthy"
    }

    /// Composite-fallback check per blueprint §6.5. Returns nil if the assessment is
    /// internally consistent and usable; otherwise returns the reason to fall back to
    /// Plant.id /health_assessment. Deliberately ignores confidenceScore — LLM-emitted
    /// confidence is notoriously uncorrelated with correctness.
    func fallbackReason() -> FallbackReason? {
        if plantName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return .emptyPlantName
        }
        if condition.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return .emptyCondition
        }
        if isHealthy && !symptoms.isEmpty {
            return .selfContradictionHealthyWithSymptoms
        }
        if !isHealthy && organicTreatment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return .missingTreatmentForDiagnosedCondition
        }
        return nil
    }

    enum FallbackReason: String, Sendable, Equatable {
        case emptyPlantName                       = "plant_name was empty"
        case emptyCondition                       = "condition was empty"
        case selfContradictionHealthyWithSymptoms = "condition is Healthy but symptoms were non-empty"
        case missingTreatmentForDiagnosedCondition = "condition was diagnosed but organic_treatment was empty"
    }
}
