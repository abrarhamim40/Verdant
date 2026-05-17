//
//  ScanRequest.swift
//  Verdant
//
//  Created by Abrar Hamim on 5/17/26.
//

import Foundation
import CoreLocation

/// Carries everything ScanningView needs to drive a single AIService.analyzePlant() call.
struct ScanRequest: Identifiable, Hashable {
    let id: UUID
    let images: [Data]
    let language: String
    let coordinate: CLLocationCoordinate2D?

    init(
        id: UUID = UUID(),
        images: [Data],
        language: String = Locale.current.localizedString(forLanguageCode: Locale.current.language.languageCode?.identifier ?? "en") ?? "English",
        coordinate: CLLocationCoordinate2D? = nil
    ) {
        self.id = id
        self.images = images
        self.language = language
        self.coordinate = coordinate
    }

    // Hash & equality by id only — image Data is large and identity is what navigationDestination tracks.
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: ScanRequest, rhs: ScanRequest) -> Bool {
        lhs.id == rhs.id
    }
}
