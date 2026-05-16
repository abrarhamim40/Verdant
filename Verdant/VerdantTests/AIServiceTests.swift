//
//  AIServiceTests.swift
//  VerdantTests
//
//  Created by Abrar Hamim on 5/17/26.
//

import Testing
import Foundation
@testable import Verdant

struct AIServiceTests {

    // MARK: - PlantAnalysisResult Codable + computed properties

    @Test func resultRoundtripsThroughCodable() throws {
        let plan = TreatmentPlan(
            summary: "Looks great",
            immediateActions: [],
            weeklyCare: ["water"],
            warningSigns: [],
            recoveryTimeline: "2 weeks",
            preventionTips: [],
            wateringFrequencyDays: 7,
            fertilizingFrequencyDays: 30
        )
        let result = PlantAnalysisResult(
            plantName: "Monstera deliciosa",
            commonNames: ["Swiss cheese plant"],
            scientificName: "Monstera deliciosa",
            confidence: 0.92,
            disease: nil,
            treatment: plan,
            alternativeMatches: []
        )

        let data = try JSONEncoder().encode(result)
        let decoded = try JSONDecoder().decode(PlantAnalysisResult.self, from: data)

        #expect(decoded.id == result.id)
        #expect(decoded.plantName == "Monstera deliciosa")
        #expect(decoded.confidence == 0.92)
        #expect(decoded.treatment.wateringFrequencyDays == 7)
    }

    @Test func confidencePercentMatchesScore() {
        let result = sampleResult(confidence: 0.876)
        #expect(result.confidencePercent == 87)
    }

    @Test func isHighConfidenceAt85Threshold() {
        #expect(sampleResult(confidence: 0.85).isHighConfidence)
        #expect(sampleResult(confidence: 0.849).isHighConfidence == false)
    }

    @Test func needsExpertReviewBelow70() {
        #expect(sampleResult(confidence: 0.69).needsExpertReview)
        #expect(sampleResult(confidence: 0.70).needsExpertReview == false)
    }

    @Test func hasDiseaseDetectedOnlyAboveHalf() {
        let disease = DiseaseSuggestion(id: "d", name: "Spot", probability: 0.6, details: nil)
        var r = sampleResult(confidence: 0.9, disease: disease)
        #expect(r.hasDiseaseDetected)

        let weakDisease = DiseaseSuggestion(id: "d", name: "Spot", probability: 0.4, details: nil)
        r = sampleResult(confidence: 0.9, disease: weakDisease)
        #expect(r.hasDiseaseDetected == false)

        r = sampleResult(confidence: 0.9, disease: nil)
        #expect(r.hasDiseaseDetected == false)
    }

    // MARK: - cacheKey determinism

    @Test func cacheKeyIsDeterministic() {
        let imgs = [Data("photo".utf8)]
        let k1 = AIService.cacheKey(images: imgs, language: "English", climate: nil)
        let k2 = AIService.cacheKey(images: imgs, language: "English", climate: nil)
        #expect(k1 == k2)
    }

    @Test func cacheKeyDiffersByLanguage() {
        let imgs = [Data("photo".utf8)]
        let en = AIService.cacheKey(images: imgs, language: "English", climate: nil)
        let bn = AIService.cacheKey(images: imgs, language: "Bengali", climate: nil)
        #expect(en != bn)
    }

    @Test func cacheKeyDiffersByImageContent() {
        let a = AIService.cacheKey(images: [Data("a".utf8)], language: "English", climate: nil)
        let b = AIService.cacheKey(images: [Data("b".utf8)], language: "English", climate: nil)
        #expect(a != b)
    }

    @Test func cacheKeyIncludesClimateWhenProvided() {
        let imgs = [Data("photo".utf8)]
        let none = AIService.cacheKey(images: imgs, language: "English", climate: nil)
        let dhaka = AIService.cacheKey(
            images: imgs,
            language: "English",
            climate: ClimateContext(location: "Dhaka", humidity: 78, temperature: 30, season: "monsoon")
        )
        #expect(none != dhaka)
    }

    // MARK: - helpers

    private func sampleResult(confidence: Double, disease: DiseaseSuggestion? = nil) -> PlantAnalysisResult {
        PlantAnalysisResult(
            plantName: "X",
            commonNames: [],
            scientificName: nil,
            confidence: confidence,
            disease: disease,
            treatment: TreatmentPlan(
                summary: "",
                immediateActions: [],
                weeklyCare: [],
                warningSigns: [],
                recoveryTimeline: "",
                preventionTips: [],
                wateringFrequencyDays: 0,
                fertilizingFrequencyDays: 0
            ),
            alternativeMatches: []
        )
    }
}
