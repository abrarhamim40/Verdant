//
//  AppleVisionService.swift
//  Verdant
//
//  Created by Abrar Hamim on 5/17/26.
//
//  On-device plant pre-filter using Vision's VNClassifyImageRequest.
//  Runs ~50-200ms, free, blocks obvious non-plant photos before paying for Plant.id.
//  Plant.id itself is more accurate (returns is_plant probability), so this is a
//  cheap first-pass not a definitive classifier.

import Foundation
import Vision
import os

actor AppleVisionService {
    static let shared = AppleVisionService()

    /// Substrings to match against Vision classification labels (case-insensitive).
    /// Vision returns hierarchical labels like "plant", "flower", "leaf vegetable", etc.
    /// Tunable as we observe real data via DEBUG logging.
    nonisolated static let plantKeywords: Set<String> = [
        "plant", "flower", "leaf", "tree", "vegetation",
        "foliage", "succulent", "herb", "fern", "moss",
        "garden", "bush", "shrub", "grass", "cactus",
        "vegetable", "fruit", "rose", "orchid", "ivy"
    ]

    /// Vision's confidence threshold. Below this, the label is ignored as noise.
    nonisolated static let confidenceThreshold: Float = 0.3

    /// True if any of the photos look plant-like.
    func anyImageContainsPlant(imageData: [Data]) async -> Bool {
        for data in imageData {
            if await containsPlant(imageData: data) {
                return true
            }
        }
        return false
    }

    func containsPlant(imageData: Data) async -> Bool {
        let request = VNClassifyImageRequest()
        let handler = VNImageRequestHandler(data: imageData)

        do {
            try handler.perform([request])
        } catch {
            Logger.ai.error("Vision perform failed: \(error.localizedDescription, privacy: .public)")
            return false
        }

        guard let observations = request.results else { return false }
        let classifications = observations.map { ($0.identifier, $0.confidence) }

        #if DEBUG
        Self.logTopClassifications(classifications)
        #endif

        return Self.detectsPlant(in: classifications)
    }

    // MARK: - Pure (testable) helpers

    nonisolated static func detectsPlant(in classifications: [(String, Float)]) -> Bool {
        classifications.contains { label, confidence in
            guard confidence > confidenceThreshold else { return false }
            let lower = label.lowercased()
            return plantKeywords.contains { lower.contains($0) }
        }
    }

    #if DEBUG
    nonisolated private static func logTopClassifications(_ classifications: [(String, Float)]) {
        let top = classifications
            .sorted { $0.1 > $1.1 }
            .prefix(5)
            .map { "\($0.0)=\(String(format: "%.2f", $0.1))" }
            .joined(separator: ", ")
        Logger.ai.debug("Vision top-5: \(top, privacy: .public)")
    }
    #endif
}
