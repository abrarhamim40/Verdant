//
//  PlantIdService.swift
//  Verdant
//
//  Created by Abrar Hamim on 5/17/26.
//

import Foundation
import CoreLocation
import os

actor PlantIdService {
    static let shared = PlantIdService()

    private let apiKey: String
    private let baseURL = URL(string: "https://plant.id/api/v3")!
    private let session: URLSession
    private let cache: ResponseCache
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(
        apiKey: String? = nil,
        session: URLSession? = nil,
        cache: ResponseCache = ResponseCache()
    ) {
        self.apiKey = apiKey ?? APIKeys.plantID
        self.cache = cache

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

    func identify(
        images: [Data],
        location: CLLocationCoordinate2D? = nil
    ) async throws -> PlantIdResponse {
        guard !images.isEmpty, images.count <= 5 else {
            throw AIError.invalidInput
        }

        let cacheKey = Self.cacheKey(images: images, location: location)
        if let cached = await cache.get(hash: cacheKey),
           let decoded = try? decoder.decode(PlantIdResponse.self, from: cached) {
            Logger.ai.info("Plant.id cache hit")
            return decoded
        }

        let body = PlantIdRequest(
            images: images.map { $0.base64EncodedString() },
            latitude: location?.latitude,
            longitude: location?.longitude,
            similarImages: true,
            healthAssessment: true,
            classificationLevel: "all"
        )

        var request = URLRequest(url: baseURL.appendingPathComponent("identification"))
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "Api-Key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(body)

        let started = Date()
        Logger.ai.info("Plant.id request started")

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            Logger.ai.error("Plant.id transport error: \(error.localizedDescription, privacy: .public)")
            throw AIError.networkError
        }

        let elapsed = Date().timeIntervalSince(started)
        Logger.ai.info("Plant.id response in \(elapsed, format: .fixed(precision: 2))s")

        guard let http = response as? HTTPURLResponse else {
            throw AIError.networkError
        }

        switch http.statusCode {
        case 200, 201:
            do {
                let decoded = try decoder.decode(PlantIdResponse.self, from: data)
                await cache.set(hash: cacheKey, data: data)
                return decoded
            } catch {
                Logger.ai.error("Plant.id decode failed: \(error.localizedDescription, privacy: .public)")
                throw AIError.parsingFailed
            }
        case 401:
            throw AIError.invalidAPIKey
        case 429:
            throw AIError.rateLimited
        case 500...599:
            throw AIError.serverError
        default:
            throw AIError.unknownError(http.statusCode)
        }
    }

    /// Deterministic cache key — same photos (+ rounded location) reuse the same Plant.id response for 24h.
    nonisolated private static func cacheKey(images: [Data], location: CLLocationCoordinate2D?) -> String {
        var combined = Data()
        for image in images {
            combined.append(image)
        }
        var key = combined.sha256Hash
        if let location {
            let lat = (location.latitude * 100).rounded() / 100
            let lon = (location.longitude * 100).rounded() / 100
            key += "_\(lat)_\(lon)"
        }
        return key
    }
}
