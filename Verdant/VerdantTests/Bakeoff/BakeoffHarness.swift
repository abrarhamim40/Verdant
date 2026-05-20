//
//  BakeoffHarness.swift
//  VerdantTests
//
//  Created by Abrar Hamim on 5/20/26.
//
//  One-off comparison harness: Gemini 3.5 Flash (multimodal) vs Plant.id /identification
//  on the same set of photos. Result decides Path A vs Path B in the production blueprint
//  (.claude/launch-prep/10-production-blueprint.md §6.1).
//
//  USAGE
//  1. Build a photo folder + manifest.json (see manifest.example.json in this directory).
//  2. In Xcode → Product → Scheme → Edit Scheme → Test → Arguments → Environment Variables, set:
//       VERDANT_BAKEOFF_DIR        = /absolute/path/to/your/photos
//       VERDANT_GEMINI_API_KEY     = <gemini key>
//       VERDANT_PLANT_ID_API_KEY   = <plant.id key>
//  3. Run the `runBakeoff` test from the test navigator.
//  4. Console outputs a Markdown comparison table + verdict (Path A or B).
//  5. Record the verdict in blueprint §6.1, then delete this entire folder.
//
//  This file deliberately does its own multimodal Gemini call rather than calling
//  GeminiService — we don't want to mutate production code before the path is decided.

import Testing
import Foundation
import UIKit
@testable import Verdant

@Suite("Path A vs Path B — Bake-off")
struct BakeoffHarness {

    @Test func runBakeoff() async throws {
        let env = ProcessInfo.processInfo.environment
        guard let dirPath = env["VERDANT_BAKEOFF_DIR"] else {
            print("⏭ Skipping bake-off — set VERDANT_BAKEOFF_DIR env var to run")
            return
        }
        guard let geminiKey = env["VERDANT_GEMINI_API_KEY"], !geminiKey.isEmpty else {
            throw BakeoffError.missingKey("VERDANT_GEMINI_API_KEY")
        }
        guard let plantIdKey = env["VERDANT_PLANT_ID_API_KEY"], !plantIdKey.isEmpty else {
            throw BakeoffError.missingKey("VERDANT_PLANT_ID_API_KEY")
        }

        let manifest = try loadManifest(at: dirPath)
        print("\n🌱 Bake-off — \(manifest.photos.count) photos\n")

        var rows: [BakeoffRow] = []
        for (idx, photo) in manifest.photos.enumerated() {
            let imageURL = URL(fileURLWithPath: dirPath).appendingPathComponent(photo.file)
            let imageData: Data
            do {
                imageData = try Data(contentsOf: imageURL)
            } catch {
                print("  [\(idx + 1)/\(manifest.photos.count)] ❌ \(photo.file) — file missing")
                continue
            }

            print("  [\(idx + 1)/\(manifest.photos.count)] → \(photo.file) (\(photo.category))")

            async let geminiTask = callGemini(imageData: imageData, key: geminiKey)
            async let plantIdTask = callPlantId(imageData: imageData, key: plantIdKey)

            let gemini = (try? await geminiTask) ?? ModelGuess.failure
            let plantId = (try? await plantIdTask) ?? ModelGuess.failure

            rows.append(BakeoffRow(photo: photo, gemini: gemini, plantId: plantId))
        }

        printMarkdownTable(rows)
        printSummary(rows)
    }

    // MARK: - Gemini multimodal (self-contained — mirrors blueprint §3.2/§3.3)

    private func callGemini(imageData: Data, key: String) async throws -> ModelGuess {
        let optimized = try optimizeForGemini(imageData)
        let base64 = optimized.base64EncodedString()

        let prompt = """
        Look at this plant photo. Identify the plant as precisely as you can.

        Return ONLY valid JSON (no markdown):
        {
          "plant_name": "Most specific identification — cultivar, variety, or species",
          "scientific_name": "Genus species 'Cultivar' if known",
          "common_names": ["common name 1", "common name 2"],
          "confidence": 0.0 to 1.0
        }

        If you recognise a specific cultivar (e.g. 'Peace Rose' vs just 'Rose'), say so.
        If unsure at the cultivar level, give the most specific level you're confident about.
        """

        let body: [String: Any] = [
            "contents": [[
                "parts": [
                    ["text": prompt],
                    ["inline_data": ["mime_type": "image/jpeg", "data": base64]]
                ]
            ]],
            "generationConfig": [
                "temperature": 0.1,
                "max_output_tokens": 600,
                "response_mime_type": "application/json",
                "thinking_config": ["thinking_budget": 0]
            ]
        ]

        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash:generateContent?key=\(key)") else {
            throw BakeoffError.geminiFailed("invalid URL")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            let bodyStr = String(data: data, encoding: .utf8) ?? ""
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            throw BakeoffError.geminiFailed("HTTP \(status): \(bodyStr.prefix(300))")
        }

