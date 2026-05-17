//
//  GeminiServiceTests.swift
//  VerdantTests
//
//  Created by Abrar Hamim on 5/17/26.
//

import Testing
import Foundation
@testable import Verdant

struct GeminiServiceTests {

    // MARK: - TreatmentPlan Codable

    @Test func treatmentPlanDecodesSnakeCase() throws {
        let json = """
        {
          "summary": "Healthy Monstera, no issues",
          "immediate_actions": ["Check soil moisture"],
          "weekly_care": ["Water deeply once", "Wipe leaves"],
          "warning_signs": ["Yellow leaves", "Brown tips"],
          "recovery_timeline": "2 weeks",
          "prevention_tips": ["Bright indirect light"],
          "watering_frequency_days": 7,
          "fertilizing_frequency_days": 30
        }
        """
        let data = try #require(json.data(using: .utf8))
        let plan = try JSONDecoder().decode(TreatmentPlan.self, from: data)

        #expect(plan.summary == "Healthy Monstera, no issues")
        #expect(plan.immediateActions == ["Check soil moisture"])
        #expect(plan.weeklyCare.count == 2)
        #expect(plan.wateringFrequencyDays == 7)
        #expect(plan.fertilizingFrequencyDays == 30)
    }

    @Test func treatmentPlanRoundtripsCleanly() throws {
        let plan = TreatmentPlan(
            summary: "S",
            immediateActions: ["a"],
            weeklyCare: ["b"],
            warningSigns: ["c"],
            recoveryTimeline: "1 day",
            preventionTips: ["d"],
            wateringFrequencyDays: 5,
            fertilizingFrequencyDays: 21
        )
        let data = try JSONEncoder().encode(plan)
        let decoded = try JSONDecoder().decode(TreatmentPlan.self, from: data)
        #expect(decoded == plan)
    }

    // MARK: - Prompt builder

    @Test func promptContainsPlantNameAndLanguage() {
        let prompt = GeminiService.buildPrompt(
            plantName: "Monstera deliciosa",
            commonNames: ["Swiss cheese plant"],
            disease: nil,
            language: "Bengali",
            climate: nil
        )
        #expect(prompt.contains("Monstera deliciosa"))
        #expect(prompt.contains("Bengali"))
        #expect(prompt.contains("Swiss cheese plant"))
    }

    @Test func promptIncludesDiseaseSectionWhenProvided() {
        let disease = DiseaseSuggestion(
            id: "d1",
            name: "Leaf spot",
            probability: 0.72,
            details: DiseaseDetails(description: "Fungal lesions", treatment: nil, cause: nil, url: nil)
        )
        let prompt = GeminiService.buildPrompt(
            plantName: "Monstera",
            commonNames: [],
            disease: disease,
            language: "English",
            climate: nil
        )
        #expect(prompt.contains("Detected issue: Leaf spot"))
        #expect(prompt.contains("72%"))
        #expect(prompt.contains("Fungal lesions"))
    }

    @Test func promptHedgesWhenNoDiseaseFlagged() {
        // We deliberately don't say "the plant is healthy" — Plant.id missing a disease
        // doesn't prove absence. The prompt should ask Gemini to keep this uncertainty.
        let prompt = GeminiService.buildPrompt(
            plantName: "Aloe",
            commonNames: [],
            disease: nil,
            language: "English",
            climate: nil
        )
        #expect(prompt.contains("No specific disease was flagged"))
        #expect(prompt.contains("not detected") || prompt.contains("not flagged") || prompt.contains("possible"))
        #expect(prompt.contains("warning signs"))
    }

    @Test func promptIncludesClimateWhenProvided() {
        let climate = ClimateContext(location: "Dhaka", humidity: 78, temperature: 30, season: "monsoon")
        let prompt = GeminiService.buildPrompt(
            plantName: "Aloe",
            commonNames: [],
            disease: nil,
            language: "English",
            climate: climate
        )
        #expect(prompt.contains("Dhaka"))
        #expect(prompt.contains("78%"))
        #expect(prompt.contains("30°C"))
        #expect(prompt.contains("monsoon"))
    }

    // MARK: - JSON cleaning

    @Test func parseStripsMarkdownFences() throws {
        let text = """
        ```json
        {"summary":"x","immediate_actions":[],"weekly_care":[],"warning_signs":[],"recovery_timeline":"y","prevention_tips":[],"watering_frequency_days":7,"fertilizing_frequency_days":30}
        ```
        """
        let plan = try GeminiService.parseTreatmentJSON(text)
        #expect(plan.summary == "x")
        #expect(plan.recoveryTimeline == "y")
    }

    @Test func parsePlainJSON() throws {
        let text = #"{"summary":"ok","immediate_actions":[],"weekly_care":[],"warning_signs":[],"recovery_timeline":"now","prevention_tips":[],"watering_frequency_days":3,"fertilizing_frequency_days":14}"#
        let plan = try GeminiService.parseTreatmentJSON(text)
        #expect(plan.wateringFrequencyDays == 3)
    }

    @Test func parseInvalidJSONThrowsParsingFailed() {
        #expect(throws: AIError.parsingFailed) {
            _ = try GeminiService.parseTreatmentJSON("not json at all")
        }
    }

    // MARK: - Full Gemini envelope

    @Test func parseGeminiResponseExtractsNestedJSON() throws {
        let envelope = """
        {
          "candidates": [
            {
              "content": {
                "parts": [
                  { "text": "{\\"summary\\":\\"s\\",\\"immediate_actions\\":[],\\"weekly_care\\":[],\\"warning_signs\\":[],\\"recovery_timeline\\":\\"r\\",\\"prevention_tips\\":[],\\"watering_frequency_days\\":7,\\"fertilizing_frequency_days\\":30}" }
                ]
              },
              "finishReason": "STOP"
            }
          ]
        }
        """
        let data = try #require(envelope.data(using: .utf8))
        let plan = try GeminiService.parseGeminiResponse(data, decoder: JSONDecoder())
        #expect(plan.summary == "s")
    }

    @Test func parseGeminiResponseThrowsOnMaxTokens() throws {
        // Mimics gemini-2.5-flash truncating with thinking enabled and a small output budget.
        let envelope = """
        {
          "candidates": [
            {
              "content": { "parts": [{ "text": "{\\"summary\\":\\"Incomplete" }] },
              "finishReason": "MAX_TOKENS"
            }
          ]
        }
        """
        let data = try #require(envelope.data(using: .utf8))
        #expect(throws: AIError.parsingFailed) {
            _ = try GeminiService.parseGeminiResponse(data, decoder: JSONDecoder())
        }
    }
}
