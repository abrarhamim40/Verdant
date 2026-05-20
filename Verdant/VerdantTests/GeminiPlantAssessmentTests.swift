//
//  GeminiPlantAssessmentTests.swift
//  VerdantTests
//
//  Created by Abrar Hamim on 5/20/26.
//

import Testing
import Foundation
@testable import Verdant

struct GeminiPlantAssessmentTests {

    // MARK: - Decoding

    @Test func decodesHealthyAssessment() throws {
        let json = """
        {
          "plant_name": "Monstera deliciosa",
          "condition": "Healthy",
          "confidence_score": 92,
          "symptoms": [],
          "organic_treatment": "",
          "chemical_treatment": null
        }
        """
        let data = try #require(json.data(using: .utf8))
        let assessment = try JSONDecoder().decode(GeminiPlantAssessment.self, from: data)
        #expect(assessment.plantName == "Monstera deliciosa")
        #expect(assessment.condition == "Healthy")
        #expect(assessment.confidenceScore == 92)
        #expect(assessment.symptoms.isEmpty)
        #expect(assessment.organicTreatment.isEmpty)
        #expect(assessment.chemicalTreatment == nil)
        #expect(assessment.isHealthy == true)
    }

    @Test func decodesDiagnosedAssessment() throws {
        let json = """
        {
          "plant_name": "Rosa 'Peace'",
          "condition": "Black spot",
          "confidence_score": 78,
          "symptoms": ["dark circular lesions on lower leaves", "yellowing margins"],
          "organic_treatment": "Remove infected leaves. Apply neem oil weekly.",
          "chemical_treatment": "Mancozeb 75% WP, follow label rates"
        }
        """
        let data = try #require(json.data(using: .utf8))
        let assessment = try JSONDecoder().decode(GeminiPlantAssessment.self, from: data)
        #expect(assessment.plantName == "Rosa 'Peace'")
        #expect(assessment.condition == "Black spot")
        #expect(assessment.symptoms.count == 2)
        #expect(assessment.chemicalTreatment == "Mancozeb 75% WP, follow label rates")
        #expect(assessment.isHealthy == false)
    }

    @Test func chemicalTreatmentMissingDecodesAsNil() throws {
        let json = """
        {
          "plant_name": "Aloe vera",
          "condition": "Healthy",
          "confidence_score": 88,
          "symptoms": [],
          "organic_treatment": ""
        }
        """
        let data = try #require(json.data(using: .utf8))
        let assessment = try JSONDecoder().decode(GeminiPlantAssessment.self, from: data)
        #expect(assessment.chemicalTreatment == nil)
    }

    // MARK: - isHealthy parsing

    @Test func isHealthyIsCaseInsensitiveAndTrimmed() throws {
        let cases = ["Healthy", "healthy", "HEALTHY", "  Healthy ", "\thealthy\n"]
        for raw in cases {
            let json = """
            { "plant_name": "Aloe", "condition": "\(raw)", "confidence_score": 70, "symptoms": [], "organic_treatment": "" }
            """
            let data = try #require(json.data(using: .utf8))
            let a = try JSONDecoder().decode(GeminiPlantAssessment.self, from: data)
            #expect(a.isHealthy == true, "expected healthy for '\(raw)'")
        }
    }

    @Test func diseaseConditionIsNotHealthy() throws {
        let json = """
        { "plant_name": "Aloe", "condition": "Root rot", "confidence_score": 70, "symptoms": ["mushy roots"], "organic_treatment": "Repot in fresh dry mix." }
        """
        let data = try #require(json.data(using: .utf8))
        let a = try JSONDecoder().decode(GeminiPlantAssessment.self, from: data)
        #expect(a.isHealthy == false)
    }

    // MARK: - fallbackReason() composite check

    @Test func validHealthyAssessmentReturnsNoFallback() {
        let a = GeminiPlantAssessment(
            plantName: "Monstera deliciosa",
            condition: "Healthy",
            confidenceScore: 92,
            symptoms: [],
            organicTreatment: "",
            chemicalTreatment: nil
        )
        #expect(a.fallbackReason() == nil)
    }

    @Test func validDiagnosedAssessmentReturnsNoFallback() {
        let a = GeminiPlantAssessment(
            plantName: "Rosa 'Peace'",
            condition: "Black spot",
            confidenceScore: 78,
            symptoms: ["leaf lesions"],
            organicTreatment: "Remove infected leaves.",
            chemicalTreatment: nil
        )
        #expect(a.fallbackReason() == nil)
    }

    @Test func emptyPlantNameTriggersFallback() {
        let a = GeminiPlantAssessment(
            plantName: "",
            condition: "Healthy",
            confidenceScore: 92,
            symptoms: [],
            organicTreatment: "",
            chemicalTreatment: nil
        )
        #expect(a.fallbackReason() == .emptyPlantName)
    }

    @Test func whitespaceOnlyPlantNameTriggersFallback() {
        let a = GeminiPlantAssessment(
            plantName: "   \n",
            condition: "Healthy",
            confidenceScore: 92,
            symptoms: [],
            organicTreatment: "",
            chemicalTreatment: nil
        )
        #expect(a.fallbackReason() == .emptyPlantName)
    }

    @Test func emptyConditionTriggersFallback() {
        let a = GeminiPlantAssessment(
            plantName: "Aloe",
            condition: "",
            confidenceScore: 70,
            symptoms: [],
            organicTreatment: "",
            chemicalTreatment: nil
        )
        #expect(a.fallbackReason() == .emptyCondition)
    }

    @Test func healthyWithSymptomsIsSelfContradiction() {
        let a = GeminiPlantAssessment(
            plantName: "Aloe",
            condition: "Healthy",
            confidenceScore: 90,
            symptoms: ["yellowing"],   // contradicts "Healthy"
            organicTreatment: "",
            chemicalTreatment: nil
        )
        #expect(a.fallbackReason() == .selfContradictionHealthyWithSymptoms)
    }

    @Test func diagnosedWithoutTreatmentTriggersFallback() {
        let a = GeminiPlantAssessment(
            plantName: "Aloe",
            condition: "Root rot",
            confidenceScore: 80,
            symptoms: ["mushy roots"],
            organicTreatment: "",       // condition non-Healthy but no treatment
            chemicalTreatment: nil
        )
        #expect(a.fallbackReason() == .missingTreatmentForDiagnosedCondition)
    }

    @Test func confidenceScoreNeverTriggersFallback() {
        // Blueprint §6.5: confidenceScore is logged for telemetry only — never gates fallback.
        let a = GeminiPlantAssessment(
            plantName: "Aloe",
            condition: "Healthy",
            confidenceScore: 0,        // would be a fail threshold under the old rule
            symptoms: [],
            organicTreatment: "",
            chemicalTreatment: nil
        )
        #expect(a.fallbackReason() == nil)
    }
}