        return try parseGeminiResponse(data)
    }

    private func parseGeminiResponse(_ data: Data) throws -> ModelGuess {
        struct Envelope: Codable {
            struct Candidate: Codable {
                struct Content: Codable {
                    struct Part: Codable { let text: String }
                    let parts: [Part]
                }
                let content: Content
            }
            let candidates: [Candidate]
        }
        struct Inner: Codable {
            let plant_name: String?
            let scientific_name: String?
            let common_names: [String]?
            let confidence: Double?
        }

        let env = try JSONDecoder().decode(Envelope.self, from: data)
        guard let text = env.candidates.first?.content.parts.first?.text else {
            throw BakeoffError.geminiFailed("no text in candidate")
        }
        let cleaned = text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let inner = try? JSONDecoder().decode(Inner.self, from: Data(cleaned.utf8)) else {
            throw BakeoffError.geminiFailed("inner JSON parse failed: \(cleaned.prefix(200))")
        }
        return ModelGuess(
            plantName: inner.plant_name ?? "",
            scientificName: inner.scientific_name,
            commonNames: inner.common_names ?? [],
            confidence: inner.confidence ?? 0,
            failed: false
        )
    }

    // MARK: - Plant.id /identification (self-contained, fresh URLSession + env var key)

    private func callPlantId(imageData: Data, key: String) async throws -> ModelGuess {
        struct Body: Codable {
            let images: [String]
        }

        let body = Body(images: [imageData.base64EncodedString()])
        var comps = URLComponents(string: "https://plant.id/api/v3/identification")!
        comps.queryItems = [
            URLQueryItem(name: "details", value: "common_names,taxonomy"),
            URLQueryItem(name: "language", value: "en"),
            URLQueryItem(name: "classification_level", value: "all")
        ]
        guard let url = comps.url else { throw BakeoffError.plantIdFailed("bad URL") }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(key, forHTTPHeaderField: "Api-Key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            let bodyStr = String(data: data, encoding: .utf8) ?? ""
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            throw BakeoffError.plantIdFailed("HTTP \(status): \(bodyStr.prefix(300))")
        }

        struct Response: Codable {
            struct Result: Codable {
                struct Classification: Codable {
                    struct Suggestion: Codable {
                        struct Details: Codable {
                            struct Taxonomy: Codable { let species: String? }
                            let common_names: [String]?
                            let taxonomy: Taxonomy?
                        }
                        let name: String
                        let probability: Double
                        let details: Details?
                    }
                    let suggestions: [Suggestion]
                }
                let classification: Classification
            }
            let result: Result
        }

        let decoded = try JSONDecoder().decode(Response.self, from: data)
        guard let top = decoded.result.classification.suggestions.first else {
            throw BakeoffError.plantIdFailed("empty suggestions")
        }
        return ModelGuess(
            plantName: top.name,
            scientificName: top.details?.taxonomy?.species,
            commonNames: top.details?.common_names ?? [],
            confidence: top.probability,
            failed: false
        )
    }

    // MARK: - Image optimization (blueprint §3.3: 512px JPEG q0.60 for Gemini)

    private func optimizeForGemini(_ data: Data) throws -> Data {
        guard let image = UIImage(data: data) else {
            throw BakeoffError.compressionFailed("not a valid image")
        }
        let maxDim: CGFloat = 512
        let longSide = max(image.size.width, image.size.height)
        let scale = longSide > maxDim ? maxDim / longSide : 1.0
        let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)

        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        defer { UIGraphicsEndImageContext() }
        image.draw(in: CGRect(origin: .zero, size: newSize))
        guard let resized = UIGraphicsGetImageFromCurrentImageContext(),
              let jpeg = resized.jpegData(compressionQuality: 0.60) else {
            throw BakeoffError.compressionFailed("jpeg encode failed")
        }
        return jpeg
    }

    // MARK: - Manifest

    private func loadManifest(at dirPath: String) throws -> Manifest {
        let url = URL(fileURLWithPath: dirPath).appendingPathComponent("manifest.json")
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(Manifest.self, from: data)
    }

    // MARK: - Output

    private func printMarkdownTable(_ rows: [BakeoffRow]) {
        print("\n## Bake-off detail\n")
        print("| # | File | Category | Truth | Gemini | Plant.id | G | P |")
        print("|---|---|---|---|---|---|---|---|")
        for (idx, row) in rows.enumerated() {
            let g = row.gemini.failed ? "—" : row.gemini.plantName
            let p = row.plantId.failed ? "—" : row.plantId.plantName
            let gOk = scoreMatch(guess: row.gemini, truth: row.photo) ? "✅" : "❌"
            let pOk = scoreMatch(guess: row.plantId, truth: row.photo) ? "✅" : "❌"
            print("| \(idx + 1) | \(row.photo.file) | \(row.photo.category) | \(row.photo.expectedSpecies) | \(g) | \(p) | \(gOk) | \(pOk) |")
        }
    }

    private func printSummary(_ rows: [BakeoffRow]) {
        let common = rows.filter { $0.photo.category == "common" }
        let cult = rows.filter { $0.photo.category == "cultivar" }

        let gCommonHit = common.filter { scoreMatch(guess: $0.gemini, truth: $0.photo) }.count
        let pCommonHit = common.filter { scoreMatch(guess: $0.plantId, truth: $0.photo) }.count
        let gCultHit = cult.filter { scoreMatch(guess: $0.gemini, truth: $0.photo) }.count
        let pCultHit = cult.filter { scoreMatch(guess: $0.plantId, truth: $0.photo) }.count

        print("\n## Summary\n")
        print("| Set | Gemini 3.5 Flash | Plant.id |")
        print("|---|---|---|")
        print("| Common (\(common.count)) | \(gCommonHit)/\(common.count) (\(pct(gCommonHit, common.count))%) | \(pCommonHit)/\(common.count) (\(pct(pCommonHit, common.count))%) |")
        print("| Cultivar (\(cult.count)) | \(gCultHit)/\(cult.count) (\(pct(gCultHit, cult.count))%) | \(pCultHit)/\(cult.count) (\(pct(pCultHit, cult.count))%) |")

        let cultPct = cult.isEmpty ? 0 : (gCultHit * 100 / cult.count)
        print("\n## Verdict\n")
        if cultPct >= 90 {
            print("✅ **Path A confirmed** — Gemini 3.5 Flash hit \(cultPct)% on cultivars (≥90% threshold).")
            print("   Proceed with the blueprint §2 Path A router (Gemini-primary for everything).")
        } else {
            print("⚠️ **Path B required** — Gemini 3.5 Flash hit only \(cultPct)% on cultivars (< 90% threshold).")
            print("   Switch the §2 router to Path B: Plant.id keeps species ID; Gemini handles diagnosis + treatment.")
        }
    }

    private func pct(_ n: Int, _ d: Int) -> Int {
        d > 0 ? (n * 100 / d) : 0
    }

    private func scoreMatch(guess: ModelGuess, truth: ManifestPhoto) -> Bool {
        if guess.failed { return false }
        // Loose substring match, case-insensitive. Common name OR scientific name counts.
        let needles = [truth.expectedSpecies, truth.expectedCommon]
            .compactMap { $0?.lowercased() }
            .filter { !$0.isEmpty }
        let haystack = ([guess.plantName] + (guess.scientificName.map { [$0] } ?? []) + guess.commonNames)
            .joined(separator: " | ")
            .lowercased()
        return needles.contains { needle in
            haystack.contains(needle)
        }
    }
}

