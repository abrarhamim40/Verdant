//
//  PlantScan.swift
//  Verdant
//
//  Created by Abrar Hamim on 5/17/26.
//

import Foundation
import SwiftData

@Model
final class PlantScan {
    var id: UUID = UUID()
    var date: Date = Date()

    @Attribute(.externalStorage) var imageData: Data?

    var analysisJSON: String = ""

    var plantNameDetected: String = ""
    var healthStatus: String = "healthy"
    var confidence: Double = 0.0
    var diseaseDetected: String?
    var diseaseProbability: Double?

    var multiAngleScan: Bool = false
    var photoCount: Int = 1

    var plant: Plant?

    init(
        imageData: Data?,
        analysisJSON: String,
        plantNameDetected: String,
        healthStatus: String,
        confidence: Double,
        multiAngleScan: Bool = false,
        photoCount: Int = 1
    ) {
        self.imageData = imageData
        self.analysisJSON = analysisJSON
        self.plantNameDetected = plantNameDetected
        self.healthStatus = healthStatus
        self.confidence = confidence
        self.multiAngleScan = multiAngleScan
        self.photoCount = photoCount
    }

    var confidencePercent: Int { Int(confidence * 100) }
}
