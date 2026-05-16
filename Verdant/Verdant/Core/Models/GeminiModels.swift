//
//  GeminiModels.swift
//  Verdant
//
//  Created by Abrar Hamim on 5/17/26.
//
//  Gemini 2.5 Pro API — request + response shapes.
//  Endpoint: POST https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-pro:generateContent

import Foundation

// MARK: - Request

nonisolated struct GeminiRequest: Codable, Sendable {
    let contents: [Content]
    let generationConfig: GenerationConfig

    struct Content: Codable, Sendable {
        let parts: [Part]
    }

    struct Part: Codable, Sendable {
        let text: String
    }

    struct GenerationConfig: Codable, Sendable {
        let temperature: Double
        let maxOutputTokens: Int
        let responseMimeType: String

        enum CodingKeys: String, CodingKey {
            case temperature
            case maxOutputTokens = "max_output_tokens"
            case responseMimeType = "response_mime_type"
        }
    }
}

// MARK: - Response

nonisolated struct GeminiResponse: Codable, Sendable {
    let candidates: [Candidate]

    struct Candidate: Codable, Sendable {
        let content: Content
    }

    struct Content: Codable, Sendable {
        let parts: [Part]
    }

    struct Part: Codable, Sendable {
        let text: String
    }
}

// MARK: - Treatment Plan (Gemini → app)

nonisolated struct TreatmentPlan: Codable, Sendable, Equatable {
    let summary: String
    let immediateActions: [String]
    let weeklyCare: [String]
    let warningSigns: [String]
    let recoveryTimeline: String
    let preventionTips: [String]
    let wateringFrequencyDays: Int
    let fertilizingFrequencyDays: Int

    enum CodingKeys: String, CodingKey {
        case summary
        case immediateActions = "immediate_actions"
        case weeklyCare = "weekly_care"
        case warningSigns = "warning_signs"
        case recoveryTimeline = "recovery_timeline"
        case preventionTips = "prevention_tips"
        case wateringFrequencyDays = "watering_frequency_days"
        case fertilizingFrequencyDays = "fertilizing_frequency_days"
    }
}

// MARK: - Climate Context (optional input to Gemini)

nonisolated struct ClimateContext: Codable, Sendable, Equatable {
    let location: String
    let humidity: Int
    let temperature: Int
    let season: String
}