// MARK: - Models

private struct Manifest: Codable {
    let photos: [ManifestPhoto]
}

private struct ManifestPhoto: Codable {
    let file: String
    let category: String         // "common" | "cultivar"
    let expectedSpecies: String  // e.g. "Rosa 'Peace'"
    let expectedCommon: String?  // e.g. "Peace Rose"

    enum CodingKeys: String, CodingKey {
        case file, category
        case expectedSpecies = "expected_species"
        case expectedCommon = "expected_common"
    }
}

private struct ModelGuess {
    let plantName: String
    let scientificName: String?
    let commonNames: [String]
    let confidence: Double
    let failed: Bool

    static let failure = ModelGuess(plantName: "", scientificName: nil, commonNames: [], confidence: 0, failed: true)
}

private struct BakeoffRow {
    let photo: ManifestPhoto
    let gemini: ModelGuess
    let plantId: ModelGuess
}

enum BakeoffError: Error, CustomStringConvertible {
    case missingKey(String)
    case compressionFailed(String)
    case geminiFailed(String)
    case plantIdFailed(String)

    var description: String {
        switch self {
        case .missingKey(let k): return "Missing env var: \(k)"
        case .compressionFailed(let s): return "Image compression failed: \(s)"
        case .geminiFailed(let s): return "Gemini call failed: \(s)"
        case .plantIdFailed(let s): return "Plant.id call failed: \(s)"
        }
    }
}
