//
//  PlantIdModels.swift
//  Verdant
//
//  Created by Abrar Hamim on 5/17/26.
//
//  Plant.id v3 API — request + response shapes.
//  Endpoint: POST https://plant.id/api/v3/identification

import Foundation

// MARK: - Request

nonisolated struct PlantIdRequest: Codable, Sendable {
    let images: [String]
    let latitude: Double?
    let longitude: Double?

    enum CodingKeys: String, CodingKey {
        case images, latitude, longitude
    }
}

// MARK: - Response

nonisolated struct PlantIdResponse: Codable, Sendable {
    let result: PlantIdResult
}

nonisolated struct PlantIdResult: Codable, Sendable {
    let isPlant: ProbabilityResult
    let classification: Classification
    let disease: DiseaseAssessment?

    enum CodingKeys: String, CodingKey {
        case isPlant = "is_plant"
        case classification, disease
    }
}

nonisolated struct ProbabilityResult: Codable, Sendable {
    let probability: Double
}

nonisolated struct Classification: Codable, Sendable {
    let suggestions: [PlantSuggestion]
}

nonisolated struct PlantSuggestion: Codable, Identifiable, Sendable {
    let id: String
    let name: String
    let probability: Double
    let details: PlantDetails?
}

nonisolated struct PlantDetails: Codable, Sendable {
    let commonNames: [String]?
    let url: String?
    let taxonomy: Taxonomy?
    let watering: Watering?
    let description: PlantDescription?

    enum CodingKeys: String, CodingKey {
        case commonNames = "common_names"
        case url, taxonomy, watering, description
    }
}

nonisolated struct Taxonomy: Codable, Sendable {
    let kingdom: String?
    let family: String?
    let genus: String?
    let species: String?
}

nonisolated struct Watering: Codable, Sendable {
    let max: Int?
    let min: Int?
}

nonisolated struct PlantDescription: Codable, Sendable {
    let value: String?
    let citation: String?
}

nonisolated struct DiseaseAssessment: Codable, Sendable {
    let suggestions: [DiseaseSuggestion]
}

nonisolated struct DiseaseSuggestion: Codable, Identifiable, Sendable {
    let id: String
    let name: String
    let probability: Double
    let details: DiseaseDetails?
}

nonisolated struct DiseaseDetails: Codable, Sendable {
    let description: String?
    let treatment: Treatment?
    let cause: String?
    let url: String?
}

nonisolated struct Treatment: Codable, Sendable {
    let prevention: [String]?
    let chemical: [String]?
    let biological: [String]?
}
