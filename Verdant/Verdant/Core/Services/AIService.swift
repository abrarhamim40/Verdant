//
//  AIService.swift
//  Verdant
//
//  Created by Abrar Hamim on 5/17/26.
//
//  Coordinator: Apple Vision pre-filter → Plant.id identification → Gemini treatment.
//  Caches the final PlantAnalysisResult for 24h keyed on image hash + language + climate.

import Foundation
import CoreLocation
import os

actor AIService {
    static let shared = AIService()

    private let plantId: PlantIdService
    private let gemini: GeminiService
    private let vision: AppleVisionService
    private let cache: ResponseCache
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private let diseaseThreshold: Double = 0.5

    init(
        plantId: PlantIdService = .shared,
        gemini: GeminiService = .shared,
        vision: AppleVisionService = .shared,
        cache: ResponseCache = ResponseCache()
    ) {
        self.plantId = plantId
        self.gemini = gemini
        self.vision = vision
        self.cache = cache
    }

    func analyzePlant(
        images: [Data],
        location: CLLocationCoordinate2D? = nil,
        language: String = "English",
        climate: ClimateContext? = nil
    ) async throws -> PlantAnalysisResult {
        guard !images.isEmpty, images.count <= 5 else {
            throw AIError.invalidInput
        }

        // 1. Free on-device pre-filter — block non-plant photos early.
        let isPlant = await vision.containsPlant(imageData: images[0])
        guard isPlant else {
            Logger.ai.info("Apple Vision: no plant detected in first image")
            throw AIError.noPlantDetected
        }

        // 2. Cache check (skips Plant.id + Gemini if same scan ran within 24h).
        let key = Self.cacheKey(images: images, language: language, climate: climate)
        if let cached = await cache.get(hash: key),
           let result = try? decoder.decode(PlantAnalysisResult.self, from: cached) {
            Logger.ai.info("AIService cache hit — skipping API calls")
            return result
        }

        // 3. Plant.id identification.
        let identification = try await plantId.identify(images: images, location: location)

        guard let topPlant = identification.result.classification.suggestions.first else {
            throw AIError.identificationFailed
        }

        let disease = identification.result.disease?.suggestions
            .first(where: { $0.probability > diseaseThreshold })

        // 4. Gemini treatment plan (personalized to plant + disease + language + climate).
        let treatment = try await gemini.generateTreatment(
            plantName: topPlant.name,
            commonNames: topPlant.details?.commonNames ?? [],
            disease: disease,
            userLanguage: language,
            climate: climate
        )

        // 5. Combine into one result.
        let result = PlantAnalysisResult(
            plantName: topPlant.name,
            commonNames: topPlant.details?.commonNames ?? [],
            scientificName: topPlant.details?.taxonomy?.species,
            confidence: topPlant.probability,
            details: topPlant.details,
            disease: disease,
            treatment: treatment,
            alternativeMatches: Array(identification.result.classification.suggestions.dropFirst().prefix(3))
        )

        // 6. Cache for 24h.
        if let encoded = try? encoder.encode(result) {
            await cache.set(hash: key, data: encoded)
        }

        Logger.ai.info("Analysis complete: \(topPlant.name, privacy: .public) at \(Int(topPlant.probability * 100))%")
        return result
    }

    /// Deterministic key: identical inputs (photos + language + climate) hit cache for 24h.
    nonisolated static func cacheKey(
        images: [Data],
        language: String,
        climate: ClimateContext?
    ) -> String {
        var combined = Data()
        for image in images {
            combined.append(image)
        }
        var key = "\(combined.sha256Hash)_\(language)"
        if let climate {
            key += "_\(climate.location)_\(climate.season)"
        }
        return key
    }
}
