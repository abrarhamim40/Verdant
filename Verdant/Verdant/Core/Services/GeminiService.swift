//
//  GeminiService.swift
//  Verdant
//
//  Created by Abrar Hamim on 5/17/26.
//

import Foundation
import os

actor GeminiService {
    static let shared = GeminiService()

    private let apiKey: String
    private let model: String
    private let session: URLSession
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(
        apiKey: String? = nil,
        model: String = "gemini-3.5-flash",
        session: URLSession? = nil
    ) {
        self.apiKey = apiKey ?? APIKeys.gemini
        self.model = model

        if let session {
            self.session = session
        } else {
            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = 30
            config.timeoutIntervalForResource = 60
            config.waitsForConnectivity = true
            self.session = URLSession(configuration: config)
        }
    }

    func generateTreatment(
        plantName: String,
        commonNames: [String],
        disease: DiseaseSuggestion?,
        userLanguage: String = "English",
        climate: ClimateContext? = nil
    ) async throws -> TreatmentPlan {
        let prompt = Self.buildPrompt(
            plantName: plantName,
            commonNames: commonNames,
            disease: disease,
            language: userLanguage,
            climate: climate
        )

        let body = GeminiRequest(
            contents: [.init(parts: [.init(text: prompt)])],
            generationConfig: .init(
                temperature: 0.7,
                maxOutputTokens: 2048,
                responseMimeType: "application/json",
                // Disable thinking — for structured JSON we want direct output, not reasoning tokens.
                thinkingConfig: .init(thinkingBudget: 0)
            )
        )

        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(apiKey)") else {
            throw AIError.invalidInput
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(body)

        #if DEBUG
        Logger.ai.debug("Gemini URL: https://generativelanguage.googleapis.com/v1beta/models/\(self.model, privacy: .public):generateContent")
        if let bodyStr = String(data: request.httpBody ?? Data(), encoding: .utf8) {
            Logger.ai.debug("Gemini request body: \(bodyStr, privacy: .public)")
        }
        #endif

        let started = Date()
        Logger.ai.info("Gemini request started")

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            Logger.ai.error("Gemini transport error: \(error.localizedDescription, privacy: .public)")
            throw AIError.networkError
        }

        let elapsed = Date().timeIntervalSince(started)
        Logger.ai.info("Gemini response in \(elapsed, format: .fixed(precision: 2))s")

        guard let http = response as? HTTPURLResponse else {
            throw AIError.networkError
        }

        #if DEBUG
        if let bodyStr = String(data: data, encoding: .utf8) {
            Logger.ai.debug("Gemini response [\(http.statusCode)]: \(bodyStr, privacy: .public)")
        }
        #endif

        switch http.statusCode {
        case 200, 201:
            return try Self.parseGeminiResponse(data, decoder: decoder)
        case 400:
            Self.logErrorBody(data, status: 400)
            throw AIError.invalidInput
        case 401, 403:
            Self.logErrorBody(data, status: http.statusCode)
            throw AIError.invalidAPIKey
        case 429:
            Self.logErrorBody(data, status: 429)
            throw AIError.rateLimited
        case 500...599:
            Self.logErrorBody(data, status: http.statusCode)
            throw AIError.serverError
        default:
            Self.logErrorBody(data, status: http.statusCode)
            throw AIError.unknownError(http.statusCode)
        }
    }

    nonisolated private static func logErrorBody(_ data: Data, status: Int) {
        if let body = String(data: data, encoding: .utf8) {
            Logger.ai.error("Gemini \(status) body: \(body, privacy: .public)")
        }
    }

    // MARK: - Pure helpers (testable, no actor isolation needed)

    nonisolated static func buildPrompt(
        plantName: String,
        commonNames: [String],
        disease: DiseaseSuggestion?,
        language: String,
        climate: ClimateContext?
    ) -> String {
        var prompt = """
        You are an expert botanist. Generate a personalized care plan in \(language).

        Plant: \(plantName)
        Common names: \(commonNames.joined(separator: ", "))
        """

        if let disease {
            prompt += """

            Detected issue: \(disease.name)
            Confidence: \(Int(disease.probability * 100))%
            Description: \(disease.details?.description ?? "")
            """
        } else {
            // Plant.id did not flag a confident disease. That does NOT mean the plant is definitely healthy —
            // it might be diseased in a way the model didn't recognize, or the photo angle missed the issue.
            // Tell Gemini to keep this in mind so the care plan doesn't overclaim.
            prompt += "\n\nNo specific disease was flagged by Plant.id. The plant may be healthy, but it is also possible an issue exists that wasn't detected. Include warning signs the user should watch for so they can spot issues early."
        }

        if let climate {
            prompt += """

            User's climate:
            - Location: \(climate.location)
            - Average humidity: \(climate.humidity)%
            - Average temperature: \(climate.temperature)°C
            - Season: \(climate.season)

            Adjust recommendations for this climate.
            """
        }

        prompt += """

        Respond with ONLY valid JSON (no markdown):
        {
          "summary": "1-2 sentence overview",
          "immediate_actions": ["urgent action 1", "action 2"],
          "weekly_care": ["routine 1", "routine 2", "routine 3"],
          "warning_signs": ["sign 1", "sign 2"],
          "recovery_timeline": "estimated time in plain language",
          "prevention_tips": ["tip 1", "tip 2"],
          "watering_frequency_days": 7,
          "fertilizing_frequency_days": 30
        }

        Rules:
        - Be specific and actionable.
        - Include concrete measurements (e.g., "1 cup every 7 days").
        - Friendly but professional tone.
        - Reference plant biology when helpful.
        """

        return prompt
    }

    nonisolated static func parseGeminiResponse(_ data: Data, decoder: JSONDecoder) throws -> TreatmentPlan {
        let response: GeminiResponse
        do {
            response = try decoder.decode(GeminiResponse.self, from: data)
        } catch {
            Logger.ai.error("Gemini envelope decode failed: \(error.localizedDescription, privacy: .public)")
            throw AIError.invalidResponse
        }

        guard let candidate = response.candidates.first else {
            throw AIError.invalidResponse
        }

        // Output got truncated — token budget too low or thinking consumed it.
        if candidate.finishReason == "MAX_TOKENS" {
            Logger.ai.error("Gemini truncated at MAX_TOKENS — bump maxOutputTokens or disable thinking")
            throw AIError.parsingFailed
        }

        guard let rawText = candidate.content.parts.first?.text else {
            throw AIError.invalidResponse
        }

        return try parseTreatmentJSON(rawText, decoder: decoder)
    }

    nonisolated static func parseTreatmentJSON(_ text: String, decoder: JSONDecoder = JSONDecoder()) throws -> TreatmentPlan {
        let cleaned = text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let jsonData = cleaned.data(using: .utf8) else {
            throw AIError.parsingFailed
        }

        do {
            return try decoder.decode(TreatmentPlan.self, from: jsonData)
        } catch {
            Logger.ai.error("TreatmentPlan decode failed: \(error.localizedDescription, privacy: .public)")
            throw AIError.parsingFailed
        }
    }
}
