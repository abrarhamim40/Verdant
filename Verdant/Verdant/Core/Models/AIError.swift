//
//  AIError.swift
//  Verdant
//
//  Created by Abrar Hamim on 5/17/26.
//

import Foundation

enum AIError: LocalizedError, Equatable {
    case noPlantDetected
    case imageUnclear
    case compressionFailed
    case identificationFailed
    case lowConfidence(Double)
    case invalidAPIKey
    case rateLimited
    case networkError
    case serverError
    case invalidInput
    case invalidResponse
    case parsingFailed
    case unknownError(Int)

    var errorDescription: String? {
        switch self {
        case .noPlantDetected:
            return "No plant detected. Try a clearer photo."
        case .imageUnclear:
            return "Image is too blurry. Use better lighting."
        case .compressionFailed:
            return "Failed to process image."
        case .identificationFailed:
            return "Could not identify this plant."
        case .lowConfidence(let confidence):
            return "Low confidence (\(Int(confidence * 100))%). Try multiple angles."
        case .invalidAPIKey:
            return "Authentication failed. Please try again."
        case .rateLimited:
            return "Too many requests. Wait a few minutes."
        case .networkError:
            return "Check your internet connection."
        case .serverError:
            return "Server temporarily unavailable."
        case .invalidInput:
            return "Invalid input."
        case .invalidResponse:
            return "Unexpected response from server."
        case .parsingFailed:
            return "Failed to process result."
        case .unknownError(let code):
            return "Error \(code). Please try again."
        }
    }

    var recoveryAction: String? {
        switch self {
        case .noPlantDetected: return "Take a clearer photo of a plant"
        case .imageUnclear: return "Use better lighting and focus"
        case .lowConfidence: return "Try multiple angles"
        case .rateLimited: return "Wait a few minutes"
        case .networkError: return "Check WiFi or cellular"
        default: return nil
        }
    }
}
