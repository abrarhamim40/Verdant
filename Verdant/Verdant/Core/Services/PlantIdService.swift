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
            longitude: location?.longitude
        )

        // Plant.id v3 — request body is minimal; response/feature controls go on query string.
        var components = URLComponents(
            url: baseURL.appendingPathComponent("identification"),
            resolvingAgainstBaseURL: false
        )!
        components.queryItems = [
            URLQueryItem(name: "details", value: "common_names,url,description,taxonomy,watering"),
            URLQueryItem(name: "language", value: "en"),
            URLQueryItem(name: "classification_level", value: "all"),
            // Plant.id v3 health values: none | auto | only.
            // "auto" runs health detection when the image looks plant-like (gated by is_plant).
            // We previously sent "all" which is not a valid value and silently disabled disease detection.
            URLQueryItem(name: "health", value: "auto"),
            URLQueryItem(name: "similar_images", value: "true"),
        ]

        guard let url = components.url else {
            throw AIError.invalidInput
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "Api-Key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(body)

        #if DEBUG
        Logger.ai.debug("Plant.id URL: \(url.absoluteString, privacy: .public)")
        // Body has base64 image data — log only sizes, not the bytes (would flood Console).
        Logger.ai.debug("Plant.id body: images=\(body.images.count) sizes=\(body.images.map { $0.count }) lat=\(body.latitude?.description ?? "nil") lon=\(body.longitude?.description ?? "nil")")
        #endif

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

        #if DEBUG
        if let bodyStr = String(data: data, encoding: .utf8) {
            // Quick flag so we can grep for whether health detection ran at all.
            let hasDisease = bodyStr.contains("\"disease\"")
            Logger.ai.debug("Plant.id response [\(http.statusCode)] has 'disease' key: \(hasDisease)")

            // Truncate huge success responses to keep Console readable, but allow more room for disease section.
            let preview = bodyStr.count > 8000 ? String(bodyStr.prefix(8000)) + "…[truncated, total \(bodyStr.count) chars]" : bodyStr
            Logger.ai.debug("Plant.id response [\(http.statusCode)]: \(preview, privacy: .public)")
        }
        #endif

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
        case 400:
            Self.logErrorBody(data, status: 400)
            throw AIError.invalidInput
        case 401:
            Self.logErrorBody(data, status: 401)
            throw AIError.invalidAPIKey
        case 429:
            throw AIError.rateLimited
        case 500...599:
            throw AIError.serverError
        default:
            Self.logErrorBody(data, status: http.statusCode)
            throw AIError.unknownError(http.statusCode)
        }
    }

    nonisolated private static func logErrorBody(_ data: Data, status: Int) {
        if let body = String(data: data, encoding: .utf8) {
            Logger.ai.error("Plant.id \(status) body: \(body, privacy: .public)")
        }
    }

    /// Plant.id v3 disease detection — separate endpoint from `/identification`.
    /// Returns the bare `DiseaseAssessment` (suggestions array). Free tier usually does
    /// not include this; callers should treat any failure as graceful degradation, not a fatal error.
    func assessHealth(
        images: [Data],
        location: CLLocationCoordinate2D? = nil
    ) async throws -> DiseaseAssessment {
        guard !images.isEmpty, images.count <= 5 else {
            throw AIError.invalidInput
        }

        let body = PlantIdRequest(
            images: images.map { $0.base64EncodedString() },
            latitude: location?.latitude,
            longitude: location?.longitude
        )

        var components = URLComponents(
            url: baseURL.appendingPathComponent("health_assessment"),
            resolvingAgainstBaseURL: false
        )!
        components.queryItems = [
            URLQueryItem(name: "details", value: "local_name,description,url,treatment,classification,common_names,cause"),
            URLQueryItem(name: "language", value: "en"),
            URLQueryItem(name: "similar_images", value: "true"),
        ]

        guard let url = components.url else {
            throw AIError.invalidInput
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "Api-Key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(body)

        #if DEBUG
        Logger.ai.debug("Plant.id health URL: \(url.absoluteString, privacy: .public)")
        #endif

        let started = Date()
        Logger.ai.info("Plant.id health_assessment started")

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            Logger.ai.error("Plant.id health transport error: \(error.localizedDescription, privacy: .public)")
            throw AIError.networkError
        }

        let elapsed = Date().timeIntervalSince(started)
        Logger.ai.info("Plant.id health response in \(elapsed, format: .fixed(precision: 2))s")

        guard let http = response as? HTTPURLResponse else {
            throw AIError.networkError
        }

        #if DEBUG
        if let bodyStr = String(data: data, encoding: .utf8) {
            let preview = bodyStr.count > 6000 ? String(bodyStr.prefix(6000)) + "…[truncated]" : bodyStr
            Logger.ai.debug("Plant.id health [\(http.statusCode)]: \(preview, privacy: .public)")
        }
        #endif

        switch http.statusCode {
        case 200, 201:
            do {
                let envelope = try decoder.decode(HealthAssessmentResponse.self, from: data)
                return envelope.result.disease ?? DiseaseAssessment(suggestions: [])
            } catch {
                Logger.ai.error("Plant.id health decode failed: \(error.localizedDescription, privacy: .public)")
                throw AIError.parsingFailed
            }
        case 400:
            Self.logErrorBody(data, status: 400)
            throw AIError.invalidInput
        case 401, 402, 403:
            Self.logErrorBody(data, status: http.statusCode)
            throw AIError.invalidAPIKey
        case 429:
            throw AIError.rateLimited
        case 500...599:
            throw AIError.serverError
        default:
            Self.logErrorBody(data, status: http.statusCode)
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
