//
//  Plant.swift
//  Verdant
//
//  Created by Abrar Hamim on 5/17/26.
//

import Foundation
import SwiftData

@Model
final class Plant {
    var id: UUID = UUID()
    var name: String = ""
    var nickname: String?
    var commonNames: [String] = []
    var scientificName: String?
    var dateAdded: Date = Date()

    @Attribute(.externalStorage) var imageData: Data?

    var location: String?
    var sunlightLevel: String = "medium"
    var hasGrowLight: Bool = false
    var indoorOrOutdoor: String = "indoor"

    var currentHealthStatus: String = "healthy"
    var lastHealthCheck: Date?

    var customWateringDays: Int?
    var customFertilizingDays: Int?
    var customMistingDays: Int?
    var careNotes: String?

    @Relationship(deleteRule: .cascade, inverse: \PlantScan.plant)
    var scans: [PlantScan]? = []

    @Relationship(deleteRule: .cascade, inverse: \CareReminder.plant)
    var reminders: [CareReminder]? = []

    init(name: String, nickname: String? = nil, location: String? = nil) {
        self.name = name
        self.nickname = nickname
        self.location = location
    }

    var displayName: String {
        nickname ?? commonNames.first ?? name
    }

    var ageInDays: Int {
        Calendar.current.dateComponents([.day], from: dateAdded, to: Date()).day ?? 0
    }

    var nextWateringDate: Date? {
        reminders?
            .filter { $0.type == "watering" && $0.isEnabled }
            .first?.nextDue
    }
}

extension Plant {
    static var preview: Plant {
        let plant = Plant(
            name: "Monstera deliciosa",
            nickname: "Big Mo",
            location: "Living Room"
        )
        plant.commonNames = ["Swiss cheese plant", "Split-leaf philodendron"]
        plant.scientificName = "Monstera deliciosa"
        return plant
    }

    /// Default care reminders seeded on every new plant. Watering + fertilizing
    /// are universal enough to auto-create; pruning + misting are species-
    /// dependent and the user adds them later from the ScheduleView (Day 31-32).
    static func defaultReminders() -> [CareReminder] {
        [
            CareReminder(type: "watering", frequencyDays: 7),
            CareReminder(type: "fertilizing", frequencyDays: 30)
        ]
    }
}
