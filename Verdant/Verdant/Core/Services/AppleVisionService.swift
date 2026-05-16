//
//  AppleVisionService.swift
//  Verdant
//
//  Created by Abrar Hamim on 5/17/26.
//
//  Apple Vision pre-filter — runs on-device, free, ~50-200ms.
//  If user uploads a cat photo, we catch it here before paying for Plant.id.

import Foundation
import Vision
import os

actor AppleVisionService {
    static let shared = AppleVisionService()

    private let plantKeywords: Set<String> = [
        "plant", "flower", "leaf", "tree", "vegetation",
        "foliage", "succulent", "herb", "fern", "moss",
        "garden", "bush", "shrub", "grass"
    ]

    private let confidenceThreshold: Float = 0.3

    func containsPlant(imageData: Data) async -> Bool {
        let request = VNClassifyImageRequest()
        let handler = VNImageRequestHandler(data: imageData)

        do {
            try handler.perform([request])
        } catch {
            Logger.ai.error("Vision perform failed: \(error.localizedDescription, privacy: .public)")
            return false
        }

        guard let results = request.results else { return false }

        return results.contains { observation in
            let label = observation.identifier.lowercased()
            let matchesKeyword = plantKeywords.contains(where: { label.contains($0) })
            return matchesKeyword && observation.confidence > confidenceThreshold
        }
    }
}
